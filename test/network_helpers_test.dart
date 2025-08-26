import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/helpers/network/network_helpers.dart';

void main() {
  group('sanitizeServerAddress', () {
    test('adds http prefix for plain host', () {
      final result = sanitizeServerAddress(address: 'example.com');
      expect(result, 'http://example.com');
    });

    test('adds https prefix for ngrok host', () {
      final result = sanitizeServerAddress(address: 'my-ngrok.ngrok.io');
      expect(result, 'https://my-ngrok.ngrok.io');
    });

    test('adds https prefix for zrok host', () {
      final result = sanitizeServerAddress(address: 'my-zrok.zrok.io');
      expect(result, 'https://my-zrok.zrok.io');
    });
  });
}
