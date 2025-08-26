import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/global/settings.dart';
import 'package:bluebubbles/database/io/chat.dart';
import 'package:bluebubbles/database/io/message.dart';
import 'package:bluebubbles/database/io/attachment.dart';
import 'package:bluebubbles/database/io/handle.dart';
import 'package:bluebubbles/database/io/contact.dart';
import 'package:bluebubbles/objectbox.g.dart';
import 'package:bluebubbles/services/backup_service.dart';
import 'package:bluebubbles/services/backend/filesystem/filesystem_service.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';

void main() {
  late Directory tempDir;
  late Store store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_test');
    store = await openStore(directory: join(tempDir.path, 'ob'));
    Database.store = store;
    Database.attachments = store.box<Attachment>();
    Database.chats = store.box<Chat>();
    Database.contacts = store.box<Contact>();
    Database.handles = store.box<Handle>();
    Database.messages = store.box<Message>();

    fs = FilesystemService();
    fs.appDocDir = tempDir;

    SharedPreferences.setMockInitialValues({});
    ss = SettingsService();
    ss.prefs = await SharedPreferences.getInstance();
    ss.settings = Settings();
  });

  tearDown(() {
    store.close();
    tempDir.deleteSync(recursive: true);
  });

  test('create and restore backup', () async {
    final chat = Chat(guid: 'c1');
    Database.chats.put(chat);
    ss.settings.userName.value = 'Tester';
    await ss.settings.saveAsync();

    final backup = await BackupService.createEncryptedBackup(password: 'pass');

    Database.chats.removeAll();
    await ss.prefs.clear();

    await BackupService.restoreEncryptedBackup(backup, password: 'pass');

    expect(Database.chats.count(), 1);
    expect(ss.settings.userName.value, 'Tester');
  });
}

