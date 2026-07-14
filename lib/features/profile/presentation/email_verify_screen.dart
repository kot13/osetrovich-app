import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/profile/domain/email_validator.dart';
import 'package:osetrovich/features/profile/domain/email_verify_notifier.dart';

class EmailVerifyScreen extends ConsumerStatefulWidget {
  const EmailVerifyScreen({super.key});

  @override
  ConsumerState<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends ConsumerState<EmailVerifyScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailVerifyProvider);
    final email = _controller.text.trim();
    final isValid = isValidEmail(email);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.newEmailTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: AppStrings.profileEmail,
                border: OutlineInputBorder(),
              ),
              onChanged:
                  (value) =>
                      ref.read(emailVerifyProvider.notifier).updateEmail(value),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed:
                  !isValid || state.isLoading
                      ? null
                      : () async {
                        ref
                            .read(emailVerifyProvider.notifier)
                            .updateEmail(email);
                        final ok =
                            await ref
                                .read(emailVerifyProvider.notifier)
                                .requestCode();
                        if (ok && context.mounted) {
                          context.push('/profile/email/code');
                        }
                      },
              child:
                  state.isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text(AppStrings.continueButton),
            ),
          ],
        ),
      ),
    );
  }
}
