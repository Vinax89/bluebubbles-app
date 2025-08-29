import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/utils/crypto_utils.dart';

void main() {
  test('encryptAES and decryptAES round trip', () {
    const message = 'secret message';
    const passphrase = 'pass123';
    final encrypted = encryptAES(message, passphrase);
    final decrypted = decryptAES(encrypted, passphrase);
    expect(decrypted, equals(message));
  });

  test('decryptAES throws on invalid base64 input', () {
    expect(() => decryptAES('not-base64', 'pass'), throwsA(isA<FormatException>()));
  });

  test('decryptAES throws on wrong passphrase', () {
    const message = 'another secret';
    const goodPass = 'good';
    const badPass = 'bad';
    final encrypted = encryptAES(message, goodPass);
    expect(() => decryptAES(encrypted, badPass), throwsA(isA<Exception>()));
  });
}
