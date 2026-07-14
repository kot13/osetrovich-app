import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/bootstrap/app_bootstrap.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/router/app_router.dart';
import 'package:osetrovich/core/theme/app_theme.dart';

Widget _buildTestApp(WidgetRef ref) {
  final router = ref.watch(routerProvider);
  return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
}

class _TestAppHost extends ConsumerWidget {
  const _TestAppHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBootstrapProvider);
    return _buildTestApp(ref);
  }
}

void main() {
  testWidgets('main shell shows five tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          appBootstrapProvider.overrideWith((ref) async {}),
        ],
        child: const _TestAppHost(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tabHome), findsWidgets);
    expect(find.text(AppStrings.tabCatalog), findsWidgets);
    expect(find.text(AppStrings.tabPromotions), findsWidgets);
    expect(find.text(AppStrings.tabCart), findsWidgets);
    expect(find.text(AppStrings.tabProfile), findsWidgets);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('switching tabs changes visible screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          appBootstrapProvider.overrideWith((ref) async {}),
        ],
        child: const _TestAppHost(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.tabCart));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.cartEmpty), findsOneWidget);
  });
}
