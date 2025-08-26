import 'package:bluebubbles/services/backend/java_dart_interop/intents_service.dart';
import 'package:bluebubbles/services/network/http_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

class _FakeHttpService extends HttpService {
  _FakeHttpService() {
    dio = Dio();
  }

  @override
  Future<Response> answerFaceTime(String callUuid, {CancelToken? cancelToken}) async {
    return Response(
      requestOptions: RequestOptions(path: ''),
      data: {
        'data': {'link': 'https://example.com'}
      },
      statusCode: 200,
    );
  }
}

void main() {
  test('answerFaceTime launches in platform default mode on web', () async {
    if (!kIsWeb) {
      // Ensure that when not running on web, this test is skipped.
      expect(kIsWeb, isFalse);
      return;
    }

    http = _FakeHttpService();
    Uri? launchedUri;
    LaunchMode? usedMode;

    launchFaceTimeUrl = (
      Uri url, {
      LaunchMode mode = LaunchMode.platformDefault,
    }) async {
      launchedUri = url;
      usedMode = mode;
      return true;
    };

    final service = IntentsService();
    await service.answerFaceTime('123');

    expect(launchedUri, Uri.parse('https://example.com'));
    expect(usedMode, LaunchMode.platformDefault);
  });
}
