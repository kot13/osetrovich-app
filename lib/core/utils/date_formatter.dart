const _russianMonthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

/// Форматирует дату публикации: «14 июля 2026».
String formatPublishedDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  final month = _russianMonthsGenitive[local.month - 1];
  return '${local.day} $month ${local.year}';
}
