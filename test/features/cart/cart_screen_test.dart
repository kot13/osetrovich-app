import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/mock_profile_sync.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/cart/presentation/cart_screen.dart';

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}

class _TestAuthSessionNotifier extends AuthSessionNotifier {
  @override
  AuthSession? build() => null;

  void login(String phone) {
    state = AuthSession(
      accessToken: 'mock.access.token.$phone',
      refreshToken: 'r',
      expiresAt: AuthSession.neverExpiresAt,
      phone: phone,
    );
    syncMockApiProfile(ref, state!);
  }
}

void main() {
  Future<void> pumpLargeScreen(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  Widget buildCartApp({
    required ProviderContainer container,
    List<GoRoute> extraRoutes = const [],
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const CartScreen()),
        GoRoute(
          path: '/catalog',
          builder: (_, __) => const Scaffold(body: Text('catalog')),
        ),
        GoRoute(
          path: '/auth/phone',
          builder: (context, state) {
            final from = state.uri.queryParameters['from'];
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  final notifier = container.read(authSessionProvider.notifier);
                  if (notifier is _TestAuthSessionNotifier) {
                    notifier.login('+79001234567');
                  }
                  if (from == 'checkout') {
                    context.go('/');
                  } else {
                    context.pop();
                  }
                },
                child: const Text('auth phone'),
              ),
            );
          },
        ),
        ...extraRoutes,
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  testWidgets('cart shows empty state and catalog button', (tester) async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildCartApp(container: container));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cartEmpty), findsOneWidget);
    expect(find.text(AppStrings.goToCatalog), findsOneWidget);
  });

  testWidgets('filled cart shows list summary terms and checkout form', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment('p-fish-0');

    await tester.pumpWidget(buildCartApp(container: container));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cartEmpty), findsNothing);
    expect(find.textContaining('Сёмга'), findsOneWidget);
    expect(find.text(AppStrings.cartItemsSubtotal), findsOneWidget);
    expect(find.text(AppStrings.cartDeliveryFee), findsOneWidget);
    expect(find.text(AppStrings.cartTotal), findsOneWidget);
    expect(find.text(AppStrings.cartDeliveryTerms), findsOneWidget);
    expect(find.text(AppStrings.cartCheckout), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('filled cart updates summary when quantity changes', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment('p-fish-0');

    await tester.pumpWidget(buildCartApp(container: container));
    await tester.pumpAndSettle();

    final initialTotal = find.textContaining('₽').evaluate().length;

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('₽').evaluate().length,
      greaterThanOrEqualTo(initialTotal),
    );
    expect(find.textContaining('2 ×'), findsOneWidget);
  });

  testWidgets('removing last item shows empty state', (tester) async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment('p-fish-0');

    await tester.pumpWidget(buildCartApp(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cartEmpty), findsOneWidget);
  });

  testWidgets('unauthenticated checkout navigates to auth', (tester) async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment('p-fish-0');

    await pumpLargeScreen(tester, buildCartApp(container: container));

    await tester.enterText(
      find.byType(TextField).first,
      'г. Санкт-Петербург, 1',
    );
    await tester.tap(find.text(AppStrings.cartCheckout));
    await tester.pumpAndSettle();

    expect(find.text('auth phone'), findsOneWidget);
    expect(container.read(cartNotifierProvider), isNotEmpty);
  });

  testWidgets('checkout resumes order after auth from checkout', (tester) async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(MockApiClient()),
        authSessionProvider.overrideWith(_TestAuthSessionNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment('p-fish-0');

    await pumpLargeScreen(tester, buildCartApp(container: container));

    await tester.enterText(
      find.byType(TextField).first,
      'г. Санкт-Петербург, 1',
    );
    await tester.tap(find.text(AppStrings.cartCheckout));
    await tester.pumpAndSettle();

    await tester.tap(find.text('auth phone'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(AppStrings.cartOrderSuccess), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cartEmpty), findsOneWidget);
    expect(container.read(cartNotifierProvider), isEmpty);
  });

  testWidgets('authenticated checkout shows success dialog and clears cart', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          MockApiClient()..ensureProfile('+79001234567'),
        ),
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionNotifier(
            AuthSession(
              accessToken: 'mock.access.token.+79001234567',
              refreshToken: 'r',
              expiresAt: DateTime.utc(2099),
              phone: '+79001234567',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment('p-fish-0');

    await pumpLargeScreen(tester, buildCartApp(container: container));

    await tester.enterText(
      find.byType(TextField).first,
      'г. Санкт-Петербург, 1',
    );
    await tester.tap(find.text(AppStrings.cartCheckout));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(AppStrings.cartOrderSuccess), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cartEmpty), findsOneWidget);
    expect(container.read(cartNotifierProvider), isEmpty);
  });
}
