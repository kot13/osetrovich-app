import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/cart/data/order_repository.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/home/presentation/home_order_history_section.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(const SubmitOrderRatingRequest(stars: 1));
  });

  CurrentOrder sampleOrder({
    OrderStatus status = OrderStatus.delivery,
    OrderRatingState ratingState = OrderRatingState.notApplicable,
  }) {
    return CurrentOrder(
      id: 'ord-1',
      orderNumber: 'ORD-1001',
      items: const [
        OrderLine(
          id: 1000,
          name: 'Сёмга',
          weightLabel: '500 г',
          priceRub: 890,
          quantity: 2,
          lineTotalRub: 1780,
        ),
      ],
      itemsSubtotalRub: 1780,
      deliveryFeeRub: 300,
      totalRub: 2080,
      deliveryAddress: 'СПб',
      status: status,
      createdAt: DateTime.utc(2026, 7, 15),
      ratingState: ratingState,
    );
  }

  testWidgets('shows order status, total and operator button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: HomeOrderHistorySection(order: sampleOrder())),
      ),
    );

    expect(find.text(AppStrings.homeOrderHistoryTitle), findsOneWidget);
    expect(find.text(AppStrings.homeOrderStatusDelivery), findsOneWidget);
    expect(find.text(AppStrings.homeContactOperator), findsOneWidget);
    expect(find.textContaining('2080'), findsOneWidget);
  });

  testWidgets('completed pending shows rating prompt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeOrderHistorySection(
            order: sampleOrder(
              status: OrderStatus.completed,
              ratingState: OrderRatingState.pending,
            ),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.homeOrderRatingPrompt), findsOneWidget);
    expect(find.text(AppStrings.homeOrderRate), findsOneWidget);
    expect(find.text(AppStrings.homeOrderSkipRating), findsOneWidget);
    expect(find.text(AppStrings.homeRepeatOrder), findsNothing);
  });

  testWidgets('completed skipped shows repeat button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeOrderHistorySection(
            order: sampleOrder(
              status: OrderStatus.completed,
              ratingState: OrderRatingState.skipped,
            ),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.homeRepeatOrder), findsOneWidget);
    expect(find.text(AppStrings.homeOrderRatingPrompt), findsNothing);
  });

  testWidgets('skip rating calls repository', (tester) async {
    final mockApi = _MockApiClient();
    when(() => mockApi.skipOrderRating('ord-1')).thenAnswer(
      (_) async => sampleOrder(
        status: OrderStatus.completed,
        ratingState: OrderRatingState.skipped,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(mockApi)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: HomeOrderHistorySection(
              order: sampleOrder(
                status: OrderStatus.completed,
                ratingState: OrderRatingState.pending,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.homeOrderSkipRating));
    await tester.pump();

    verify(() => mockApi.skipOrderRating('ord-1')).called(1);
  });

  testWidgets('skip rating period expired shows snackbar', (tester) async {
    final mockApi = _MockApiClient();

    when(() => mockApi.skipOrderRating('ord-1')).thenThrow(
      ApiException(
        code: 'rating_period_expired',
        message: AppStrings.ratingPeriodExpired,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(mockApi)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: HomeOrderHistorySection(
              order: sampleOrder(
                status: OrderStatus.completed,
                ratingState: OrderRatingState.pending,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.homeOrderSkipRating));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.ratingPeriodExpired), findsOneWidget);
    verify(() => mockApi.skipOrderRating('ord-1')).called(1);
  });

  testWidgets('rate order shows snackbar when rating already set', (
    tester,
  ) async {
    final mockApi = _MockApiClient();
    when(() => mockApi.submitOrderRating('ord-1', any())).thenThrow(
      ApiException(
        code: 'rating_already_set',
        message: AppStrings.ratingAlreadySet,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(mockApi)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: HomeOrderHistorySection(
              order: sampleOrder(
                status: OrderStatus.completed,
                ratingState: OrderRatingState.pending,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.homeOrderRate));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border).at(4));
    await tester.pump();
    await tester.tap(find.text(AppStrings.homeOrderRatingSubmit));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.ratingAlreadySet), findsOneWidget);
  });
}
