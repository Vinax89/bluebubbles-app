import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/main.dart' as app;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const timezoneChannel = MethodChannel('flutter_timezone');
  const entityChannel = MethodChannel('google_mlkit_entity_extractor');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(entityChannel, null);
  });

  test('timezone failure surfaces', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      timezoneChannel,
      (MethodCall call) async => 'Invalid/Timezone',
    );

    final exception = await app.testInitTimezone();
    expect(exception, isNotNull);
  });

  test('model download failure surfaces', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      timezoneChannel,
      (MethodCall call) async => 'America/Detroit',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      entityChannel,
      (MethodCall call) async {
        if (call.method == 'isModelDownloaded') return false;
        if (call.method == 'downloadModel') {
          throw PlatformException(code: 'failed', message: 'download failed');
        }
        return null;
      },
    );

    final exception = await app.testInitTimezone();
    expect(exception, isNotNull);
  });
}
