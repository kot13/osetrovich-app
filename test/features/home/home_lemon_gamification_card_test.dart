import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/home/domain/home_lemon_gamification_ui_model.dart';
import 'package:osetrovich/features/home/presentation/home_lemon_gamification_card.dart';
import 'package:osetrovich/features/home/presentation/lemon_progress_icon.dart';

void main() {
  testWidgets(
    'home lemon gamification card shows progress gift info and terms',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: HomeLemonGamificationCard(
              model: buildHomeLemonGamificationUiModel(7),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.homeLemonGamificationTitle), findsOneWidget);
      expect(
        find.text(AppStrings.homeLemonGamificationGiftTitle),
        findsOneWidget,
      );
      expect(find.text('Ещё 3 лимона до подарка'), findsOneWidget);
      expect(find.text('7 / 10'), findsOneWidget);
      expect(
        find.text(AppStrings.homeLemonGamificationCaption),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.homeLemonGamificationTermsLink),
        findsOneWidget,
      );
      expect(find.byType(LemonProgressIcon), findsNWidgets(10));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    },
  );

  testWidgets('shows gift ready message at 10 lemons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeLemonGamificationCard(
            model: buildHomeLemonGamificationUiModel(10),
          ),
        ),
      ),
    );

    expect(
      find.text(AppStrings.homeLemonGamificationGiftReady),
      findsOneWidget,
    );
    expect(find.text('10 / 10'), findsOneWidget);
  });

  testWidgets('terms link navigates to promotion article 1', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) => Scaffold(
                body: HomeLemonGamificationCard(
                  model: buildHomeLemonGamificationUiModel(4),
                ),
              ),
        ),
        GoRoute(
          path: '/promotions/article/:id',
          builder:
              (context, state) => Scaffold(
                body: Text('article-${state.pathParameters['id']}'),
              ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeLemonGamificationCard.termsLinkKey));
    await tester.pumpAndSettle();

    expect(find.text('article-1'), findsOneWidget);
  });
}
