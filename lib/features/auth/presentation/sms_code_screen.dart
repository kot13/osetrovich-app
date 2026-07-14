import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/auth/domain/sms_auth_notifier.dart';

class SmsCodeScreen extends ConsumerStatefulWidget {
  const SmsCodeScreen({super.key});

  @override
  ConsumerState<SmsCodeScreen> createState() => _SmsCodeScreenState();
}

class _SmsCodeScreenState extends ConsumerState<SmsCodeScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(smsAuthProvider);
    final code = _controller.text;
    final isComplete = code.length == 6;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.smsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(smsAuthProvider.notifier).backToPhone();
            context.pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: AppStrings.smsHint,
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                authState.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  !isComplete || authState.isLoading
                      ? null
                      : () async {
                        final ok = await ref
                            .read(smsAuthProvider.notifier)
                            .verifyCode(code);
                        if (ok && context.mounted) {
                          context.go('/profile');
                        }
                      },
              child:
                  authState.isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text(AppStrings.continueButton),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed:
                  authState.canResend
                      ? () => ref.read(smsAuthProvider.notifier).resendCode()
                      : null,
              child: Text(
                authState.canResend
                    ? AppStrings.resendRequest
                    : '${AppStrings.resendInSeconds} ${authState.resendSecondsRemaining} с',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
