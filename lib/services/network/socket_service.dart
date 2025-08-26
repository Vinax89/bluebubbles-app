import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:bluebubbles/helpers/backend/settings_helpers.dart';
import 'package:bluebubbles/utils/crypto_utils.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/helpers/network/network_helpers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:workmanager/workmanager.dart';

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

  String? _deviceId;

  Future<String> _getDeviceId() async {
    _deviceId ??= await getDeviceName();
    return _deviceId!;
  }

  Future<void> _ensureSession() async {
    final id = await _getDeviceId();
    if (!sessionRegistry.validate(id)) {
      await sessionRegistry.refresh(id);
    }
  }

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
    Workmanager().initialize(callbackDispatcher);
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

  Future<void> startSocket() async {
    final id = await _getDeviceId();
    await _ensureSession();
    final token = sessionRegistry.get(id)?.token;

    OptionBuilder options = OptionBuilder()
        .setQuery({"guid": password, "device_id": id, if (token != null) "session_token": token})
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
    socket.on("session-invalid", (data) async {
      await _ensureSession();
      restartSocket();
    });
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

  Future<Map<String, dynamic>> sendMessage(String event, Map<String, dynamic> message) async {
    Completer<Map<String, dynamic>> completer = Completer();

    await _ensureSession();

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

    class _RunningStats {
      int count = 0;
      double _mean = 0;
      Duration? min;
      Duration? max;

      void add(Duration value) {
        count++;
        final double micros = value.inMicroseconds.toDouble();
        _mean += (micros - _mean) / count;
        if (min == null || value < min!) min = value;
        if (max == null || value > max!) max = value;
      }

      Duration get average =>
          count == 0 ? Duration.zero : Duration(microseconds: _mean.round());
    }

    class _P2Quantile {
      _P2Quantile(this.p) : dn = [0, p / 2, p, (1 + p) / 2, 1];

      final double p;
      final List<double> q = List.filled(5, 0);
      final List<int> n = List.filled(5, 0);
      final List<double> np = List.filled(5, 0);
      final List<double> dn;
      int count = 0;

      bool get isInitialized => count >= 5;

      void add(Duration value) {
        _add(value.inMicroseconds.toDouble());
      }

      void _add(double x) {
        if (count < 5) {
          q[count] = x;
          count++;
          if (count == 5) {
            q.sort();
            for (int i = 0; i < 5; i++) {
              n[i] = i + 1;
            }
            np[0] = 1;
            np[1] = 1 + 2 * p;
            np[2] = 1 + 4 * p;
            np[3] = 3 + 2 * p;
            np[4] = 5;
          }
          return;
        }

        int k;
        if (x < q[0]) {
          q[0] = x;
          k = 0;
        } else if (x >= q[4]) {
          q[4] = x;
          k = 3;
        } else {
          k = 0;
          while (k < 3 && x >= q[k + 1]) {
            k++;
          }
        }

        for (int i = k + 1; i < 5; i++) {
          n[i]++;
        }
        for (int i = 0; i < 5; i++) {
          np[i] += dn[i];
        }

        for (int i = 1; i <= 3; i++) {
          final double d = np[i] - n[i];
          if ((d >= 1 && n[i + 1] - n[i] > 1) ||
              (d <= -1 && n[i - 1] - n[i] > 1)) {
            final int sign = d >= 0 ? 1 : -1;
            double qn = _parabolic(i, sign);
            if (q[i - 1] < qn && qn < q[i + 1]) {
              q[i] = qn;
            } else {
              q[i] = _linear(i, sign);
            }
            n[i] += sign;
          }
        }

        count++;
      }

      double _parabolic(int i, int d) {
        return q[i] +
            d /
                (n[i + 1] - n[i - 1]) *
                ((n[i] - n[i - 1] + d) * (q[i + 1] - q[i]) /
                    (n[i + 1] - n[i]) +
                    (n[i + 1] - n[i] - d) * (q[i] - q[i - 1]) /
                        (n[i] - n[i - 1]));
      }

      double _linear(int i, int d) {
        return q[i] + d * (q[i + d] - q[i]) / (n[i + d] - n[i]);
      }

      Duration get value => Duration(microseconds: q[2].round());
    }

    final _RunningStats stats = _RunningStats();
    final _P2Quantile p95 = _P2Quantile(0.95);
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
          stats.add(sw.elapsed);
          p95.add(sw.elapsed);
        }());
      }

      await Future.wait(futures);
    }

    totalWatch.stop();

    if (stats.count == 0) {
      Logger.info('No messages sent during benchmark');
      return;
    }

    final Duration totalElapsed = totalWatch.elapsed;
    final Duration avgLatency = stats.average;
    final Duration minLatency = stats.min ?? Duration.zero;
    final Duration maxLatency = stats.max ?? Duration.zero;
    final Duration? p95Latency =
        p95.isInitialized ? p95.value : null;
    final double throughput =
        messageCount / totalElapsed.inMilliseconds * 1000.0;

    Logger.info('Socket benchmark complete');
    Logger.info('Total messages: $messageCount');
    Logger.info('Total time: ${totalElapsed.inMilliseconds} ms');
    Logger.info('Average latency: ${avgLatency.inMilliseconds} ms');
    Logger.info('Min latency: ${minLatency.inMilliseconds} ms');
    Logger.info('Max latency: ${maxLatency.inMilliseconds} ms');
    if (p95Latency != null) {
      Logger.info('95th percentile latency: ${p95Latency.inMilliseconds} ms');
    }
    Logger.info('Throughput: ${throughput.toStringAsFixed(2)} msg/s');
  }

  void scheduleMessage(String chatGuid, String message, DateTime scheduledFor) {
    final delay = scheduledFor.difference(DateTime.now());
    Workmanager().registerOneOffTask(
      'send_\${scheduledFor.millisecondsSinceEpoch}',
      'sendScheduledMessage',
      initialDelay: delay,
      inputData: {'chatGuid': chatGuid, 'message': message},
    );
    Timer(delay, () {
      sendMessage('send-message', {'chatGuid': chatGuid, 'message': message});
    });
  }

  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      final chatGuid = inputData?['chatGuid'];
      final message = inputData?['message'];
      if (chatGuid != null && message != null) {
        socket.sendMessage('send-message', {'chatGuid': chatGuid, 'message': message});
      }
      return Future.value(true);
    });
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
