import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/auth/data/secure_token_storage.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';
import 'package:osetrovich/features/profile/presentation/profile_screen.dart';

const _testProfile = UserProfile(
  id: 'u1',
  name: 'Покупатель',
  phone: '+79001234567',
  emailVerified: false,
  pushEnabled: true,
  discount: 0,
);

class _FakeProfileNotifier extends ProfileNotifier {
  @override
  Future<UserProfile?> build() async => _testProfile;
}

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}

class _FailingProfileNotifier extends ProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    throw ApiException(code: 'NETWORK_ERROR', message: AppStrings.networkError);
  }
}

void main() {
  testWidgets('profile guest shows auth required and legal section', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
      ),
    );

    expect(find.text(AppStrings.profileAuthRequired), findsOneWidget);
    expect(find.text(AppStrings.signIn), findsOneWidget);
    expect(find.text(AppStrings.contactUs), findsOneWidget);
    expect(find.text(AppStrings.privacyPolicy), findsOneWidget);
  });

  testWidgets('profile after clearSession shows auth required', (tester) async {
    final storage = InMemoryTokenStorage();
    late AuthSessionNotifier authNotifier;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          authSessionProvider.overrideWith(() {
            authNotifier = AuthSessionNotifier();
            return authNotifier;
          }),
          profileNotifierProvider.overrideWith(_FakeProfileNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
      ),
    );

    await authNotifier.setSession(
      tokens: const TokenResponse(
        accessToken: 'mock.access.token.+79001234567',
        refreshToken: 'r',
        expiresIn: 3600,
        tokenType: 'Bearer',
      ),
      phone: '+79001234567',
    );
    await tester.pumpAndSettle();

    await authNotifier.clearSession();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.profileAuthRequired), findsOneWidget);
    expect(find.text(AppStrings.signIn), findsOneWidget);
  });

  testWidgets('authenticated profile shows logout', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
          profileNotifierProvider.overrideWith(_FakeProfileNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
      ),
    );

    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(AppStrings.pushNotifications).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text(AppStrings.pushNotifications), findsOneWidget);
    expect(find.text(AppStrings.logout), findsOneWidget);
    expect(find.text(AppStrings.setPin), findsNothing);
  });

  testWidgets('profile error state shows user-friendly message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
          profileNotifierProvider.overrideWith(_FailingProfileNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppStrings.networkError), findsOneWidget);
    expect(find.textContaining('DioException'), findsNothing);
    expect(find.textContaining('bad response'), findsNothing);
  });
}
