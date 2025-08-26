import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:dio/dio.dart';

Message handleSendError(dynamic error, Message m) {
  if (error is Response) {
    dynamic data = error.data;
    String errorMessage;
    if (data is Map && data['error'] is Map && (data['error'] as Map).containsKey('message')) {
      errorMessage = (data['error'] as Map)['message'].toString();
    } else {
      errorMessage = data.toString();
    }

    m.guid = m.guid!.replaceAll("temp", "error-$errorMessage");
    m.error = error.statusCode ?? MessageError.BAD_REQUEST.code;
  } else if (error is DioException) {
    String _error;
    if (error.type == DioExceptionType.connectionTimeout) {
      _error = "Connect timeout occurred! Check your connection.";
    } else if (error.type == DioExceptionType.sendTimeout) {
      _error = "Send timeout occurred!";
    } else if (error.type == DioExceptionType.receiveTimeout) {
      _error = "Receive data timeout occurred! Check server logs for more info.";
    } else {
      _error = error.error.toString();
    }
    m.guid = m.guid!.replaceAll("temp", "error-$_error");
    m.error = error.response?.statusCode ?? MessageError.BAD_REQUEST.code;
  } else {
    m.guid = m.guid!.replaceAll("temp", "error-Connection timeout, please check your internet connection and try again");
    m.error = MessageError.BAD_REQUEST.code;
  }

  return m;
}
