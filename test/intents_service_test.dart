import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:receive_intent/receive_intent.dart';
import 'package:file_picker/file_picker.dart';

import 'package:bluebubbles/services/backend/java_dart_interop/intents_service.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/services/ui/navigator/navigator_service.dart';

class MockNavigatorService extends NavigatorService {
  bool pushed = false;

  @override
  Future<void> pushAndRemoveUntil(
    BuildContext context,
    Widget widget,
    bool Function(Route) predicate, {
    bool closeActiveChat = true,
    PageRoute? customRoute,
  }) async {
    pushed = true;
  }
}

class TestIntentsService extends IntentsService {
  bool openChatCalled = false;
  String? lastGuid;
  String? lastText;
  List<PlatformFile> lastAttachments = [];
  bool answered = false;

  @override
  Future<void> openChat(String? guid, {String? text, List<PlatformFile> attachments = const []}) async {
    openChatCalled = true;
    lastGuid = guid;
    lastText = text;
    lastAttachments = attachments;
  }

  @override
  Future<void> answerFaceTime(String callUuid) async {
    answered = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    if (!StartupTasks.uiReady.isCompleted) {
      StartupTasks.uiReady.complete();
    }
  });

  test('handle SEND intent calls openChat', () async {
    final service = TestIntentsService();
    final intent = Intent(action: 'android.intent.action.SEND', extra: {
      'android.intent.extra.shortcut.ID': 'guid1',
      'android.intent.extra.TEXT': 'hello',
    });
    await service.handleIntent(intent);
    expect(service.openChatCalled, isTrue);
    expect(service.lastGuid, 'guid1');
    expect(service.lastText, 'hello');
    expect(service.lastAttachments, isEmpty);
  });

  testWidgets('handle imessage url pushes chat creator', (tester) async {
    final mockNs = MockNavigatorService();
    ns = mockNs;
    await tester.pumpWidget(GetMaterialApp(home: Container()));
    final service = TestIntentsService();
    final intent = Intent(action: 'VIEW', data: 'imessage://1234567890&body=hi');
    await service.handleIntent(intent);
    expect(mockNs.pushed, isTrue);
  });

  test('handle chatGuid opens chat and sets bubble', () async {
    ls.isBubble = false;
    final service = TestIntentsService();
    final intent = Intent(action: 'ACTION', extra: {'chatGuid': 'chat-1', 'bubble': true});
    await service.handleIntent(intent);
    expect(service.openChatCalled, isTrue);
    expect(service.lastGuid, 'chat-1');
    expect(ls.isBubble, isTrue);
  });

  test('handle FaceTime intent answers call', () async {
    final service = TestIntentsService();
    final intent = Intent(action: 'ACTION', extra: {'callUuid': 'abc', 'answer': true});
    await service.handleIntent(intent);
    expect(service.answered, isTrue);
  });
}

