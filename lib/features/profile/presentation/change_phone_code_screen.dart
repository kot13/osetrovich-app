import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/verification_code_field.dart';
import 'package:osetrovich/features/profile/domain/change_phone_notifier.dart';

class ChangePhoneCodeScreen extends ConsumerStatefulWidget {
  const ChangePhoneCodeScreen({super.key});

  @override
  ConsumerState<ChangePhoneCodeScreen> createState() =>
      _ChangePhoneCodeScreenState();
}

class _ChangePhoneCodeScreenState extends ConsumerState<ChangePhoneCodeScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePhoneProvider);
    final code = _controller.text;
    final isComplete = code.length == 6;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.smsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VerificationCodeField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed:
                  state.canResend
                      ? () =>
                          ref.read(changePhoneProvider.notifier).resendCode()
                      : null,
              child: Text(
                state.canResend
                    ? AppStrings.resendRequest
                    : '${AppStrings.resendInSeconds} ${state.resendSecondsRemaining} с',
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed:
                  !isComplete || state.isLoading
                      ? null
                      : () async {
                        final ok = await ref
                            .read(changePhoneProvider.notifier)
                            .verifyCode(code);
                        if (ok && context.mounted) {
                          context.pop();
                          context.pop();
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
