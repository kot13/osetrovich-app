import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/auth/data/secure_token_storage.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';
import 'package:osetrovich/features/profile/presentation/profile_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _testProfile = UserProfile(
  id: 'u1',
  name: 'Покупатель',
  phone: '+79001234567',
  emailVerified: false,
  pushEnabled: true,
  discount: 0,
);

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile?> build() async => _profile;
}

class _SessionAwareProfileNotifier extends ProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    final session = ref.watch(authSessionProvider);
    if (session == null) {
      return null;
    }
    return UserProfile(
      id: 'u-${session.phone}',
      name: session.phone == '+79001111111' ? 'Алиса' : 'Борис',
      phone: session.phone,
      emailVerified: false,
      pushEnabled: true,
      discount: 0,
    );
  }
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'osetrovich',
      packageName: 'ru.osetrovich.osetrovich',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

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
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.appVersion('1.0.0')), findsOneWidget);
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
          profileNotifierProvider.overrideWith(
            () => _FakeProfileNotifier(_testProfile),
          ),
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
          profileNotifierProvider.overrideWith(
            () => _FakeProfileNotifier(_testProfile),
          ),
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
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.pushNotifications), findsOneWidget);
    expect(find.text(AppStrings.logout), findsOneWidget);
    expect(find.text(AppStrings.setPin), findsNothing);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text(AppStrings.appVersion('1.0.0')), findsOneWidget);
  });

  testWidgets('profile name updates after logout and login as another user', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryTokenStorage();
    late AuthSessionNotifier authNotifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          tokenStorageProvider.overrideWithValue(storage),
          authSessionProvider.overrideWith(() {
            authNotifier = AuthSessionNotifier();
            return authNotifier;
          }),
          profileNotifierProvider.overrideWith(
            _SessionAwareProfileNotifier.new,
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
      ),
    );

    await authNotifier.setSession(
      tokens: const TokenResponse(
        accessToken: 'mock.access.token.+79001111111',
        refreshToken: 'r',
        expiresIn: 3600,
        tokenType: 'Bearer',
      ),
      phone: '+79001111111',
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(AppStrings.logout).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(_nameFieldText(tester), 'Алиса');

    await tester.tap(find.text(AppStrings.logout));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await authNotifier.setSession(
      tokens: const TokenResponse(
        accessToken: 'mock.access.token.+79002222222',
        refreshToken: 'r2',
        expiresIn: 3600,
        tokenType: 'Bearer',
      ),
      phone: '+79002222222',
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(AppStrings.logout).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(_nameFieldText(tester), 'Борис');
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

String _nameFieldText(WidgetTester tester) {
  final field = tester.widget<TextField>(find.byType(TextField));
  return field.controller?.text ?? '';
}
