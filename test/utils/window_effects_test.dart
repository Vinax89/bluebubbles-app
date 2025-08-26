import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/utils/window_effects.dart';

void main() {
  group('parsedWindowsVersion', () {
    test('parses typical build number', () {
      expect(
        parsedWindowsVersion('Windows 10 Pro 10.0 (Build 19045.2846)'),
        19045,
      );
    });

    test('parses windows 11 build number', () {
      expect(
        parsedWindowsVersion('Microsoft Windows 10.0 (Build 22621)'),
        22621,
      );
    });

    test('returns null for unexpected format', () {
      expect(parsedWindowsVersion('Microsoft Windows [Version 10.0.19045.3324]'), isNull);
      expect(parsedWindowsVersion('Unknown Format'), isNull);
    });
  });
}
