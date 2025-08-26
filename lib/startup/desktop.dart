import 'dart:math';
import 'dart:ui';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:universal_io/io.dart';
import 'package:window_manager/window_manager.dart';

import 'package:bluebubbles/app/system_tray.dart';
import 'package:bluebubbles/services/services.dart';

import 'helpers.dart';

Future<Exception?> initDesktopWindow(List<String> arguments) async {
  return await captureError(() async {
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
