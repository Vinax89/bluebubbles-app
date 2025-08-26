import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:bluebubbles/services/ui/theme/themes_service.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/constants.dart';
import 'package:bluebubbles/app/components/custom/custom_bouncing_scroll_physics.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';

class FakeSettingsService extends SettingsService {
  FakeSettingsService() {
    settings = Settings();
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    ss = FakeSettingsService();
    ts = ThemesService();
  });

  test('scrollPhysics uses bouncing on iOS skin', () {
    ss.settings.skin.value = Skins.iOS;
    final physics = ts.scrollPhysics;
    expect(physics.parent, isA<CustomBouncingScrollPhysics>());
  });

  test('scrollPhysics uses clamping on non-iOS skin', () {
    ss.settings.skin.value = Skins.Material;
    final physics = ts.scrollPhysics;
    expect(physics.parent, isA<ClampingScrollPhysics>());
  });
}

