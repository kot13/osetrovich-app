import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/auth/domain/phone_validator.dart';
import 'package:osetrovich/features/profile/domain/change_phone_notifier.dart';

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _controller = TextEditingController();
  final _maskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePhoneProvider);
    final phone = toE164RussianPhone(_controller.text);
    final isValid = isValidRussianPhone(phone);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.newPhoneTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [_maskFormatter],
              decoration: const InputDecoration(
                labelText: AppStrings.phoneHint,
                border: OutlineInputBorder(),
              ),
              onChanged:
                  (value) => ref
                      .read(changePhoneProvider.notifier)
                      .updatePhone(toE164RussianPhone(value)),
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
                            .read(changePhoneProvider.notifier)
                            .updatePhone(phone);
                        final ok =
                            await ref
                                .read(changePhoneProvider.notifier)
                                .requestCode();
                        if (ok && context.mounted) {
                          context.push('/profile/change-phone/code');
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
