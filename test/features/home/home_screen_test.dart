import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/data/order_repository.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/home/presentation/auth_prompt_banner.dart';
import 'package:osetrovich/features/home/presentation/home_screen.dart';
import 'package:osetrovich/features/notifications/domain/unread_count_notifier.dart';

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}

void main() {
  testWidgets('home shows notifications badge contact weekly and auth prompt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          unreadCountProvider.overrideWith((ref) => 3),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text(AppStrings.contactUs), findsOneWidget);
    expect(find.text(AppStrings.homeWeeklyProductsTitle), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsWidgets);
    expect(find.byType(AuthPromptBanner), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('home shows order block when authenticated with order', (
    tester,
  ) async {
    final order = CurrentOrder(
      id: 'ord-demo',
      orderNumber: 'ORD-DEMO',
      items: const [
        OrderLine(
          id: 1000,
          name: 'Сёмга',
          weightLabel: '500 г',
          priceRub: 890,
          quantity: 1,
          lineTotalRub: 890,
        ),
      ],
      itemsSubtotalRub: 890,
      deliveryFeeRub: 300,
      totalRub: 1190,
      deliveryAddress: 'СПб',
      status: OrderStatus.delivery,
      createdAt: DateTime.utc(2026, 7, 15),
      ratingState: OrderRatingState.notApplicable,
    );

    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          authSessionProvider.overrideWith(
            () => _FakeAuthSessionNotifier(
              AuthSession(
                accessToken: 'mock.access.token.+79001111111',
                refreshToken: 'r',
                expiresAt: DateTime.utc(2099),
                phone: '+79001111111',
              ),
            ),
          ),
          currentOrderProvider.overrideWith((ref) async => order),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(AppStrings.homeOrderHistoryTitle), findsOneWidget);
    expect(find.text(AppStrings.homeOrderStatusDelivery), findsOneWidget);
    expect(find.byType(AuthPromptBanner), findsNothing);
  });
}
