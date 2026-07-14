import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/catalog/presentation/catalog_screen.dart';

void main() {
  testWidgets('catalog shows chips and empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CatalogScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Рыба'), findsOneWidget);
    expect(find.text('Все'), findsOneWidget);
    expect(find.text(AppStrings.nothingFound), findsOneWidget);
  });
}
