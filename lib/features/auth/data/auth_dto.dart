class SmsRequestResponse {
  const SmsRequestResponse({required this.retryAfterSeconds});

  factory SmsRequestResponse.fromJson(Map<String, dynamic> json) {
    return SmsRequestResponse(
      retryAfterSeconds: json['retryAfterSeconds'] as int,
    );
  }

  final int retryAfterSeconds;
}

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      tokenType: json['token_type'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
}
