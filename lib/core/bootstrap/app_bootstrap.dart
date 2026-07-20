import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/analytics/analytics_providers.dart';
import 'package:osetrovich/core/analytics/analytics_user_id.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/catalog/domain/categories_provider.dart';
import 'package:osetrovich/features/notifications/data/notifications_cache_migration.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(authSessionProvider.notifier).restoreSession();
  await runNotificationsCacheMigration(ref);
  await ref.read(categoriesProvider.future);

  final session = ref.read(authSessionProvider);
  final analytics = ref.read(analyticsServiceProvider);
  if (session != null) {
    analytics.setUserId(analyticsUserIdFromPhone(session.phone));
  }
  analytics.reportAppLaunch();
});
