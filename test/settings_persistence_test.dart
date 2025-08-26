import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/database/global/settings.dart';

void main() {
  test('chaosMode and stressMode persist through toMap and fromMap', () {
    final settings = Settings();
    settings.chaosMode.value = true;
    settings.stressMode.value = true;

    final map = settings.toMap(includeAll: true);
    expect(map['chaosMode'], isTrue);
    expect(map['stressMode'], isTrue);

    final restored = Settings.fromMap(map);
    expect(restored.chaosMode.value, isTrue);
    expect(restored.stressMode.value, isTrue);
  });
}
