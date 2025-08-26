import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:bluebubbles/helpers/network/network_error_handler.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/constants.dart';
import 'package:bluebubbles/helpers/types/extensions/extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('handleSendError', () {
    test('updates message for Response errors', () {
      final message = Message(guid: 'temp-123');
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 500,
        data: {'error': {'message': 'server failure'}},
      );

      final result = handleSendError(response, message);

      expect(result.error, 500);
      expect(result.guid!.startsWith('error-'), isTrue);
      expect(result.guid, contains('server failure'));
    });

    test('updates message for DioException timeout', () {
      final message = Message(guid: 'temp-123');
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = handleSendError(dioError, message);

      expect(result.error, MessageError.BAD_REQUEST.code);
      expect(result.guid!.startsWith('error-'), isTrue);
      expect(result.guid, contains('Connect timeout occured!'));
    });
  });
}
