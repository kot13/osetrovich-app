import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/home/presentation/home_loyalty_status_card_skeleton.dart';

void main() {
  testWidgets('loyalty status skeleton renders shimmer placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: HomeLoyaltyStatusCardSkeleton()),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(HomeLoyaltyStatusCardSkeleton.skeletonKey),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.byKey(HomeLoyaltyStatusCardSkeleton.skeletonKey),
      findsOneWidget,
    );
  });
}
