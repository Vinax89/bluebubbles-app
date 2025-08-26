import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:bluebubbles/helpers/network/network_error_handler.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/constants.dart';
import 'package:bluebubbles/helpers/types/extensions/extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('handleSendError', () {
    test('handles Response errors', () {
      final message = Message(guid: 'temp-1');
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

    test('handles DioException with response', () {
      final message = Message(guid: 'temp-2');
      final requestOptions = RequestOptions(path: '/');
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 500,
      );
      final error = DioException(
        requestOptions: requestOptions,
        response: response,
        type: DioExceptionType.connectionTimeout,
      );

      final updated = handleSendError(error, message);

      expect(updated.guid,
          'error-Connect timeout occured! Check your connection.-2');
      expect(updated.error, 500);
    });

    test('handles DioException without response', () {
      final message = Message(guid: 'temp-3');
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = handleSendError(dioError, message);

      expect(result.error, MessageError.BAD_REQUEST.code);
      expect(result.guid!.startsWith('error-'), isTrue);
      expect(result.guid, contains('Connect timeout occured!'));
    });

    test('handles generic error', () {
      final message = Message(guid: 'temp-4');

      final updated = handleSendError(Exception('oops'), message);

      expect(updated.guid,
          'error-Connection timeout, please check your internet connection and try again-4');
      expect(updated.error, MessageError.BAD_REQUEST.code);
    });
  });
}
