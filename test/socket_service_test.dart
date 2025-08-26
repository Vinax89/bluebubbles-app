@Tags(['stress'])
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bluebubbles/services/network/socket_service.dart';
import 'package:bluebubbles/utils/crypto_utils.dart';
import 'package:pointycastle/export.dart';

/// Environment flag to enable the socket stress tests.
const bool runSocketStressTest = bool.fromEnvironment('ENABLE_FLOOD_TEST', defaultValue: false);

class MockSocket {
  final Map<String, Function> _handlers = {};
  Map<String, dynamic>? lastMessage;
  final String sessionKey = 'server-session';

  void on(String event, Function(dynamic) handler) {
    _handlers[event] = handler;
  }

  void emitWithAck(String event, Map<String, dynamic> message, {Function? ack}) {
    lastMessage = message;
    if (event == 'handshake') {
      final n = BigInt.parse(message['n'], radix: 16);
      final e = BigInt.parse(message['e'], radix: 16);
      final pub = RSAPublicKey(n, e);
      final encrypted = rsaEncrypt(sessionKey, pub);
      if (ack != null) {
        Future.microtask(() => ack({'sessionKey': encrypted}));
      }
      return;
    }

    if (message['encrypted'] == true) {
      final decrypted = decryptWithSessionKey(message['data'], sessionKey);
      if (ack != null) {
        Future.microtask(() => ack({
              'status': 'ok',
              'encrypted': true,
              'data': encryptWithSessionKey(decrypted, sessionKey),
            }));
      }
    } else {
      if (ack != null) {
        Future.microtask(() => ack({
              'status': 'ok',
              'encrypted': false,
              'data': message,
            }));
      }
    }
  }

  void connect() {
    final handler = _handlers['connect'];
    if (handler != null) handler(null);
  }

  void disconnect() {
    final handler = _handlers['disconnect'];
    if (handler != null) handler(null);
  }

  void dispose() {}
}

class TestSocketService extends SocketService {
  @override
  String get serverAddress => 'http://localhost';

  @override
  String get password => '';

  @override
  void startSocket() {
    // Overridden to prevent real network calls during tests
  }
}

@Tags(['integration'])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  test('SocketService handles disconnect during message flood', () async {
    final service = TestSocketService();
    service.socket = MockSocket();
    service.handleStatusUpdate(SocketState.connected, null);

    // Flood the service with messages
    final futures = List.generate(50, (i) => service.sendMessage('event', {'index': i}));

    // Inject a disconnect while messages are in-flight
    service.handleStatusUpdate(SocketState.disconnected, null);

    final responses = await Future.wait(futures);

    // Verify that all responses completed and the state reflects disconnect
    expect(responses.length, 50);
    expect(service.state.value, SocketState.disconnected);
  }, skip: !runSocketStressTest);

  test('SocketService performs key exchange and encrypts messages', () async {
    final service = TestSocketService();
    final mock = MockSocket();
    service.socket = mock;
    await service.performKeyExchange();
    expect(service.sessionKey, mock.sessionKey);

    final response = await service.sendMessage('event', {'foo': 'bar'});
    expect(mock.lastMessage?['encrypted'], true);
    expect(response['encrypted'], true);
    expect(response['data']['foo'], 'bar');
  });
}

