import 'package:test/test.dart';
import 'package:bluebubbles/app/components/voice/voice_recorder.dart';
import 'package:bluebubbles/database/html/chat.dart';
import 'package:bluebubbles/database/html/message.dart';

void main() {
  test('transcribed text saved with message', () async {
    VoiceRecorder.startTranscription = (onResult) async {
      onResult('hello world');
    };
    VoiceRecorder.stopTranscription = () async => 'hello world';
    String? interim;
    await VoiceRecorder.startTranscription((res) => interim = res);
    final transcript = await VoiceRecorder.stopTranscription();
    final message = Message(guid: 'temp-guid', dateCreated: DateTime.now(), audioTranscript: transcript);
    final chat = Chat(guid: 'chat-guid');
    await chat.addMessage(message, checkForMessageText: false, changeUnreadStatus: false);
    expect(interim, 'hello world');
    expect(message.audioTranscript, 'hello world');
  });
}
