import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/helpers/network/network_helpers.dart';

void main() {
  group('sanitizeServerAddress', () {
    test('defaults to https for plain host', () {
      final result = sanitizeServerAddress(address: 'example.com');
      expect(result, 'https://example.com');
    });

    test('retains http when explicitly provided', () {
      final result = sanitizeServerAddress(address: 'http://example.com');
      expect(result, 'http://example.com');
    });

    test('uses https for ngrok host', () {
      final result = sanitizeServerAddress(address: 'my-ngrok.ngrok.io');
      expect(result, 'https://my-ngrok.ngrok.io');
    });

    test('uses https for zrok host', () {
      final result = sanitizeServerAddress(address: 'my-zrok.zrok.io');
      expect(result, 'https://my-zrok.zrok.io');
    });
  });
}
