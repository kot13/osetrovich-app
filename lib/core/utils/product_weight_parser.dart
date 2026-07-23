/// Parses product weight in kilograms from labels like «500 г», «0.5 кг», «1 кг».
double? parseProductWeightKg(String weightLabel) {
  final normalized = weightLabel.trim().toLowerCase().replaceAll(',', '.');

  final kgMatch = RegExp(r'([\d.]+)\s*кг').firstMatch(normalized);
  if (kgMatch != null) {
    return double.tryParse(kgMatch.group(1)!);
  }

  final gMatch = RegExp(r'([\d.]+)\s*г').firstMatch(normalized);
  if (gMatch != null) {
    final grams = double.tryParse(gMatch.group(1)!);
    return grams == null ? null : grams / 1000;
  }

  return null;
}
