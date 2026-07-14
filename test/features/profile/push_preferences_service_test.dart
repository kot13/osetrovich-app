import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/features/profile/data/profile_repository.dart';
import 'package:osetrovich/features/profile/domain/push_preferences_service.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository repository;
  late PushPreferencesService service;

  setUp(() {
    repository = _MockProfileRepository();
    service = PushPreferencesService(repository);
  });

  test('updatePushEnabled calls repository when disabling', () async {
    when(
      () => repository.updatePushEnabled(false),
    ).thenAnswer((_) async => const ProfilePreferences(pushEnabled: false));

    await service.updatePushEnabled(false);

    verify(() => repository.updatePushEnabled(false)).called(1);
  });
}
