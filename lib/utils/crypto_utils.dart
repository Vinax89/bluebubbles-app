import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:tuple/tuple.dart';

String encryptAES(String plainText, String passphrase) {
  try {
    final salt = genRandomWithNonZero(16);
    var keyndIV = deriveKeyAndIV(passphrase, salt);
    final key = keyndIV.item1;
    final iv = keyndIV.item2.sublist(0, 12);

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    final encrypted = cipher.process(Uint8List.fromList(utf8.encode(plainText)));
    Uint8List encryptedBytesWithSalt =
        Uint8List.fromList(createUint8ListFromString("Salted__") + salt + encrypted);
    return base64.encode(encryptedBytesWithSalt);
  } catch (error) {
    rethrow;
  }
}

String decryptAES(String encrypted, String passphrase) {
  try {
    Uint8List encryptedBytesWithSalt = base64.decode(encrypted);

    Uint8List encryptedBytes = encryptedBytesWithSalt.sublist(24, encryptedBytesWithSalt.length);
    final salt = encryptedBytesWithSalt.sublist(8, 24);
    var keyndIV = deriveKeyAndIV(passphrase, salt);
    final key = keyndIV.item1;
    final iv = keyndIV.item2.sublist(0, 12);

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    final decrypted = cipher.process(encryptedBytes);
    return utf8.decode(decrypted);
  } catch (error) {
    rethrow;
  }
}

Tuple2<Uint8List, Uint8List> deriveKeyAndIV(String passphrase, Uint8List salt) {
  final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  final params = Pbkdf2Parameters(salt, 100000, 48);
  derivator.init(params);
  final key = derivator.process(Uint8List.fromList(utf8.encode(passphrase)));
  var keyBytes = key.sublist(0, 32);
  var ivBytes = key.sublist(32, 48);
  return Tuple2(keyBytes, ivBytes);
}

Uint8List createUint8ListFromString(String s) {
  var ret = Uint8List(s.length);
  for (var i = 0; i < s.length; i++) {
    ret[i] = s.codeUnitAt(i);
  }
  return ret;
}

Uint8List genRandomWithNonZero(int seedLength) {
  final random = Random.secure();
  const int randomMax = 245;
  final Uint8List uint8list = Uint8List(seedLength);
  for (int i = 0; i < seedLength; i++) {
    uint8list[i] = random.nextInt(randomMax) + 1;
  }
  return uint8list;
}
