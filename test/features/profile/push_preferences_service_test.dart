import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/push/push_service.dart';
import 'package:osetrovich/core/push/push_token_registration_service.dart';
import 'package:osetrovich/features/profile/data/profile_repository.dart';
import 'package:osetrovich/features/profile/domain/push_preferences_service.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockPushService extends Mock implements PushService {}

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockProfileRepository repository;
  late _MockPushService pushService;
  late _MockApiClient apiClient;
  late PushPreferencesService service;

  setUp(() {
    repository = _MockProfileRepository();
    pushService = _MockPushService();
    apiClient = _MockApiClient();
    when(() => pushService.syncPushEnabled(any())).thenAnswer((_) async {});
    when(() => pushService.getTokens()).thenAnswer(
      (_) async => const {'android': 'token-1'},
    );
    when(
      () => apiClient.registerPushToken(token: any(named: 'token'), platform: any(named: 'platform')),
    ).thenAnswer((_) async {});
    service = PushPreferencesService(
      repository,
      pushService,
      PushTokenRegistrationService(apiClient),
    );
  });

  test(
    'updatePushEnabled calls repository and syncs push service when disabling',
    () async {
      when(
        () => repository.updatePushEnabled(false),
      ).thenAnswer((_) async => const ProfilePreferences(pushEnabled: false));

      await service.updatePushEnabled(false);

      verify(() => repository.updatePushEnabled(false)).called(1);
      verify(() => pushService.syncPushEnabled(false)).called(1);
    },
  );
}
