import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart';

import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/global/settings.dart';
import 'package:bluebubbles/services/service_locator.dart';

/// Supported cloud storage providers for backups.
enum CloudProvider { googleDrive, iCloud }

/// Service responsible for creating, encrypting and uploading backups of the
/// application's database and settings.
class BackupService {
  static const String _dbFile = 'database.json';
  static const String _settingsFile = 'settings.json';
  static const String _archiveName = 'bluebubbles_backup.bb';

  /// Creates an encrypted backup archive and returns the resulting file.
  static Future<File> createEncryptedBackup({required String password}) async {
    final dbData = await Database.exportData();
    final settingsJson = ss.settings.toJson(includeAll: true);

    final archive = Archive()
      ..addFile(ArchiveFile(_dbFile, utf8.encode(jsonEncode(dbData)).length,
          utf8.encode(jsonEncode(dbData))))
      ..addFile(ArchiveFile(
          _settingsFile, utf8.encode(settingsJson).length, utf8.encode(settingsJson)));

    final bytes = ZipEncoder().encode(archive)!;
    final key = Key(Uint8List.fromList(sha256.convert(utf8.encode(password)).bytes));
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encryptBytes(bytes, iv: IV.fromLength(16));

    final file = File(join(fs.appDocDir.path, _archiveName));
    await file.writeAsBytes(encrypted.bytes, flush: true);
    return file;
  }

  /// Restores an encrypted backup previously created by
  /// [createEncryptedBackup].
  static Future<void> restoreEncryptedBackup(File archive,
      {required String password}) async {
    final key = Key(Uint8List.fromList(sha256.convert(utf8.encode(password)).bytes));
    final encrypter = Encrypter(AES(key));
    final decrypted =
        encrypter.decryptBytes(Encrypted(await archive.readAsBytes()), iv: IV.fromLength(16));
    final data = ZipDecoder().decodeBytes(decrypted);

    Map<String, dynamic>? dbMap;
    Map<String, dynamic>? settingsMap;
    for (final file in data) {
      if (file.isFile) {
        final content = utf8.decode(file.content);
        if (file.name == _dbFile) {
          dbMap = jsonDecode(content);
        } else if (file.name == _settingsFile) {
          settingsMap = jsonDecode(content);
        }
      }
    }

    if (dbMap != null) {
      await Database.importData(dbMap);
    }
    if (settingsMap != null) {
      ss.settings = Settings.fromMap(settingsMap);
      await ss.settings.saveAsync();
    }
  }

  /// Uploads [file] to the chosen cloud [provider].  This implementation stores
  /// the file in a provider-named folder within the application directory as a
  /// stand-in for real cloud functionality.
  static Future<void> uploadBackup(File file, CloudProvider provider) async {
    final dir = Directory(join(fs.appDocDir.path, 'cloud', provider.name));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    await file.copy(join(dir.path, basename(file.path)));
  }

  static Timer? _timer;

  /// Enables periodic backups on the specified [interval].  If [provider] is
  /// supplied the backup is uploaded after creation.
  static void schedulePeriodicBackups(Duration interval,
      {required String password, CloudProvider? provider}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      final file = await createEncryptedBackup(password: password);
      if (provider != null) {
        await uploadBackup(file, provider);
      }
    });
  }

  /// Cancels any running periodic backup task.
  static void cancelPeriodicBackups() {
    _timer?.cancel();
    _timer = null;
  }
}

