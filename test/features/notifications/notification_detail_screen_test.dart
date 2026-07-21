import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/notifications/presentation/notification_detail_screen.dart';

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}

class _RatingTestApiClient extends MockApiClient {
  _RatingTestApiClient({this.currentOrder, this.onSubmitRating});

  CurrentOrder? currentOrder;
  Future<CurrentOrder> Function(
    String orderId,
    SubmitOrderRatingRequest request,
  )?
  onSubmitRating;

  @override
  Future<CurrentOrder?> getCurrentOrder() async => currentOrder;

  @override
  Future<CurrentOrder> submitOrderRating(
    String orderId,
    SubmitOrderRatingRequest request,
  ) {
    final handler = onSubmitRating;
    if (handler != null) {
      return handler(orderId, request);
    }
    return super.submitOrderRating(orderId, request);
  }
}

CurrentOrder _pendingOrder() {
  return CurrentOrder(
    id: 'ord-1',
    orderNumber: 'ORD-1001',
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
    status: OrderStatus.completed,
    createdAt: DateTime.utc(2026, 7, 15),
    deliveryAt: DateTime.utc(2026, 7, 15),
    ratingState: OrderRatingState.pending,
  );
}

ProviderScope _scoped(Widget child, {ApiClient? apiClient}) {
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(apiClient ?? MockApiClient()),
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
        apiClient: _RatingTestApiClient(currentOrder: _pendingOrder()),
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

  testWidgets('rate order button hidden when rating state is not pending', (
    tester,
  ) async {
    final apiClient = _RatingTestApiClient(
      currentOrder: _pendingOrder().copyWith(
        ratingState: OrderRatingState.submitted,
        ratingStars: 5,
      ),
    );

    await tester.pumpWidget(
      _scoped(
        MaterialApp(
          theme: AppTheme.light,
          home: const NotificationDetailScreen(notificationId: '4'),
        ),
        apiClient: apiClient,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.rateOrderFromNotification), findsNothing);
  });

  testWidgets('rate order button hides after successful rating', (
    tester,
  ) async {
    final apiClient = _RatingTestApiClient(
      currentOrder: _pendingOrder(),
      onSubmitRating:
          (_, __) async => _pendingOrder().copyWith(
            ratingState: OrderRatingState.submitted,
            ratingStars: 5,
          ),
    );

    await tester.pumpWidget(
      _scoped(
        MaterialApp(
          theme: AppTheme.light,
          home: const NotificationDetailScreen(notificationId: '4'),
        ),
        apiClient: apiClient,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.rateOrderFromNotification), findsOneWidget);

    await tester.tap(find.text(AppStrings.rateOrderFromNotification));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.star_border).at(4));
    await tester.pump();
    await tester.tap(find.text(AppStrings.homeOrderRatingSubmit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppStrings.rateOrderFromNotification), findsNothing);
    expect(find.text(AppStrings.ratingThankYou), findsOneWidget);
  });

  testWidgets('rate order shows expired snackbar when period ended', (
    tester,
  ) async {
    final apiClient = _RatingTestApiClient(
      currentOrder: _pendingOrder(),
      onSubmitRating: (_, __) async {
        throw ApiException(
          code: 'rating_period_expired',
          message: AppStrings.ratingPeriodExpired,
        );
      },
    );

    await tester.pumpWidget(
      _scoped(
        MaterialApp(
          theme: AppTheme.light,
          home: const NotificationDetailScreen(notificationId: '4'),
        ),
        apiClient: apiClient,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.rateOrderFromNotification));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.star_border), findsWidgets);
    await tester.tap(find.byIcon(Icons.star_border).at(4));
    await tester.pump();
    await tester.tap(find.text(AppStrings.homeOrderRatingSubmit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppStrings.ratingPeriodExpired), findsOneWidget);
  });
}
