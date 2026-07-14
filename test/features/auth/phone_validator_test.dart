import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/auth/domain/phone_validator.dart';

void main() {
  group('phone_validator', () {
    test('valid +7 phone', () {
      expect(isValidRussianPhone('+79161234567'), isTrue);
    });

    test('invalid short phone', () {
      expect(isValidRussianPhone('+7916123'), isFalse);
    });

    test('toE164 from 10 digits', () {
      expect(toE164RussianPhone('9161234567'), '+79161234567');
    });
  });
}
