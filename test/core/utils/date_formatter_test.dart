import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/utils/date_formatter.dart';

void main() {
  test('formatPublishedDate formats Russian date without time', () {
    final date = DateTime.utc(2026, 7, 14, 9, 30);
    expect(formatPublishedDate(date), '14 июля 2026');
  });

  test('formatPublishedDate uses genitive month names', () {
    final date = DateTime.utc(2026, 1, 5);
    expect(formatPublishedDate(date), '5 января 2026');
  });
}
