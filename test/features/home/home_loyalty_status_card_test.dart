import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/home/domain/home_loyalty_status_ui_model.dart';
import 'package:osetrovich/features/home/presentation/home_loyalty_status_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home loyalty card shows premium layout with promo condition', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeLoyaltyStatusCard(
            model: const HomeLoyaltyStatusUiModel(
              statusLabel: 'Premium',
              showsMaximumLevelBadge: false,
              discountAppliesToAllPurchases: false,
              discountPercent: 10,
              cardNumber: '1234567890123456',
            ),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.homeLoyaltyStatusTitle), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text(AppStrings.homeLoyaltyYourDiscount), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(
      find.text(AppStrings.homeLoyaltyDiscountExceptPromo),
      findsOneWidget,
    );
    expect(find.text('1234 5678 9012 3456'), findsOneWidget);
    expect(find.text(AppStrings.homeLoyaltyMaximumLevel), findsNothing);
  });

  testWidgets('home loyalty card shows vip badge and all purchases condition', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: HomeLoyaltyStatusCard(
            model: HomeLoyaltyStatusUiModel(
              statusLabel: 'Super VIP',
              showsMaximumLevelBadge: true,
              discountAppliesToAllPurchases: true,
              discountPercent: 25,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Super VIP'), findsOneWidget);
    expect(find.text(AppStrings.homeLoyaltyMaximumLevel), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(
      find.text(AppStrings.homeLoyaltyDiscountAllPurchases),
      findsOneWidget,
    );
    expect(find.text(AppStrings.homeLoyaltyDiscountExceptPromo), findsNothing);
  });

  testWidgets('home loyalty card hides discount section when absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: HomeLoyaltyStatusCard(
            model: HomeLoyaltyStatusUiModel(
              statusLabel: 'VIP',
              showsMaximumLevelBadge: true,
              discountAppliesToAllPurchases: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('VIP'), findsOneWidget);
    expect(find.text(AppStrings.homeLoyaltyMaximumLevel), findsOneWidget);
    expect(find.text(AppStrings.homeLoyaltyYourDiscount), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('home loyalty card does not overflow on narrow width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: HomeLoyaltyStatusCard(
              model: const HomeLoyaltyStatusUiModel(
                statusLabel: 'VIP',
                showsMaximumLevelBadge: true,
                discountAppliesToAllPurchases: true,
                discountPercent: 30,
                cardNumber: '0710',
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text(AppStrings.homeLoyaltyMaximumLevel), findsOneWidget);
  });

  testWidgets('copy button shows copied snackbar', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
      methodCall,
    ) async {
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeLoyaltyStatusCard(
            model: const HomeLoyaltyStatusUiModel(
              statusLabel: 'Premium',
              showsMaximumLevelBadge: false,
              discountAppliesToAllPurchases: false,
              cardNumber: '1234567890',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.copy_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.homeLoyaltyCardCopied), findsOneWidget);
  });
}
