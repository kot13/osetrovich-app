import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/home/presentation/home_weekly_products_section.dart';

void main() {
  testWidgets('shows weekly products title and cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: HomeWeeklyProductsSection()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(AppStrings.homeWeeklyProductsTitle), findsOneWidget);
    expect(find.textContaining('₽'), findsWidgets);
  });

  testWidgets('add to cart updates badge provider', (tester) async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: HomeWeeklyProductsSection()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final addButtons = find.textContaining('₽ +');
    expect(addButtons, findsWidgets);

    await tester.tap(addButtons.first);
    await tester.pump();

    expect(container.read(cartDistinctCountProvider), 1);
  });
}
