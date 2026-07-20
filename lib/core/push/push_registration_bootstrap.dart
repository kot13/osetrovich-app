import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/push/push_providers.dart';
import 'package:osetrovich/core/push/push_token_registration_service.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';

final pushTokenRegistrationServiceProvider = Provider<PushTokenRegistrationService>(
  (ref) => PushTokenRegistrationService(ref.watch(apiClientProvider)),
);

final pushRegistrationBootstrapProvider = Provider<void>((ref) {
  final registrationService = ref.watch(pushTokenRegistrationServiceProvider);
  final pushService = ref.watch(pushServiceProvider);

  Future<void> registerCurrentTokens() async {
    if (ref.read(authSessionProvider) == null) {
      return;
    }
    final tokens = await pushService.getTokens();
    await registrationService.registerFromTokenMap(tokens);
  }

  ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
    if (next != null) {
      registerCurrentTokens();
    }
  });

  pushService.listenForTokenUpdates((tokens) {
    registrationService.registerFromTokenMap(tokens);
  });

  if (ref.read(authSessionProvider) != null) {
    registerCurrentTokens();
  }
});

/// Вызывается после входа или refresh сессии для немедленной регистрации токена.
Future<void> registerPushTokenAfterAuth(WidgetRef ref) async {
  ref.read(pushRegistrationBootstrapProvider);
  final pushService = ref.read(pushServiceProvider);
  final registrationService = ref.read(pushTokenRegistrationServiceProvider);
  final tokens = await pushService.getTokens();
  await registrationService.registerFromTokenMap(tokens);
}

Future<void> registerPushTokenAfterAuthFromRef(Ref ref) async {
  final pushService = ref.read(pushServiceProvider);
  final registrationService = ref.read(pushTokenRegistrationServiceProvider);
  final tokens = await pushService.getTokens();
  await registrationService.registerFromTokenMap(tokens);
}
