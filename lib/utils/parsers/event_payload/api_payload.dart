import 'package:bluebubbles/database/global/server_payload.dart';

class ApiPayload {
  ApiPayload({
    required this.payload,
    required this.type,
    this.isLegacy = false,
  }) {
    data = isLegacy ? payload : payload['data'];
  }

  final dynamic payload;
  final bool isLegacy;
  final PayloadType type;
  late dynamic data;

  bool get dataIsString => data is String;
  bool get dataIsList => data is List;
}

