import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_ml_kit/google_ml_kit.dart' hide Message;
import 'package:intl/date_symbol_data_local.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:universal_io/io.dart';
import 'package:window_manager/window_manager.dart';

import 'package:bluebubbles/app/layouts/startup/failure_to_start.dart';
import 'package:bluebubbles/app/layouts/startup/splash_screen.dart';
import 'package:bluebubbles/app/system_tray.dart';
import 'package:bluebubbles/database/html/media_kit.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/backend/startup_tasks.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/network/http_overrides.dart';
import 'package:bluebubbles/services/service_locator.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/main.dart' show Main;

@pragma('vm:entry-point')
Future<void> initializeApp(bool bubble, List<String> arguments) async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      HttpOverrides.global = BadCertOverride();
      FlutterError.onError = (details) {
        Logger.error("Rendering Error: ${details.exceptionAsString()}",
            error: details.exception, trace: details.stack);
      };

      Exception? exception;

      exception ??= await _initServices(bubble, arguments);
      if (!kIsWeb && !kIsDesktop && exception == null) {
        exception ??= await _initTimezone();
      }
      if (kIsDesktop && exception == null) {
        exception ??= await _initDesktopWindow(arguments);
      }

      if (exception == null) {
        _initTheme();
      } else {
        runApp(FailureToStart(e: exception));
        throw exception;
      }
    },
    (dynamic error, StackTrace stackTrace) {
      Logger.error("Unhandled Exception", trace: stackTrace, error: error);
    },
  );
}

Future<Exception?> _initServices(bool bubble, List<String> arguments) async {
  return await _captureError(() async {
    setupServices();
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

Future<Exception?> _initTimezone() async {
  return await _captureError(() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(
          tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {}
    if (!await EntityExtractorModelManager()
        .isModelDownloaded(EntityExtractorLanguage.english.name)) {
      EntityExtractorModelManager().downloadModel(
          EntityExtractorLanguage.english.name,
          isWifiRequired: false);
    }
  }, "Time zone initialization failed");
}

Future<Exception?> _initDesktopWindow(List<String> arguments) async {
  return await _captureError(() async {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(ss.settings.closeToTray.value);
    await windowManager.setTitle('BlueBubbles');
    await Window.initialize();
    if (Platform.isWindows) {
      await Window.hideWindowControls();
    } else if (Platform.isLinux) {
      await windowManager.setTitleBarStyle(
          ss.settings.useCustomTitleBar.value
              ? TitleBarStyle.hidden
              : TitleBarStyle.normal);
    }
    windowManager.addListener(DesktopWindowListener.instance);
    doWhenWindowReady(() async {
      await windowManager.setMinimumSize(const Size(300, 300));
      Display primary = await ScreenRetriever.instance.getPrimaryDisplay();

      Size size = await windowManager.getSize();
      double width = ss.prefs.getDouble("window-width") ?? size.width;
      double height = ss.prefs.getDouble("window-height") ?? size.height;

      width = width.clamp(300, max(300, primary.size.width));
      height = height.clamp(300, max(300, primary.size.height));
      await windowManager.setSize(Size(width, height));
      await ss.prefs.setDouble("window-width", width);
      await ss.prefs.setDouble("window-height", height);

      await windowManager.setAlignment(Alignment.center);
      Offset offset = await windowManager.getPosition();
      double? posX = ss.prefs.getDouble("window-x") ?? offset.dx;
      double? posY = ss.prefs.getDouble("window-y") ?? offset.dy;

      posX = posX.clamp(0, max(0, primary.size.width - width));
      posY = posY.clamp(0, max(0, primary.size.height - height));
      await windowManager.setPosition(Offset(posX, posY), animate: true);
      await ss.prefs.setDouble("window-x", posX);
      await ss.prefs.setDouble("window-y", posY);

      await windowManager.setTitle('BlueBubbles');
      if (arguments.firstOrNull != "minimized") {
        await windowManager.show();
      }
      if (!(ss.canAuthenticate && ss.settings.shouldSecure.value)) {
        chats.init();
        socket;
      }
    });
    await dotenv.load(fileName: '.env', isOptional: true);
  }, "Desktop initialization failed");
}

void _initTheme() {
  ThemeData light = ThemeStruct.getLightTheme().data;
  ThemeData dark = ThemeStruct.getDarkTheme().data;

  final tuple = ts.getStructsFromData(light, dark);
  light = tuple.item1;
  dark = tuple.item2;

  runApp(Main(
    lightTheme: light,
    darkTheme: dark,
  ));
}

Future<Exception?> _captureError(
    Future<void> Function() f, String msg) async {
  try {
    await f();
    return null;
  } catch (e, s) {
    Logger.error(msg, error: e, trace: s);
    return Exception(msg);
  }
}

class DesktopWindowListener extends WindowListener {
  DesktopWindowListener._();

  static final DesktopWindowListener instance = DesktopWindowListener._();

  @override
  void onWindowFocus() {
    ls.open();
  }

  @override
  void onWindowBlur() {
    ls.close();
  }

  @override
  void onWindowResized() async {
    Size size = await windowManager.getSize();
    await ss.prefs.setDouble("window-width", size.width);
    await ss.prefs.setDouble("window-height", size.height);
  }

  @override
  void onWindowMoved() async {
    Offset offset = await windowManager.getPosition();
    await ss.prefs.setDouble("window-x", offset.dx);
    await ss.prefs.setDouble("window-y", offset.dy);
  }

  @override
  void onWindowEvent(String eventName) async {
    switch (eventName) {
      case "hide":
        await setSystemTrayContextMenu(windowHidden: true);
        break;
      case "show":
        await setSystemTrayContextMenu(windowHidden: false);
        break;
    }
  }

  @override
  void onWindowClose() async {
    if (await windowManager.isPreventClose()) {
      await windowManager.hide();
    }
  }
}

