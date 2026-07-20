import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/features/notifications/domain/notifications_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

const notificationsCacheVersion = 2;
const _cacheVersionKey = 'notifications_cache_version';

Future<void> runNotificationsCacheMigration(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getInt(_cacheVersionKey) ?? 0;
  if (stored >= notificationsCacheVersion) {
    return;
  }

  ref.invalidate(notificationsNotifierProvider);
  ref.invalidate(unreadCountNotifierProvider);
  await prefs.setInt(_cacheVersionKey, notificationsCacheVersion);
}
