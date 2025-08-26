import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:bluebubbles/utils/parsers/event_payload/api_payload.dart';
import 'package:bluebubbles/utils/parsers/event_payload/api_payload_parser.dart';
import 'package:bluebubbles/database/global/server_payload.dart';
import 'package:bluebubbles/services/network/http_service.dart';

class MockHttpService extends HttpService {
  MockHttpService({
    required this.messagesMap,
    required this.chatsMap,
    required this.attachmentsMap,
    required this.handlesMap,
  }) {
    dio = Dio();
  }

  final Map<String, dynamic> messagesMap;
  final Map<String, dynamic> chatsMap;
  final Map<String, dynamic> attachmentsMap;
  final Map<String, dynamic> handlesMap;

  @override
  Future<Response> messages({List<String> withQuery = const [], List<dynamic> where = const [], String sort = "DESC", int? before, int? after, String? chatGuid, int offset = 0, int limit = 100, bool convertAttachments = true, CancelToken? cancelToken}) async {
    List<String> guids = [];
    if (where.isNotEmpty && where.first is Map && where.first['args'] != null) {
      guids = List<String>.from(where.first['args']['guids'] ?? []);
    }
    final data = guids.map((g) => messagesMap[g]).where((m) => m != null).toList();
    return Response(data: {'data': data}, statusCode: 200, requestOptions: RequestOptions(path: 'messages'));
  }

  @override
  Future<Response> singleChat(String guid, {String withQuery = "", CancelToken? cancelToken}) async {
    return Response(data: {'data': chatsMap[guid]}, statusCode: 200, requestOptions: RequestOptions(path: 'chat'));
  }

  @override
  Future<Response> attachment(String guid, {CancelToken? cancelToken}) async {
    return Response(data: {'data': attachmentsMap[guid]}, statusCode: 200, requestOptions: RequestOptions(path: 'attachment'));
  }

  @override
  Future<Response> handle(String guid, {CancelToken? cancelToken}) async {
    return Response(data: {'data': handlesMap[guid]}, statusCode: 200, requestOptions: RequestOptions(path: 'handle'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GUID-only payloads are enriched into full entities', () async {
    http = MockHttpService(
      messagesMap: {'msg-1': {'guid': 'msg-1', 'text': 'Hello'}},
      chatsMap: {'chat-1': {'guid': 'chat-1', 'title': 'Test Chat'}},
      attachmentsMap: {'att-1': {'guid': 'att-1', 'filename': 'file.txt'}},
      handlesMap: {'+1234567890': {'address': '+1234567890', 'id': 1}},
    );

    // Message enrichment
    final msgPayload = ApiPayload(payload: {'data': ['msg-1']}, type: PayloadType.MESSAGE);
    final msgParser = ApiPayloadParser(msgPayload);
    await msgParser.parse();
    expect(msgPayload.data[0]['text'], 'Hello');

    // Chat enrichment
    final chatPayload = ApiPayload(payload: {'data': ['chat-1']}, type: PayloadType.CHAT);
    final chatParser = ApiPayloadParser(chatPayload);
    await chatParser.parse();
    expect(chatPayload.data[0]['title'], 'Test Chat');

    // Attachment enrichment
    final attPayload = ApiPayload(payload: {'data': ['att-1']}, type: PayloadType.ATTACHMENT);
    final attParser = ApiPayloadParser(attPayload);
    await attParser.parse();
    expect(attPayload.data[0]['filename'], 'file.txt');

    // Handle enrichment
    final handlePayload = ApiPayload(payload: {'data': ['+1234567890']}, type: PayloadType.HANDLE);
    final handleParser = ApiPayloadParser(handlePayload);
    await handleParser.parse();
    expect(handlePayload.data[0]['id'], 1);
  });
}

