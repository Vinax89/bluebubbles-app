import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

import 'package:bluebubbles/services/network/http_service.dart';
import 'package:bluebubbles/database/models.dart';
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
    ss.settings.guidAuthKey.value = 'test-guid';
    ss.settings.serverAddress.value = 'http://example.com';
    ss.settings.simulateServerDelay.value = false;
    http = HttpService();
  });

  test('buildQueryParams adds guid', () {
    final params = http.buildQueryParams({'a': 'b'});
    expect(params['guid'], 'test-guid');
    expect(params['a'], 'b');
  });

  test('returnSuccessOrError returns value on 200', () async {
    final response = Response(requestOptions: RequestOptions(path: '/'), statusCode: 200);
    final result = await http.returnSuccessOrError(response);
    expect(result, isA<Response>());
  });

  test('returnSuccessOrError throws on non-200', () {
    final response = Response(requestOptions: RequestOptions(path: '/'), statusCode: 500);
    expect(() => http.returnSuccessOrError(response), throwsA(isA<Response>()));
  });

  test('runApiGuarded errors when origin missing', () async {
    ss.settings.serverAddress.value = '';
    http = HttpService();
    expect(() async {
      await http.runApiGuarded(() async => Response(requestOptions: RequestOptions(path: '/')));
    }, throwsA(isA<String>()));
  });

  test('runApiGuarded succeeds when checkOrigin false', () async {
    ss.settings.serverAddress.value = '';
    http = HttpService();
    final res = await http.runApiGuarded(() async => Response(requestOptions: RequestOptions(path: '/'), statusCode: 200), checkOrigin: false);
    expect(res.statusCode, 200);
  });
}

