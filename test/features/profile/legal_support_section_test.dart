import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/profile/presentation/widgets/legal_support_section.dart';

void main() {
  testWidgets('legal support section shows contact and privacy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LegalSupportSection())),
    );

    expect(find.text(AppStrings.contactUs), findsOneWidget);
    expect(find.text(AppStrings.privacyPolicy), findsOneWidget);
  });
}
