import 'package:get/get.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';

/// Represents a client session identified by [deviceId].
class ClientSession {
  ClientSession({required this.deviceId, required this.token, required this.expiresAt});

  final String deviceId;
  String token;
  DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Registry that tracks active client sessions by device ID.
class SessionRegistry extends GetxService {
  final RxMap<String, ClientSession> _sessions = <String, ClientSession>{}.obs;

  /// Returns a list of all known sessions.
  List<ClientSession> get sessions => _sessions.values.toList();

  ClientSession? get(String deviceId) => _sessions[deviceId];

  void register(ClientSession session) {
    _sessions[session.deviceId] = session;
  }

  bool validate(String deviceId) {
    final session = _sessions[deviceId];
    return session != null && !session.isExpired;
  }

  Future<void> refresh(String deviceId) async {
    try {
      final response = await http.refreshSession(deviceId);
      final data = response.data;
      if (data is Map) {
        final token = data['token'] as String?;
        final expires = data['expiresAt'] as int?;
        if (token != null && expires != null) {
          register(ClientSession(
            deviceId: deviceId,
            token: token,
            expiresAt: DateTime.fromMillisecondsSinceEpoch(expires),
          ));
        }
      }
    } catch (e, s) {
      Logger.error('Failed to refresh session for $deviceId', error: e, trace: s);
    }
  }

  Future<void> loadSessions() async {
    try {
      final response = await http.getSessions();
      final data = response.data;
      if (data is List) {
        _sessions.clear();
        for (final item in data) {
          if (item is Map) {
            final device = item['deviceId'] as String?;
            final token = item['token'] as String?;
            final expires = item['expiresAt'] as int?;
            if (device != null && token != null && expires != null) {
              _sessions[device] = ClientSession(
                deviceId: device,
                token: token,
                expiresAt: DateTime.fromMillisecondsSinceEpoch(expires),
              );
            }
          }
        }
      }
    } catch (e, s) {
      Logger.error('Failed to load sessions', error: e, trace: s);
    }
  }

  Future<void> revoke(String deviceId) async {
    try {
      await http.revokeSession(deviceId);
    } catch (e, s) {
      Logger.error('Failed to revoke session for $deviceId', error: e, trace: s);
    } finally {
      _sessions.remove(deviceId);
    }
  }
}
