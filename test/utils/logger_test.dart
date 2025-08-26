import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';

import 'package:bluebubbles/services/backend/filesystem/filesystem_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';

void main() {
  late Directory tempDir;
  late Directory logDir;
  late BaseLogger logger;

  setUp(() async {
    Get.reset();
    fs = Get.put(FilesystemService());
    tempDir = await Directory.systemTemp.createTemp('logger_test');
    fs.appDocDir = tempDir;
    logger = BaseLogger();
    Get.put<BaseLogger>(logger);
    logDir = Directory(logger.logDir)..createSync(recursive: true);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    Get.reset();
  });

  test('getLogs returns expected lines', () async {
    final logFile = File(join(logDir.path, logger.latestLogName));
    await logFile.writeAsString([
      '2024-01-01 [INFO] first',
      'continuation line',
      '2024-01-02 [ERROR] second'
    ].join('\n'));

    final logs = await logger.getLogs();
    expect(logs, [
      '2024-01-01 [INFO] first\ncontinuation line',
      '2024-01-02 [ERROR] second'
    ]);
    expect(logs.last.contains('second'), isTrue);
  });

  test('compressLogs creates a ZIP', () async {
    final logFile = File(join(logDir.path, logger.latestLogName));
    await logFile.writeAsString('2024-01-01 [INFO] log');

    final zipPath = logger.compressLogs();
    final zipFile = File(zipPath);
    expect(zipFile.existsSync(), isTrue);

    final archive = ZipDecoder().decodeBytes(zipFile.readAsBytesSync());
    expect(archive.files.any((f) => f.name.endsWith('.log')), isTrue);
  });

  test('clearLogs removes existing logs', () {
    final logFile = File(join(logDir.path, logger.latestLogName));
    logFile.writeAsStringSync('test log');
    expect(logDir.listSync().isNotEmpty, isTrue);

    logger.clearLogs();
    expect(logDir.listSync(), isEmpty);
  });
}
