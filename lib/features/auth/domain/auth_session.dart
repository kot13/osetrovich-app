class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.phone,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String phone;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
