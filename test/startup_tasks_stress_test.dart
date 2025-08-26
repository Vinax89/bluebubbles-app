import 'dart:developer';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/helpers/backend/startup_tasks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StartupTasks.initStartupServices stress test', () {
    test('sequential initialization', () async {
      const iterations = 5;
      final stopwatch = Stopwatch()..start();
      final memUsage = <int>[];
      for (var i = 0; i < iterations; i++) {
        await StartupTasks.initStartupServices();
        final rss = ProcessInfo.currentRss;
        memUsage.add(rss);
        Timeline.instantSync('init iteration', arguments: {'iteration': i, 'rss': rss});
      }
      stopwatch.stop();
      // Output memory usage for manual inspection
      print('Memory usage (RSS): $memUsage');
      print('Total elapsed: ${stopwatch.elapsed}');
    });

    test('concurrent initialization', () async {
      const runs = 3;
      await Future.wait(List.generate(runs, (_) => StartupTasks.initStartupServices()));
    });
  });
}
