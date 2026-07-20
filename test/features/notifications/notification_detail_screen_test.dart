import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/notifications/presentation/notification_detail_screen.dart';

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}

ProviderScope _scoped(Widget child) {
  return ProviderScope(
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
    child: child,
  );
}

void main() {
  testWidgets('detail screen shows title body and time', (tester) async {
    await tester.pumpWidget(
      _scoped(
        MaterialApp(
          theme: AppTheme.light,
          home: const NotificationDetailScreen(notificationId: '1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Заказ принят'), findsOneWidget);
    expect(find.text('Ваш заказ принят в обработку.'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
  });

  testWidgets('delivered notification shows rate order CTA', (tester) async {
    await tester.pumpWidget(
      _scoped(
        MaterialApp(
          theme: AppTheme.light,
          home: const NotificationDetailScreen(notificationId: '4'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Заказ доставлен'), findsOneWidget);
    expect(find.text('Оценить заказ'), findsOneWidget);
  });

  testWidgets('multiline body preserves line breaks', (tester) async {
    await tester.pumpWidget(
      _scoped(
        MaterialApp(
          theme: AppTheme.light,
          home: const NotificationDetailScreen(notificationId: '2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Сёмга холодного курения'), findsOneWidget);
    expect(find.textContaining('Итого: 1 190 ₽'), findsOneWidget);
  });
}
