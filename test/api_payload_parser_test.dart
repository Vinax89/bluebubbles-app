import 'package:test/test.dart';
import 'package:bluebubbles/database/global/server_payload.dart';
import 'package:bluebubbles/utils/parsers/event_payload/api_payload_parser.dart';
import 'package:bluebubbles/utils/parsers/event_payload/models.dart';

class _TestParser extends ApiPayloadParser {
  _TestParser(
    ServerPayload payload, {
    this.attachments,
    this.chats,
    this.handles,
  }) : super(payload);

  final Future<List<AttachmentPayload>> Function(List<String>)? attachments;
  final Future<List<ChatPayload>> Function(List<String>)? chats;
  final Future<List<HandlePayload>> Function(List<String>)? handles;

  @override
  Future<List<AttachmentPayload>> enrichAttachments(List<String> guids) async {
    if (attachments != null) return attachments!(guids);
    return super.enrichAttachments(guids);
  }

  @override
  Future<List<ChatPayload>> enrichChats(List<String> guids) async {
    if (chats != null) return chats!(guids);
    return super.enrichChats(guids);
  }

  @override
  Future<List<HandlePayload>> enrichHandles(List<String> addresses) async {
    if (handles != null) return handles!(addresses);
    return super.enrichHandles(addresses);
  }
}

ServerPayload buildPayload({required PayloadType type, required dynamic data}) {
  return ServerPayload(
    originalJson: {},
    data: data,
    isLegacy: false,
    type: type,
    subtype: null,
    isEncrypted: false,
    isPartial: false,
    encoding: PayloadEncoding.JSON_OBJECT,
    encryptionType: EncryptionType.AES_PB,
  );
}

void main() {
  test('parses attachment payloads and enriches GUIDs', () async {
    final payload = buildPayload(type: PayloadType.ATTACHMENT, data: [
      {
        'guid': 'att-1',
        'mimeType': 'image/png',
      }
    ]);
    final parser = ApiPayloadParser(payload);
    final parsed = await parser.parseAttachment();
    expect(parsed, isA<List<AttachmentPayload>>());
    expect(parsed.first.guid, 'att-1');

    final enrichPayload = buildPayload(
      type: PayloadType.ATTACHMENT,
      data: ['att-2'],
    );
    final enrichParser = _TestParser(enrichPayload,
        attachments: (guids) async =>
            guids.map((g) => AttachmentPayload(guid: g)).toList());
    final enriched = await enrichParser.parseAttachment();
    expect(enriched.first.guid, 'att-2');
  });

  test('parses chat payloads and enriches GUIDs', () async {
    final payload = buildPayload(type: PayloadType.CHAT, data: [
      {
        'guid': 'chat-1',
        'participants': ['+123'],
      }
    ]);
    final parser = ApiPayloadParser(payload);
    final parsed = await parser.parseChat();
    expect(parsed, isA<List<ChatPayload>>());
    expect(parsed.first.guid, 'chat-1');

    final enrichPayload = buildPayload(
      type: PayloadType.CHAT,
      data: ['chat-2'],
    );
    final enrichParser = _TestParser(enrichPayload,
        chats: (ids) async =>
            ids.map((id) => ChatPayload(guid: id, participants: ['a'])).toList());
    final enriched = await enrichParser.parseChat();
    expect(enriched.first.guid, 'chat-2');
  });

  test('parses handle payloads and enriches addresses', () async {
    final payload = buildPayload(type: PayloadType.HANDLE, data: [
      {
        'address': '+1555',
      }
    ]);
    final parser = ApiPayloadParser(payload);
    final parsed = await parser.parseHandle();
    expect(parsed, isA<List<HandlePayload>>());
    expect(parsed.first.address, '+1555');

    final enrichPayload = buildPayload(
      type: PayloadType.HANDLE,
      data: ['+1666'],
    );
    final enrichParser = _TestParser(enrichPayload,
        handles: (addresses) async =>
            addresses.map((a) => HandlePayload(address: a)).toList());
    final enriched = await enrichParser.parseHandle();
    expect(enriched.first.address, '+1666');
  });
}
