import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/main.dart' as app;
import 'package:bluebubbles/helpers/backend/startup_tasks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('main startup', () async {
    expect(app.initializeApp(false, []), completes);
  });

  test('bubble startup', () async {
    expect(app.initializeApp(true, []), completes);
  });

  test('startup failure halts initialization', () async {
    StartupTasks.onStartupOverride = () async {
      throw Exception('startup failed');
    };
    await expectLater(app.initializeApp(false, []), throwsException);
    StartupTasks.onStartupOverride = null;
  });
}
