import 'package:bluebubbles/database/global/server_payload.dart';
import 'models.dart';

/// Parser to transform raw server payloads into strongly typed models.
class ApiPayloadParser {
  ApiPayloadParser(this.payload);

  final ServerPayload payload;

  /// Parses the payload into typed models based on the [PayloadType].
  Future<Object?> parse() async {
    if (payload.isLegacy) return payload.originalJson;

    switch (payload.type) {
      case PayloadType.ATTACHMENT:
        return parseAttachment();
      case PayloadType.CHAT:
        return parseChat();
      case PayloadType.HANDLE:
        return parseHandle();
      default:
        return payload.data;
    }
  }

  /// Parse attachment payloads and return [AttachmentPayload] objects.
  Future<List<AttachmentPayload>> parseAttachment() async {
    final List<dynamic> dataList =
        payload.isList ? List<dynamic>.from(payload.data) : [payload.data];
    if (dataList.isEmpty) return <AttachmentPayload>[];

    bool needsEnrichment = dataList.every((element) => element is String);
    List<dynamic> enriched = dataList;
    if (needsEnrichment) {
      enriched = await enrichAttachments(dataList.cast<String>());
    }

    return enriched
        .map((e) => e is AttachmentPayload
            ? e
            : AttachmentPayload.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Parse chat payloads and return [ChatPayload] objects.
  Future<List<ChatPayload>> parseChat() async {
    final List<dynamic> dataList =
        payload.isList ? List<dynamic>.from(payload.data) : [payload.data];
    if (dataList.isEmpty) return <ChatPayload>[];

    bool needsEnrichment = dataList.every((element) => element is String);
    List<dynamic> enriched = dataList;
    if (needsEnrichment) {
      enriched = await enrichChats(dataList.cast<String>());
    }

    return enriched
        .map((e) => e is ChatPayload
            ? e
            : ChatPayload.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Parse handle payloads and return [HandlePayload] objects.
  Future<List<HandlePayload>> parseHandle() async {
    final List<dynamic> dataList =
        payload.isList ? List<dynamic>.from(payload.data) : [payload.data];
    if (dataList.isEmpty) return <HandlePayload>[];

    bool needsEnrichment = dataList.every((element) => element is String);
    List<dynamic> enriched = dataList;
    if (needsEnrichment) {
      enriched = await enrichHandles(dataList.cast<String>());
    }

    return enriched
        .map((e) => e is HandlePayload
            ? e
            : HandlePayload.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Attachment enrichment hook. Can be overridden in tests.
  Future<List<AttachmentPayload>> enrichAttachments(List<String> guids) async =>
      <AttachmentPayload>[];

  /// Chat enrichment hook. Can be overridden in tests.
  Future<List<ChatPayload>> enrichChats(List<String> guids) async =>
      <ChatPayload>[];

  /// Handle enrichment hook. Can be overridden in tests.
  Future<List<HandlePayload>> enrichHandles(List<String> addresses) async =>
      <HandlePayload>[];
}
