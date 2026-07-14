import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/widgets/empty_state.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';
import 'package:osetrovich/features/profile/domain/push_preferences_service.dart';
import 'package:osetrovich/features/profile/presentation/widgets/legal_support_section.dart';
import 'package:osetrovich/features/profile/presentation/widgets/profile_field_tile.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isSavingName = false;
  String? _pushError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final profileAsync = ref.watch(profileNotifierProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.tabProfile)),
        body: ListView(
          children: [
            EmptyState(
              message: AppStrings.profileAuthRequired,
              actionLabel: AppStrings.signIn,
              onAction: () => context.push('/auth/phone'),
            ),
            const LegalSupportSection(),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabProfile)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.toString()),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed:
                        () =>
                            ref
                                .read(profileNotifierProvider.notifier)
                                .refresh(),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_nameController.text.isEmpty) {
            _nameController.text = profile.name;
          }

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.profileName,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon:
                          _isSavingName
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save),
                      onPressed:
                          _isSavingName
                              ? null
                              : () async {
                                setState(() => _isSavingName = true);
                                try {
                                  await ref
                                      .read(profileNotifierProvider.notifier)
                                      .updateName(_nameController.text.trim());
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSavingName = false);
                                  }
                                }
                              },
                    ),
                  ),
                ),
              ),
              ProfileFieldTile(
                label: AppStrings.profileEmail,
                value: profile.email ?? AppStrings.changeEmail,
                subtitle:
                    profile.email == null
                        ? null
                        : profile.emailVerified
                        ? AppStrings.emailVerified
                        : AppStrings.emailNotVerified,
                onTap: () => context.push('/profile/email'),
              ),
              ProfileFieldTile(
                label: AppStrings.profilePhone,
                value: profile.phone,
                onTap: () => context.push('/profile/change-phone'),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  AppStrings.securitySection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SwitchListTile(
                title: const Text(AppStrings.pushNotifications),
                subtitle: _pushError != null ? Text(_pushError!) : null,
                value: profile.pushEnabled,
                onChanged: (value) async {
                  setState(() => _pushError = null);
                  try {
                    await ref
                        .read(pushPreferencesServiceProvider)
                        .updatePushEnabled(value);
                    await ref.read(profileNotifierProvider.notifier).refresh();
                  } on ApiException catch (e) {
                    setState(() => _pushError = e.message);
                  } catch (_) {
                    setState(
                      () => _pushError = AppStrings.pushPermissionDenied,
                    );
                  }
                },
              ),
              if (_pushError == AppStrings.pushPermissionDenied)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: openAppSettings,
                    child: const Text(AppStrings.openSettings),
                  ),
                ),
              const LegalSupportSection(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.dark,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _logout(context),
                  child: const Text(AppStrings.logout),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await ref.read(authRepositoryProvider).logout();
    await ref.read(authSessionProvider.notifier).clearSession();
    ref.read(profileNotifierProvider.notifier).clear();
  }
}
