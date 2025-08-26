import 'package:flutter/foundation.dart';

import 'desktop.dart';
import 'timezone.dart';

Future<Exception?> initPlatform(List<String> arguments) async {
  if (kIsDesktop) {
    return await initDesktopWindow(arguments);
  } else if (!kIsWeb) {
    return await initTimezone();
  }
  return null;
}
