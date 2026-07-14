import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/empty_state.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabProfile)),
      body:
          session == null
              ? EmptyState(
                message: AppStrings.profileAuthRequired,
                actionLabel: AppStrings.signIn,
                onAction: () => context.push('/auth/phone'),
              )
              : Center(
                child: Text(
                  AppStrings.signedInPlaceholder,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
    );
  }
}
