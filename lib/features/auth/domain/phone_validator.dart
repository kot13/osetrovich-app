final phoneE164Pattern = RegExp(r'^\+7\d{10}$');

bool isValidRussianPhone(String phone) => phoneE164Pattern.hasMatch(phone);

String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

String toE164RussianPhone(String digits) {
  final normalized = digitsOnly(digits);
  if (normalized.length == 11 && normalized.startsWith('7')) {
    return '+$normalized';
  }
  if (normalized.length == 10) {
    return '+7$normalized';
  }
  return '+$normalized';
}
