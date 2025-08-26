import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'helpers.dart';

Future<Exception?> initTimezone() async {
  return await captureError(() async {
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
