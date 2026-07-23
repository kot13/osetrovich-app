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
  testWidgets('catalog notifications route pops back to catalog root', (
    tester,
  ) async {
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

    await tester.tap(find.text(AppStrings.tabCatalog));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.notificationsTitle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Рыба'), findsOneWidget);
    expect(find.text(AppStrings.tabCatalog), findsWidgets);
  });
}
