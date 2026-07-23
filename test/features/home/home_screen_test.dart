import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/core/widgets/safe_cached_network_image.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/data/order_repository.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/home/presentation/banner_carousel.dart';
import 'package:osetrovich/features/home/presentation/home_lemon_gamification_card.dart';
import 'package:osetrovich/features/home/presentation/home_lemon_gamification_card_skeleton.dart';
import 'package:osetrovich/features/home/presentation/home_loyalty_status_card_skeleton.dart';
import 'package:osetrovich/features/home/presentation/home_profile_slot.dart';
import 'package:osetrovich/features/home/presentation/home_screen.dart';
import 'package:osetrovich/features/notifications/domain/unread_count_notifier.dart';
import 'package:osetrovich/features/profile/domain/loyalty_status.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}

class _FakeLemonProfileNotifier extends ProfileNotifier {
  @override
  Future<UserProfile?> build() async => const UserProfile(
    id: 'u1',
    name: 'Покупатель',
    phone: '+79005555555',
    emailVerified: false,
    pushEnabled: true,
    discount: 5,
    lemons: 7,
    loyaltyStatus: LoyaltyStatus.clubMember,
  );
}

class _FakeLemonProfileWithoutStatusNotifier extends ProfileNotifier {
  @override
  Future<UserProfile?> build() async => const UserProfile(
    id: 'u2',
    name: 'Покупатель',
    phone: '+79003333333',
    emailVerified: false,
    pushEnabled: true,
    discount: 0,
    lemons: 3,
  );
}

class _FakeLoyaltyProfileNotifier extends ProfileNotifier {
  @override
  Future<UserProfile?> build() async => const UserProfile(
    id: 'u1',
    name: 'Покупатель',
    phone: '+79001111111',
    emailVerified: false,
    pushEnabled: true,
    discount: 10,
    loyaltyStatus: LoyaltyStatus.premium,
    card: '1234567890123456',
  );
}

class _FailingProfileNotifier extends ProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    throw ApiException(code: 'NETWORK_ERROR', message: AppStrings.networkError);
  }
}

class _SlowProfileNotifier extends ProfileNotifier {
  _SlowProfileNotifier(this._completer);

  final Completer<UserProfile?> _completer;

  @override
  Future<UserProfile?> build() => _completer.future;
}

class _RefreshableLoyaltyProfileNotifier extends ProfileNotifier {
  _RefreshableLoyaltyProfileNotifier(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile?> build() async => _profile;

  @override
  Future<void> refresh() async {
    state = const AsyncLoading<UserProfile?>().copyWithPrevious(state);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state = AsyncData(_profile);
  }
}

void main() {
  testWidgets('home shows notifications badge auth button weekly for guest', (
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
    expect(find.text(AppStrings.homeAuthButton), findsOneWidget);
    expect(find.text(AppStrings.contactUs), findsNothing);
    expect(find.text(AppStrings.authPrompt), findsNothing);
    expect(find.text(AppStrings.homeWeeklyProductsTitle), findsOneWidget);
    expect(find.text(AppStrings.homeLemonGamificationTitle), findsNothing);
    expect(find.byType(SafeCachedNetworkImage), findsWidgets);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('home shows loyalty block when authenticated with status', (
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
          profileNotifierProvider.overrideWith(_FakeLoyaltyProfileNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Premium'), findsOneWidget);
    expect(find.text(AppStrings.homeLoyaltyYourDiscount), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('1234 5678 9012 3456'), findsOneWidget);
    expect(find.text(AppStrings.homeAuthButton), findsNothing);
  });

  testWidgets('home shows lemon gamification block when authenticated', (
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
          authSessionProvider.overrideWith(
            () => _FakeAuthSessionNotifier(
              AuthSession(
                accessToken: 'mock.access.token.+79005555555',
                refreshToken: 'r',
                expiresAt: DateTime.utc(2099),
                phone: '+79005555555',
              ),
            ),
          ),
          profileNotifierProvider.overrideWith(_FakeLemonProfileNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeLemonGamificationTitle), findsOneWidget);
    expect(find.text(AppStrings.homeLemonGamificationCaption), findsOneWidget);
    expect(find.byKey(HomeLemonGamificationCard.cardKey), findsOneWidget);
  });

  testWidgets('home hides lemon block when profile fails to load', (
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
          profileNotifierProvider.overrideWith(_FailingProfileNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeLemonGamificationTitle), findsNothing);
  });

  testWidgets(
    'home places profile slot before lemon block before weekly products',
    (tester) async {
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
                  accessToken: 'mock.access.token.+79005555555',
                  refreshToken: 'r',
                  expiresAt: DateTime.utc(2099),
                  phone: '+79005555555',
                ),
              ),
            ),
            profileNotifierProvider.overrideWith(_FakeLemonProfileNotifier.new),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final profileSlot = tester.getTopLeft(find.byType(HomeProfileSlot));
      final lemonCard = tester.getTopLeft(
        find.byKey(HomeLemonGamificationCard.cardKey),
      );
      final weeklyTitle = tester.getTopLeft(
        find.text(AppStrings.homeWeeklyProductsTitle),
      );

      expect(profileSlot.dy, lessThan(lemonCard.dy));
      expect(lemonCard.dy, lessThan(weeklyTitle.dy));
    },
  );

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
          profileNotifierProvider.overrideWith(_FakeLoyaltyProfileNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeOrderHistoryTitle), findsOneWidget);
    expect(find.text(AppStrings.homeOrderStatusDelivery), findsOneWidget);
    expect(find.text(AppStrings.homeAuthButton), findsNothing);
  });

  testWidgets('home shows auth button again after logout', (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late AuthSessionNotifier authNotifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          authSessionProvider.overrideWith(() {
            authNotifier = _FakeAuthSessionNotifier(
              AuthSession(
                accessToken: 'mock.access.token.+79001111111',
                refreshToken: 'r',
                expiresAt: DateTime.utc(2099),
                phone: '+79001111111',
              ),
            );
            return authNotifier;
          }),
          profileNotifierProvider.overrideWith(_FakeLoyaltyProfileNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Premium'), findsOneWidget);

    authNotifier.state = null;
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeAuthButton), findsOneWidget);
    expect(find.text('Premium'), findsNothing);
  });

  testWidgets('home shows profile skeletons while profile is loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profileCompleter = Completer<UserProfile?>();
    addTearDown(() {
      if (!profileCompleter.isCompleted) {
        profileCompleter.complete(null);
      }
    });

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
          profileNotifierProvider.overrideWith(
            () => _SlowProfileNotifier(profileCompleter),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(HomeLoyaltyStatusCardSkeleton.skeletonKey),
      findsOneWidget,
    );
    expect(
      find.byKey(HomeLemonGamificationCardSkeleton.skeletonKey),
      findsOneWidget,
    );
    expect(find.text('Premium'), findsNothing);
    expect(find.text(AppStrings.homeLemonGamificationTitle), findsNothing);

    // Дождаться mock-задержек (уведомления и т.п.), не дожидаясь профиля.
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('home hides loyalty card when profile fails to load', (
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
          profileNotifierProvider.overrideWith(_FailingProfileNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Premium'), findsNothing);
    expect(find.text(AppStrings.homeAuthButton), findsNothing);
    expect(
      find.byKey(HomeLoyaltyStatusCardSkeleton.skeletonKey),
      findsNothing,
    );
  });

  testWidgets('home shows lemon block with top spacing when loyalty hidden', (
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
          authSessionProvider.overrideWith(
            () => _FakeAuthSessionNotifier(
              AuthSession(
                accessToken: 'mock.access.token.+79003333333',
                refreshToken: 'r',
                expiresAt: DateTime.utc(2099),
                phone: '+79003333333',
              ),
            ),
          ),
          profileNotifierProvider.overrideWith(
            _FakeLemonProfileWithoutStatusNotifier.new,
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final bannerBottom = tester.getBottomLeft(find.byType(BannerCarousel));
    final lemonTop = tester.getTopLeft(
      find.byKey(HomeLemonGamificationCard.cardKey),
    );

    expect(lemonTop.dy - bannerBottom.dy, greaterThanOrEqualTo(16));
  });

  testWidgets('home keeps profile content visible during profile refresh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const profile = UserProfile(
      id: 'u1',
      name: 'Покупатель',
      phone: '+79001111111',
      emailVerified: false,
      pushEnabled: true,
      discount: 10,
      loyaltyStatus: LoyaltyStatus.premium,
      card: '1234567890123456',
    );
    late _RefreshableLoyaltyProfileNotifier profileNotifier;

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
          profileNotifierProvider.overrideWith(() {
            profileNotifier = _RefreshableLoyaltyProfileNotifier(profile);
            return profileNotifier;
          }),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Premium'), findsOneWidget);

    final refreshFuture = profileNotifier.refresh();
    await tester.pump();

    expect(find.text('Premium'), findsOneWidget);
    expect(
      find.byKey(HomeLoyaltyStatusCardSkeleton.skeletonKey),
      findsNothing,
    );
    expect(
      find.byKey(HomeLemonGamificationCardSkeleton.skeletonKey),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 100));
    await refreshFuture;
    await tester.pump();

    expect(find.text('Premium'), findsOneWidget);
  });

  testWidgets('home shows order load error and retry refetches provider', (
    tester,
  ) async {
    var fetchCount = 0;

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
          currentOrderProvider.overrideWith((ref) async {
            fetchCount++;
            if (fetchCount == 1) {
              throw ApiException(
                code: 'NETWORK_ERROR',
                message: AppStrings.networkError,
              );
            }
            return null;
          }),
          profileNotifierProvider.overrideWith(_FakeLoyaltyProfileNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeLoadError), findsOneWidget);
    expect(find.text(AppStrings.homeRetry), findsWidgets);

    await tester.tap(find.text(AppStrings.homeRetry).last);
    await tester.pumpAndSettle();

    expect(fetchCount, greaterThan(1));
  });
}
