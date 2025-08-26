import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:bluebubbles/app/layouts/conversation_view/widgets/text_field/conversation_text_field.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/ui/chat/conversation_view_controller.dart';

class FakeSettingsService extends SettingsService {
  FakeSettingsService() {
    settings = Settings();
  }
}

class TestConversationTextFieldState extends ConversationTextFieldState {
  TestConversationTextFieldState(this._controller);
  final ConversationViewController _controller;

  @override
  ConversationViewController get controller => _controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    ss = FakeSettingsService();
    ss.settings.spellcheck.value = false;
  });

  test('getTextDraft loads chat text draft', () {
    final chat = Chat(guid: 'test-guid');
    chat.textFieldText = 'hello world';
    final controller = ConversationViewController(chat);
    final state = TestConversationTextFieldState(controller);

    state.getTextDraft();
    expect(controller.textController.text, 'hello world');
  });

  test('getTextDraft prioritizes provided text', () {
    final chat = Chat(guid: 'test-guid');
    chat.textFieldText = 'chat text';
    final controller = ConversationViewController(chat);
    final state = TestConversationTextFieldState(controller);

    state.getTextDraft(text: 'param text');
    expect(controller.textController.text, 'param text');
  });
}

