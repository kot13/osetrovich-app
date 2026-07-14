import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/profile/domain/email_validator.dart';

void main() {
  test('valid email passes', () {
    expect(isValidEmail('user@example.com'), isTrue);
  });

  test('invalid email fails', () {
    expect(isValidEmail('not-an-email'), isFalse);
    expect(isValidEmail(''), isFalse);
  });
}
