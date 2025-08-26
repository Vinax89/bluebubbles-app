import 'package:bluebubbles/helpers/types/helpers/contact_helpers.dart';
import 'package:bluebubbles/database/html/message.dart';
import 'package:test/test.dart';

void main() {
  test('formatPhoneNumber returns original on parse failure', () async {
    final result = await formatPhoneNumber('not-a-number');
    expect(result, 'not-a-number');
  });

  test('Message.fromMap handles invalid metadata', () {
    final message = Message.fromMap({
      'guid': '123',
      'attachments': [],
      'metadata': '{invalid',
      'messageSummaryInfo': [],
      'attributedBody': [],
    });
    expect(message.metadata, isA<Map<String, dynamic>>());
    expect(message.metadata!.isEmpty, isTrue);
  });
}
