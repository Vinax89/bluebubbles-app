import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:bluebubbles/helpers/backend/settings_helpers.dart';
import 'package:bluebubbles/utils/crypto_utils.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart';

SocketService socket = Get.isRegistered<SocketService>() ? Get.find<SocketService>() : Get.put(SocketService());

enum SocketState {
  connected,
  disconnected,
  error,
  connecting,
}

class ReconnectMetric {
  ReconnectMetric({required this.duration, required this.retryCount, required this.timestamp});

  final Duration duration;
  final int retryCount;
  final DateTime timestamp;
}

class SocketService extends GetxService {
  final Rx<SocketState> state = SocketState.disconnected.obs;
  SocketState _lastState = SocketState.disconnected;
  RxString lastError = "".obs;
  Timer? _reconnectTimer;
  late Socket socket;

  DateTime? _lastDisconnect;
  DateTime? _lastConnect;
  int _retryCount = 0;
  static const Duration _baseReconnectDelay = Duration(seconds: 5);
  static const Duration _maxReconnectDelay = Duration(minutes: 1);
  final StreamController<ReconnectMetric> _metricsController = StreamController.broadcast();
  Stream<ReconnectMetric> get metricsStream => _metricsController.stream;

  String get serverAddress => http.origin;
  String get password => ss.settings.guidAuthKey.value;

  @override
  void onInit() {
    super.onInit();

    Logger.debug("Initializing socket service...");
    startSocket();
    Connectivity().onConnectivityChanged.listen((event) {
      if (!event.contains(ConnectivityResult.wifi) &&
          !event.contains(ConnectivityResult.ethernet) &&
          http.originOverride != null) {
        Logger.info("Detected switch off wifi, removing localhost address...");
        http.originOverride = null;
      }
    });
    Logger.debug("Initialized socket service");
  }

  @override
  void onClose() {
    closeSocket();
    _metricsController.close();
    super.onClose();
  }

  void startSocket() {
    OptionBuilder options = OptionBuilder()
        .setQuery({"guid": password})
        .setTransports(['websocket', 'polling'])
        .setExtraHeaders(http.headers)
        // Disable so that we can create the listeners first
        .disableAutoConnect()
        .enableReconnection();
    socket = io(serverAddress, options.build());
    // placed here so that [socket] is still initialized
    if (isNullOrEmpty(serverAddress)) return;

    socket.onConnect((data) => handleStatusUpdate(SocketState.connected, data));
    socket.onReconnect((data) => handleStatusUpdate(SocketState.connected, data));

    socket.onReconnectAttempt((data) => handleStatusUpdate(SocketState.connecting, data));
    socket.onReconnecting((data) => handleStatusUpdate(SocketState.connecting, data));
    socket.onConnecting((data) => handleStatusUpdate(SocketState.connecting, data));

    socket.onDisconnect((data) => handleStatusUpdate(SocketState.disconnected, data));

    socket.onConnectError((data) => handleStatusUpdate(SocketState.error, data));
    socket.onConnectTimeout((data) => handleStatusUpdate(SocketState.error, data));
    socket.onError((data) => handleStatusUpdate(SocketState.error, data));

    // custom events
    // only listen to these events from socket on web/desktop (FCM handles on Android)
    if (kIsWeb || kIsDesktop) {
      socket.on("group-name-change", (data) => ah.handleEvent("group-name-change", data, 'DartSocket'));
      socket.on("participant-removed", (data) => ah.handleEvent("participant-removed", data, 'DartSocket'));
      socket.on("participant-added", (data) => ah.handleEvent("participant-added", data, 'DartSocket'));
      socket.on("participant-left", (data) => ah.handleEvent("participant-left", data, 'DartSocket'));
      socket.on("incoming-facetime", (data) => ah.handleEvent("incoming-facetime", jsonDecode(data), 'DartSocket'));
    }

    socket.on("ft-call-status-changed", (data) => ah.handleEvent("ft-call-status-changed", data, 'DartSocket'));
    socket.on("new-message", (data) => ah.handleEvent("new-message", data, 'DartSocket'));
    socket.on("updated-message", (data) => ah.handleEvent("updated-message", data, 'DartSocket'));
    socket.on("typing-indicator", (data) => ah.handleEvent("typing-indicator", data, 'DartSocket'));
    socket.on("chat-read-status-changed", (data) => ah.handleEvent("chat-read-status-changed", data, 'DartSocket'));
    socket.on("imessage-aliases-removed", (data) => ah.handleEvent("imessage-aliases-removed", data, 'DartSocket'));

    socket.connect();
  }

  void disconnect() {
    if (isNullOrEmpty(serverAddress)) return;
    socket.disconnect();
    state.value = SocketState.disconnected;
  }

  void reconnect() {
    if (state.value == SocketState.connected || isNullOrEmpty(serverAddress)) return;
    state.value = SocketState.connecting;
    socket.connect();
  }

  void closeSocket() {
    if (isNullOrEmpty(serverAddress)) return;
    socket.dispose();
    state.value = SocketState.disconnected;
  }

  void restartSocket() {
    closeSocket();
    startSocket();
  }

  void forgetConnection() {
    closeSocket();
    ss.settings.guidAuthKey.value = "";
    clearServerUrl(saveAdditionalSettings: ["guidAuthKey"]);
  }

  Future<Map<String, dynamic>> sendMessage(String event, Map<String, dynamic> message) {
    Completer<Map<String, dynamic>> completer = Completer();

    socket.emitWithAck(event, message, ack: (response) {
      if (response['encrypted'] == true) {
        response['data'] = jsonDecode(decryptAES(response['data'], password));
      }

      if (!completer.isCompleted) {
        completer.complete(response);
      }
    });

    return completer.future;
  }

  /// Benchmark utility that sends [messageCount] synthetic messages
  /// to the server with [concurrency] parallel sends.
  ///
  /// Uses [sendMessage] under the hood and records latency and
  /// throughput metrics which are logged once complete.
  Future<void> runBenchmark({int messageCount = 100, int concurrency = 1}) async {
    if (messageCount <= 0 || concurrency <= 0) {
      Logger.error('Message count and concurrency must be greater than 0');
      return;
    }

    final List<Duration> latencies = [];
    final Stopwatch totalWatch = Stopwatch()..start();

    int sent = 0;
    while (sent < messageCount) {
      final List<Future<void>> futures = [];
      for (int i = 0; i < concurrency && sent < messageCount; i++, sent++) {
        final int current = sent;
        futures.add(() async {
          final Map<String, dynamic> data = {
            'index': current,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
          final Stopwatch sw = Stopwatch()..start();
          await sendMessage('benchmark', data);
          sw.stop();
          latencies.add(sw.elapsed);
        }());
      }

      await Future.wait(futures);
    }

    totalWatch.stop();

    if (latencies.isEmpty) {
      Logger.info('No messages sent during benchmark');
      return;
    }

    final Duration totalElapsed = totalWatch.elapsed;
    final Duration avgLatency =
        latencies.fold(Duration.zero, (a, b) => a + b) ~/ latencies.length;
    final double throughput =
        messageCount / totalElapsed.inMilliseconds * 1000.0;

    Logger.info('Socket benchmark complete');
    Logger.info('Total messages: $messageCount');
    Logger.info('Total time: ${totalElapsed.inMilliseconds} ms');
    Logger.info('Average latency: ${avgLatency.inMilliseconds} ms');
    Logger.info('Throughput: ${throughput.toStringAsFixed(2)} msg/s');
  }

  void handleStatusUpdate(SocketState status, dynamic data) {
    if (_lastState == status) return;
    _lastState = status;

    switch (status) {
      case SocketState.connected:
        state.value = SocketState.connected;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        NetworkTasks.onConnect();
        notif.clearSocketError();
        final now = DateTime.now();
        _lastConnect = now;
        if (_lastDisconnect != null) {
          final duration = now.difference(_lastDisconnect!);
          Logger.info("Socket reconnected in ${duration.inMilliseconds} ms after $_retryCount retries");
          _metricsController.add(ReconnectMetric(duration: duration, retryCount: _retryCount, timestamp: now));
          _lastDisconnect = null;
          _retryCount = 0;
        }
        return;
      case SocketState.disconnected:
        Logger.info("Disconnected from socket...");
        state.value = SocketState.disconnected;
        _lastDisconnect = DateTime.now();
        _retryCount = 0;
        return;
      case SocketState.connecting:
        Logger.info("Connecting to socket...");
        state.value = SocketState.connecting;
        return;
      case SocketState.error:
        Logger.info("Socket connect error, fetching new URL...");

        if (_lastDisconnect != null) {
          _retryCount++;
        }

        if (data is SocketException) {
          handleSocketException(data);
        }

        state.value = SocketState.error;
        final int exponent = _retryCount > 0 ? _retryCount - 1 : 0;
        final int delaySeconds = math.min(
            _baseReconnectDelay.inSeconds * (1 << exponent),
            _maxReconnectDelay.inSeconds);
        _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
          if (state.value == SocketState.connected) return;

          await fdb.fetchNewUrl();
          restartSocket();

          if (state.value == SocketState.connected) return;

          if (!ss.settings.keepAppAlive.value) {
            notif.createSocketError();
          }
        });
        return;
      default:
        return;
    }
  }

  void handleSocketException(SocketException e) {
    String msg = e.message;
    if (msg.contains("Failed host lookup")) {
      lastError.value = "Failed to resolve hostname";
    } else {
      lastError.value = msg;
    }
  }
}
