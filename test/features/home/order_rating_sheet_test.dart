import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/home/presentation/order_rating_sheet.dart';

void main() {
  testWidgets('submit disabled until star selected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: OrderRatingSheet(onSubmit: (_, __) {}),
        ),
      ),
    );

    final submitButton = find.widgetWithText(FilledButton, AppStrings.homeOrderRatingSubmit);
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNull);

    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pump();

    expect(tester.widget<FilledButton>(submitButton).onPressed, isNotNull);
  });

  testWidgets('submit calls callback with stars and comment', (tester) async {
    int? submittedStars;
    String? submittedComment;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: OrderRatingSheet(
            onSubmit: (stars, comment) {
              submittedStars = stars;
              submittedComment = comment;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.star_border).at(4));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Хорошо');
    await tester.tap(find.text(AppStrings.homeOrderRatingSubmit));
    await tester.pump();

    expect(submittedStars, 5);
    expect(submittedComment, 'Хорошо');
  });
}
