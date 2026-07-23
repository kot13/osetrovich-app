import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:osetrovich/app.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('notifications flow from home with authenticated session', (
    tester,
  ) async {
    final mockClient = MockApiClient();
    await mockClient.verifySmsCode('+79001234567', MockApiClient.validCode);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockClient),
          authSessionProvider.overrideWith(
            () => _FakeAuthSessionNotifier(
              AuthSession(
                accessToken: 'mock.access.token.+79001234567',
                refreshToken: 'r',
                expiresAt: AuthSession.neverExpiresAt,
                phone: '+79001234567',
              ),
            ),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.notificationsTitle), findsOneWidget);
    expect(find.text('Заказ принят'), findsOneWidget);

    await tester.tap(find.text('Заказ принят'));
    await tester.pumpAndSettle();

    expect(find.text('Ваш заказ принят в обработку.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(mockClient.registeredPushToken, isNotNull);
  });

  testWidgets('notifications flow from promotions keeps promotions tab', (
    tester,
  ) async {
    final mockClient = MockApiClient();
    await mockClient.verifySmsCode('+79001234567', MockApiClient.validCode);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockClient),
          authSessionProvider.overrideWith(
            () => _FakeAuthSessionNotifier(
              AuthSession(
                accessToken: 'mock.access.token.+79001234567',
                refreshToken: 'r',
                expiresAt: AuthSession.neverExpiresAt,
                phone: '+79001234567',
              ),
            ),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text(AppStrings.tabPromotions));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.notificationsTitle), findsOneWidget);
    expect(find.text(AppStrings.tabPromotions), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.chipAll), findsOneWidget);
    expect(find.text(AppStrings.tabPromotions), findsWidgets);
  });
}
