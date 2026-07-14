import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';

void main() {
  test('session never expires', () {
    final session = AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      expiresAt: AuthSession.neverExpiresAt,
      phone: '+79001234567',
    );

    expect(session.isExpired, isFalse);
  });
}
