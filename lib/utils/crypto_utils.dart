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
  return Uint8List.fromList(s.codeUnits);
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

SecureRandom _secureRandom() {
  final secureRandom = FortunaRandom();
  final seedSource = Random.secure();
  final seeds = List<int>.generate(32, (_) => seedSource.nextInt(255));
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
  return secureRandom;
}

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAKeyPair({int bitLength = 2048}) {
  final generator = RSAKeyGenerator()
    ..init(ParametersWithRandom(RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64), _secureRandom()));
  final pair = generator.generateKeyPair();
  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(pair.publicKey as RSAPublicKey, pair.privateKey as RSAPrivateKey);
}

Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
  final blockSize = engine.inputBlockSize;
  final output = BytesBuilder();
  for (int offset = 0; offset < input.length; offset += blockSize) {
    final end = min(offset + blockSize, input.length);
    output.add(engine.process(input.sublist(offset, end)));
  }
  return output.toBytes();
}

String rsaEncrypt(String plaintext, RSAPublicKey publicKey) {
  final engine = OAEPEncoding(RSAEngine())..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  final encrypted = _processInBlocks(engine, Uint8List.fromList(utf8.encode(plaintext)));
  return base64.encode(encrypted);
}

String rsaDecrypt(String ciphertext, RSAPrivateKey privateKey) {
  final engine = OAEPEncoding(RSAEngine())..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  final decrypted = _processInBlocks(engine, base64.decode(ciphertext));
  return utf8.decode(decrypted);
}

Tuple2<DHPublicKey, DHPrivateKey> generateDHKeyPair({int bitLength = 2048}) {
  final paramsGen = DHParametersGenerator()..init(bitLength, 20, _secureRandom());
  final params = paramsGen.generateParameters();
  final keyGen = DHKeyGenerator()
    ..init(ParametersWithRandom(DHKeyGeneratorParameters(params.p, params.g, params.l), _secureRandom()));
  final pair = keyGen.generateKeyPair();
  return Tuple2<DHPublicKey, DHPrivateKey>(pair.publicKey as DHPublicKey, pair.privateKey as DHPrivateKey);
}

Uint8List deriveDHSharedSecret(DHPrivateKey privateKey, DHPublicKey publicKey) {
  final agreement = DHBasicAgreement()..init(privateKey);
  final secret = agreement.calculateAgreement(publicKey);
  return Uint8List.fromList(secret.toRadixString(16).codeUnits);
}

String encryptWithSessionKey(String plainText, String sessionKey) => encryptAES(plainText, sessionKey);

String decryptWithSessionKey(String encrypted, String sessionKey) => decryptAES(encrypted, sessionKey);
