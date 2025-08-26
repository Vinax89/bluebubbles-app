@Tags(['stress'])

import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Stubbed replacement for [StartupTasks.initStartupServices] to speed up tests
Future<void> _stubInitStartupServices() async {
  await Future.delayed(const Duration(milliseconds: 10));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync();
  });

  tearDown(() {
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
    Get.reset();
  });

  group('StartupTasks.initStartupServices stress test', () {
    test('sequential initialization', () async {
      const iterations = 5;
      final stopwatch = Stopwatch()..start();
      final memUsage = <int>[];
      for (var i = 0; i < iterations; i++) {
        await _stubInitStartupServices();
        final rss = ProcessInfo.currentRss;
        memUsage.add(rss);
        Timeline.instantSync('init iteration', arguments: {'iteration': i, 'rss': rss});

        // Release resources between iterations
        Get.reset();
        if (tmpDir.existsSync()) {
          tmpDir.deleteSync(recursive: true);
        }
        tmpDir = Directory.systemTemp.createTempSync();
      }
      stopwatch.stop();
      // Output memory usage for manual inspection
      debugPrint('Memory usage (RSS): $memUsage');
      debugPrint('Total elapsed: ${stopwatch.elapsed}');
    });

    test('concurrent initialization', () async {
      const runs = 3;
      await Future.wait(List.generate(runs, (_) => _stubInitStartupServices()));
    });
  });
}
