import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/profile/data/profile_repository.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PushPreferencesService {
  PushPreferencesService(this._repository);

  final ProfileRepository _repository;

  Future<bool> isOsPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<PermissionStatus> requestOsPermission() {
    return Permission.notification.request();
  }

  Future<bool> updatePushEnabled(bool enabled) async {
    if (enabled) {
      final status = await requestOsPermission();
      if (!status.isGranted && !status.isLimited) {
        throw ApiException(
          code: 'PERMISSION_DENIED',
          message: AppStrings.pushPermissionDenied,
        );
      }
    }
    await _repository.updatePushEnabled(enabled);
    return true;
  }
}

final pushPreferencesServiceProvider = Provider<PushPreferencesService>((ref) {
  return PushPreferencesService(ref.watch(profileRepositoryProvider));
});
