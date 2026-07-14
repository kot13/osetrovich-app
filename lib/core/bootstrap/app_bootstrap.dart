import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/catalog/domain/categories_provider.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(authSessionProvider.notifier).restoreSession();
  await ref.read(categoriesProvider.future);
});
