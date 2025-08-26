import 'package:bluebubbles/services/network/socket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

class TestSocketService extends SocketService {
  bool called = false;
  @override
  Future<Map<String, dynamic>> sendMessage(String event, Map<String, dynamic> message) async {
    called = true;
    return {};
  }
}

void main() {
  test('scheduled message dispatches at correct time', () {
    final service = TestSocketService();
    fakeAsync((async) {
      final when = DateTime.now().add(const Duration(minutes: 1));
      service.scheduleMessage('test', 'hello', when);
      expect(service.called, isFalse);
      async.elapse(const Duration(minutes: 1, seconds: 1));
      expect(service.called, isTrue);
    });
  });
}
