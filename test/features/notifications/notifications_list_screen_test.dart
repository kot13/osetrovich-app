import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/notifications/presentation/notifications_list_screen.dart';

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}

void main() {
  testWidgets('notifications list shows items and mark-all button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
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
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationsListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Заказ принят'), findsOneWidget);
    expect(find.text(AppStrings.markAllRead), findsOneWidget);
  });

  testWidgets('mark all read hides floating button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
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
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationsListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.markAllRead));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.markAllRead), findsNothing);
  });
}
