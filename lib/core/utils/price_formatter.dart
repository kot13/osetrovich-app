/// Formats price in whole rubles with non-breaking space before ₽.
String formatPriceRub(int priceRub) {
  return '$priceRub\u00A0₽';
}
