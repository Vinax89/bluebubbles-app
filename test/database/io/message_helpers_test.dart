import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/io/attachment.dart';
import 'package:bluebubbles/database/io/chat.dart';
import 'package:bluebubbles/database/io/handle.dart';
import 'package:bluebubbles/database/io/message.dart';
import 'package:bluebubbles/objectbox.g.dart';

void main() {
  late Directory tempDir;
  late Store store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('message_helper_test');
    store = await openStore(directory: tempDir.path);
    Database.store = store;
    Database.attachments = store.box<Attachment>();
    Database.messages = store.box<Message>();
    Database.handles = store.box<Handle>();
  });

  tearDown(() {
    store.close();
    tempDir.deleteSync(recursive: true);
  });

  test('prepareAttachments saves and maps attachments', () {
    final helper = BulkSaveNewMessages([]);
    final msg1 = Message(guid: 'm1', attachments: [Attachment(guid: 'a1'), Attachment(guid: 'a2')]);
    final msg2 = Message(guid: 'm2', attachments: [Attachment(guid: 'a1')]);
    final messages = [msg1, msg2];

    final messageAttachments = <String, List<String>>{};
    final attachmentMap = helper.prepareAttachmentsForTesting(messages, messageAttachments);

    expect(Database.attachments.count(), 2);
    expect(messageAttachments['m1'], ['a1', 'a2']);
    expect(messageAttachments['m2'], ['a1']);
    expect(attachmentMap.keys.toSet(), {'a1', 'a2'});
  });

  test('mapHandles assigns chat and handle', () {
    final helper = BulkSaveNewMessages([]);
    final chat = Chat(guid: 'chat');
    final handle = Handle(id: 1, originalROWID: 5);
    Database.handles.put(handle);
    final msg = Message(guid: 'm', handleId: 5);

    helper.mapHandlesForTesting([msg], chat, [handle]);

    expect(msg.chat.target, chat);
    expect(msg.handle, handle);
  });

  test('persistMessages stores new messages with attachments', () {
    final helper = BulkSaveNewMessages([]);
    final existing = Message(guid: 'e1');
    Database.messages.put(existing);

    final attachment1 = Attachment(guid: 'a1');
    final attachment2 = Attachment(guid: 'a2');
    Database.attachments.putMany([attachment1, attachment2]);

    final msg1 = Message(guid: 'm1');
    final msg2 = Message(guid: 'm2');
    final inputMessages = [Message(guid: 'e1'), msg1, msg2];
    final inputGuids = ['e1', 'm1', 'm2'];
    final messageAttachments = {
      'm1': ['a1'],
      'm2': ['a2']
    };
    final attachmentMap = {'a1': attachment1, 'a2': attachment2};

    final result = helper.persistMessagesForTesting(
        inputMessages, inputGuids, messageAttachments, attachmentMap);

    expect(Database.messages.count(), 3);
    expect(result.length, 3);
    final fetchedM1 = result.firstWhere((m) => m.guid == 'm1');
    expect(fetchedM1.attachments.single.guid, 'a1');
  });

  test('updateReactions sets hasReactions on associated message', () {
    final helper = BulkSaveNewMessages([]);
    final handle = Handle(id: 1, originalROWID: 5);
    Database.handles.put(handle);

    final original = Message(guid: 'm1', handleId: 5);
    final reaction = Message(guid: 'm2', handleId: 5, associatedMessageGuid: 'm1');
    Database.messages.putMany([original, reaction]);

    helper.updateReactionsForTesting([reaction], [handle]);

    final updated = Database.messages.query(Message_.guid.equals('m1')).build().findFirst()!;
    expect(updated.hasReactions, isTrue);
    expect(reaction.handle, handle);
  });
}
