import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/auth/data/secure_token_storage.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';

void main() {
  test('applyRefreshedTokens updates storage and session state', () async {
    final storage = InMemoryTokenStorage();
    await storage.saveTokens(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );

    late AuthSessionNotifier notifier;
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authSessionProvider.overrideWith(() {
          notifier = AuthSessionNotifier();
          return notifier;
        }),
      ],
    );
    addTearDown(container.dispose);

    notifier = container.read(authSessionProvider.notifier);
    await notifier.setSession(
      tokens: const TokenResponse(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
        expiresIn: 3600,
        tokenType: 'Bearer',
      ),
      phone: '+79001234567',
    );

    await notifier.applyRefreshedTokens(
      const TokenResponse(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
        expiresIn: 3600,
        tokenType: 'Bearer',
      ),
    );

    expect(await storage.readAccessToken(), 'new-access');
    expect(await storage.readRefreshToken(), 'new-refresh');

    final session = container.read(authSessionProvider);
    expect(session?.accessToken, 'new-access');
    expect(session?.refreshToken, 'new-refresh');
    expect(session?.phone, '+79001234567');
  });

  test('applyRefreshedTokens is no-op when session is cleared', () async {
    final storage = InMemoryTokenStorage();
    await storage.saveTokens(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );

    late AuthSessionNotifier notifier;
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authSessionProvider.overrideWith(() {
          notifier = AuthSessionNotifier();
          return notifier;
        }),
      ],
    );
    addTearDown(container.dispose);

    notifier = container.read(authSessionProvider.notifier);
    await notifier.clearSession();

    await notifier.applyRefreshedTokens(
      const TokenResponse(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
        expiresIn: 3600,
        tokenType: 'Bearer',
      ),
    );

    expect(await storage.readAccessToken(), isNull);
    expect(container.read(authSessionProvider), isNull);
  });
}
