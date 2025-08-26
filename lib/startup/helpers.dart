import 'package:bluebubbles/utils/logger/logger.dart';

Future<Exception?> captureError(Future<void> Function() f, String msg) async {
  try {
    await f();
    return null;
  } catch (e, s) {
    Logger.error(msg, error: e, trace: s);
    return Exception(msg);
  }
}
