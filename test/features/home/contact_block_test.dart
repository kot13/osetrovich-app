import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/contact_block.dart';

void main() {
  testWidgets('contact block shows phone icon and label', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: ContactBlock())),
      ),
    );

    expect(find.byIcon(Icons.phone), findsOneWidget);
    expect(find.text(AppStrings.contactUs), findsOneWidget);
  });
}
