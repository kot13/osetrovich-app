import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/push/push_providers.dart';
import 'package:osetrovich/core/push/push_service.dart';
import 'package:osetrovich/features/profile/data/profile_repository.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';
import 'package:permission_handler/permission_handler.dart';

class PushPreferencesService {
  PushPreferencesService(this._repository, this._pushService);

  final ProfileRepository _repository;
  final PushService _pushService;

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
    await _pushService.syncPushEnabled(enabled);
    return true;
  }
}

final pushPreferencesServiceProvider = Provider<PushPreferencesService>((ref) {
  return PushPreferencesService(
    ref.watch(profileRepositoryProvider),
    ref.watch(pushServiceProvider),
  );
});
