import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';
import 'package:system_tray/system_tray.dart' as st;
import 'package:window_manager/window_manager.dart';

import 'package:bluebubbles/helpers/helpers.dart';

final systemTray = st.SystemTray();

Future<void> initSystemTray() async {
  if (Platform.isWindows) {
    await systemTray.initSystemTray(
      iconPath: 'assets/icon/icon.ico',
      toolTip: 'BlueBubbles',
    );
  } else {
    String path;
    if (isFlatpak) {
      path = 'app.bluebubbles.BlueBubbles';
    } else if (isSnap) {
      path = p.joinAll(
          [p.dirname(Platform.resolvedExecutable), 'data/flutter_assets/assets/icon', 'icon.png']);
    } else {
      path = 'assets/icon/icon.png';
    }

    await trayManager.setIcon(path);
  }

  await setSystemTrayContextMenu(windowHidden: !appWindow.isVisible);
}

Future<void> setSystemTrayContextMenu({bool windowHidden = false}) async {
  if (Platform.isWindows) {
    st.Menu menu = st.Menu();
    menu.buildFrom([
      st.MenuItemLabel(
        label: windowHidden ? 'Show App' : 'Hide App',
        onClicked: (st.MenuItemBase menuItem) async {
          if (windowHidden) {
            await windowManager.show();
          } else {
            await windowManager.hide();
          }
        },
      ),
      st.MenuSeparator(),
      st.MenuItemLabel(
        label: 'Close App',
        onClicked: (_) async {
          if (await windowManager.isPreventClose()) {
            await windowManager.setPreventClose(false);
          }
          await windowManager.close();
        },
      ),
    ]);

    await systemTray.setContextMenu(menu);
  } else {
    await trayManager.setContextMenu(Menu(
      items: [
        MenuItem(
            label: windowHidden ? 'Show App' : 'Hide App',
            key: windowHidden ? 'show_app' : 'hide_app'),
        MenuItem.separator(),
        MenuItem(label: 'Close App', key: 'close_app'),
      ],
    ));
  }
}

