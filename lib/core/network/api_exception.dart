class ApiException implements Exception {
  ApiException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'ApiException($code): $message';
}
