import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/helpers/types/helpers/contact_helpers.dart';

void main() {
  test('getUniqueNumbers deduplicates formatted and unformatted numbers', () {
    final numbers = [
      '555-1234',
      '5551234',
      '(555) 1234',
      '(555) 5678',
      '5555678',
      '555-9012',
    ];

    final result = getUniqueNumbers(numbers);

    expect(result, ['555-1234', '(555) 5678', '555-9012']);
  });
}
