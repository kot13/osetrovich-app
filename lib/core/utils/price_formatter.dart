/// Formats price in whole rubles with non-breaking space before ₽.
String formatPriceRub(int priceRub) {
  return '$priceRub\u00A0₽';
}

/// Formats price per kilogram, e.g. «2 400 ₽/кг».
String formatPricePerKgRub(int pricePerKgRub) {
  return '${formatPriceRub(pricePerKgRub)}/кг';
}

/// Formats price with weight context, e.g. «2 178 ₽ за 2 кг».
String formatPriceForWeightLabel(int priceRub, String weightLabel) {
  return '${formatPriceRub(priceRub)} за $weightLabel';
}
