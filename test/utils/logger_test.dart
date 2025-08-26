import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/services/backend/filesystem/filesystem_service.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put(FilesystemService());
  });

  test('getLogs includes last log entry', () async {
    final tempDir = await Directory.systemTemp.createTemp();
    fs.appDocDir = tempDir;
    final logsDir = Directory(join(tempDir.path, 'logs'))..createSync(recursive: true);
    final logFile = File(join(logsDir.path, 'bluebubbles-latest.log'));
    logFile.writeAsStringSync(
      '2024-01-01 First log\n'
      'Continuation\n'
      '2024-01-02 Second log',
    );

    final logger = BaseLogger();
    final logs = await logger.getLogs();
    expect(logs.length, 2);
    expect(logs.last.contains('Second log'), isTrue);

    tempDir.deleteSync(recursive: true);
  });
}
