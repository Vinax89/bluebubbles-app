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

  setUp(() async {
    Get.reset();
    Get.put(FilesystemService());
    initLogger();
    tempDir = await Directory.systemTemp.createTemp('logger_test');
    fs.appDocDir = tempDir;
    logDir = Directory(Logger.logDir)..createSync(recursive: true);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('getLogs returns expected lines', () async {
    final logFile = File(join(logDir.path, Logger.latestLogName));
    await logFile.writeAsString([
      '2024-01-01 [INFO] first',
      'continuation line',
      '2024-01-02 [ERROR] second'
    ].join('\n'));

    final logs = await Logger.getLogs();
    expect(logs, [
      '2024-01-01 [INFO] first\ncontinuation line',
      '2024-01-02 [ERROR] second'
    ]);
  });

  test('compressLogs creates a ZIP', () async {
    final logFile = File(join(logDir.path, Logger.latestLogName));
    await logFile.writeAsString('2024-01-01 [INFO] log');

    final zipPath = Logger.compressLogs();
    final zipFile = File(zipPath);
    expect(zipFile.existsSync(), isTrue);

    final archive = ZipDecoder().decodeBytes(zipFile.readAsBytesSync());
    expect(archive.files.any((f) => f.name.endsWith('.log')), isTrue);
  });

  test('clearLogs removes existing logs', () {
    final logFile = File(join(logDir.path, Logger.latestLogName));
    logFile.writeAsStringSync('test log');
    expect(logDir.listSync().isNotEmpty, isTrue);

    Logger.clearLogs();
    expect(logDir.listSync(), isEmpty);
  });
}

