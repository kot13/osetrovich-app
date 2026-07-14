import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/catalog/domain/categories_provider.dart';
import 'package:osetrovich/features/catalog/presentation/catalog_screen.dart';

class _SemiFinishedCategoryNotifier extends SelectedCategoryNotifier {
  @override
  String build() => 'semi_finished';
}

void main() {
  testWidgets('catalog shows chips and product grid', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(theme: AppTheme.light, home: const CatalogScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Рыба'), findsOneWidget);
    expect(find.text('Все'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text(AppStrings.nothingFound), findsNothing);
  });

  testWidgets('catalog shows empty state for category without products', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          selectedCategoryIdProvider.overrideWith(
            _SemiFinishedCategoryNotifier.new,
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const CatalogScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(AppStrings.nothingFound), findsOneWidget);
  });
}
