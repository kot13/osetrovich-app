import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/notifications/domain/unread_count_notifier.dart';
import 'package:osetrovich/features/notifications/presentation/widgets/notification_bell_action.dart';

void main() {
  Widget buildTestApp({
    required GoRouter router,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  testWidgets('shows icon without badge when unread count is zero', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder:
              (context, state) =>
                  const Scaffold(body: NotificationBellAction()),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        router: router,
        overrides: [unreadCountProvider.overrideWith((ref) => 0)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('shows badge when unread count is positive', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder:
              (context, state) =>
                  const Scaffold(body: NotificationBellAction()),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        router: router,
        overrides: [unreadCountProvider.overrideWith((ref) => 3)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('tap pushes notifications list for current tab root', (
    tester,
  ) async {
    String? pushedPath;

    final router = GoRouter(
      initialLocation: '/catalog',
      routes: [
        GoRoute(
          path: '/catalog',
          builder:
              (context, state) =>
                  const Scaffold(body: NotificationBellAction()),
          routes: [
            GoRoute(
              path: 'notifications',
              builder: (context, state) {
                pushedPath = state.uri.path;
                return const Scaffold(body: Text('notifications list'));
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        router: router,
        overrides: [unreadCountProvider.overrideWith((ref) => 1)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();

    expect(pushedPath, '/catalog/notifications');
    expect(find.text('notifications list'), findsOneWidget);
  });

  testWidgets('two bells share the same unread count', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder:
              (context, state) => const Scaffold(
                body: Column(
                  children: [
                    NotificationBellAction(),
                    NotificationBellAction(),
                  ],
                ),
              ),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        router: router,
        overrides: [unreadCountProvider.overrideWith((ref) => 5)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5'), findsNWidgets(2));
  });
}
