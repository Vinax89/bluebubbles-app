import 'package:bluebubbles/helpers/network/network_error_handler.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/constants.dart';
import 'package:bluebubbles/helpers/types/extensions/extensions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('handleSendError', () {
    test('handles dio Response', () {
      final message = Message(guid: 'temp-1');
      final response = Response(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 404,
        data: {'error': {'message': 'Not Found'}},
      );

      final updated = handleSendError(response, message);

      expect(updated.guid, 'error-Not Found-1');
      expect(updated.error, 404);
    });

    test('handles DioException', () {
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

      expect(
        updated.guid,
        'error-Connect timeout occured! Check your connection.-2',
      );
      expect(updated.error, 500);
    });

    test('handles generic error', () {
      final message = Message(guid: 'temp-3');

      final updated = handleSendError(Exception('oops'), message);

      expect(
        updated.guid,
        'error-Connection timeout, please check your internet connection and try again-3',
      );
      expect(updated.error, MessageError.BAD_REQUEST.code);
    });
  });
}

