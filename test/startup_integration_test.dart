import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/main.dart' as app;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('main startup', () async {
    expect(app.initializeApp(false, []), completes);
  });

  test('bubble startup', () async {
    expect(app.initializeApp(true, []), completes);
  });
}
