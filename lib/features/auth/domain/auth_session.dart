class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.phone,
  });

  static final neverExpiresAt = DateTime.utc(9999, 12, 31);

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String phone;

  bool get isExpired => false;
}
