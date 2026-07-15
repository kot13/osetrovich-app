/// Внутренний ID пользователя для AppMetrica (без PII).
/// Согласован с `MockApiClient._userIdForPhone` для мок-фазы.
String? analyticsUserIdFromPhone(String phone) {
  final normalized = phone.trim();
  if (normalized.isEmpty) {
    return null;
  }
  return 'u-${normalized.replaceAll(RegExp(r'\D'), '')}';
}
