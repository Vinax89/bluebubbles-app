import 'package:bluebubbles/database/io/message.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/utils/logger/outputs/log_stream_output.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logs error when saving associated messages fails', () async {
    // Direct logs to the in-memory stream
    Logger.currentOutput = LogStreamOutput();

    final logs = <String>[];
    final sub = Logger.logStream.stream.listen(logs.add);

    // Trigger a failure by leaving Database.messages uninitialized
    final msg = Message(guid: 'test');
    saveUpdatedAssociatedMessages({'test': msg});

    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();

    expect(
      logs.any(
        (line) =>
            line.contains('Failed to put associated messages into DB!'),
      ),
      isTrue,
    );
  });
}

