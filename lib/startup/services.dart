import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bluebubbles/app/layouts/startup/splash_screen.dart';
import 'package:bluebubbles/database/html/media_kit.dart';
import 'package:bluebubbles/helpers/backend/startup_tasks.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';

import 'helpers.dart';

Future<Exception?> initServices(bool bubble, List<String> arguments) async {
  return await captureError(() async {
    await StartupTasks.initStartupServices(isBubble: bubble);
    StartupTasks.onStartup().then((_) {
      Logger.info("Startup tasks completed");
    }).catchError((e, s) {
      Logger.error("Failed to complete startup tasks!", error: e, trace: s);
    });
    await initializeDateFormatting();
    MediaKit.ensureInitialized();
    if (!ss.settings.finishedSetup.value && !kIsWeb && !kIsDesktop) {
      runApp(MaterialApp(
          home: SplashScreen(shouldNavigate: false),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSwatch(
                backgroundColor: PlatformDispatcher.instance.platformBrightness ==
                        Brightness.dark
                    ? Colors.black
                    : Colors.white),
          )));
    }
    fs.checkFont();
  }, "Failure during app initialization!");
}
