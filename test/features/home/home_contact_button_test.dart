import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/home/presentation/home_contact_button.dart';

void main() {
  testWidgets('home contact button shows label and phone icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: HomeContactButton()),
      ),
    );

    expect(find.text(AppStrings.contactUs), findsOneWidget);
    expect(find.byIcon(Icons.phone), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });
}
