@Tags(['stress'])
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bluebubbles/services/network/socket_service.dart';

/// Environment flag to enable the socket stress tests.
const bool runSocketStressTest = bool.fromEnvironment('ENABLE_FLOOD_TEST', defaultValue: true);

class MockSocket {
  final Map<String, Function> _handlers = {};

  void on(String event, Function(dynamic) handler) {
    _handlers[event] = handler;
  }

  void emitWithAck(String event, Map<String, dynamic> message, {Function? ack}) {
    // Immediately return the message in the ack to simulate server response
    if (ack != null) {
      Future.microtask(() => ack({
            'status': 'ok',
            'encrypted': false,
            'data': message,
          }));
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

void main() {
  if (!runSocketStressTest) {
    return;
  }

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
  });
}

