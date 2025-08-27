import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/settings_widgets.dart';
import 'package:bluebubbles/services/services.dart';

class AccessibilityPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AccessibilityPanelState();
}

class _AccessibilityPanelState extends OptimizedState<AccessibilityPanel> {
  void saveSettings() {
    ss.saveSettings(ss.settings);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Accessibility',
      iosSubtitle: iosSubtitle,
      materialSubtitle: materialSubtitle,
      tileColor: tileColor,
      headerColor: headerColor,
      bodySlivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            SettingsSection(
              backgroundColor: tileColor,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 15, top: 10),
                  child: Text('Text Scale', style: context.theme.textTheme.bodyLarge),
                ),
                Obx(() => SettingsSlider(
                      startingVal: ss.settings.textScale.value,
                      update: (double val) => ss.settings.textScale.value = val,
                      onChangeEnd: (double val) => saveSettings(),
                      min: 1.0,
                      max: 2.0,
                      divisions: 10,
                      backgroundColor: tileColor,
                      leading: const SettingsLeadingIcon(
                        iosIcon: CupertinoIcons.textformat_size,
                        materialIcon: Icons.format_size,
                        containerColor: Colors.indigo,
                      ),
                    )),
                const SettingsDivider(padding: EdgeInsets.only(left: 16.0)),
                Obx(() => SettingsSwitch(
                      onChanged: (bool val) {
                        ss.settings.highContrast.value = val;
                        saveSettings();
                      },
                      initialVal: ss.settings.highContrast.value,
                      title: 'High Contrast',
                      backgroundColor: tileColor,
                      leading: const SettingsLeadingIcon(
                        iosIcon: CupertinoIcons.circle_lefthalf_fill,
                        materialIcon: Icons.brightness_6,
                        containerColor: Colors.black,
                      ),
                    )),
              ],
            ),
          ]),
        )
      ],
    );
  }
}

