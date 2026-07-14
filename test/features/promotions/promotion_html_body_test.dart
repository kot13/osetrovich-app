import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/promotions/presentation/widgets/promotion_html_body.dart';

void main() {
  testWidgets('promotion html body renders strong text and emoji', (
    tester,
  ) async {
    const html =
        '<p>Текст <strong>жирный</strong> 🎉</p><ul><li>Пункт</li></ul>';

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PromotionHtmlBody(html: html))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('жирный'), findsOneWidget);
    expect(find.textContaining('🎉'), findsOneWidget);
    expect(find.text('Пункт'), findsOneWidget);
  });

  testWidgets('promotion html body does not render script content', (
    tester,
  ) async {
    const html =
        '<p>Безопасный текст</p><script>alert("xss")</script><p>После</p>';

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PromotionHtmlBody(html: html))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Безопасный'), findsOneWidget);
    expect(find.textContaining('После'), findsOneWidget);
    expect(find.textContaining('alert'), findsNothing);
    expect(find.textContaining('xss'), findsNothing);
  });
}
