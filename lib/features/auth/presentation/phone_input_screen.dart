import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/auth/domain/phone_validator.dart';
import 'package:osetrovich/features/auth/domain/sms_auth_notifier.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _maskFormatter = MaskTextInputFormatter.eager(
    mask: '+7 (###) ###-##-##',
    filter: {'#': RegExp(r'[0-9]')},
    initialText: '+7',
  );

  @override
  void initState() {
    super.initState();
    _controller.text = _maskFormatter.getMaskedText();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(smsAuthProvider);
    final phone = toE164RussianPhone(_controller.text);
    final isValid = isValidRussianPhone(phone);
    final from = GoRouter.maybeOf(context)?.state.uri.queryParameters['from'];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.authTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [_maskFormatter],
              decoration: const InputDecoration(
                labelText: AppStrings.phoneHint,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref
                    .read(smsAuthProvider.notifier)
                    .updatePhone(toE164RussianPhone(value));
              },
            ),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                authState.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed:
                  !isValid || authState.isLoading
                      ? null
                      : () async {
                        ref.read(smsAuthProvider.notifier).updatePhone(phone);
                        final ok =
                            await ref
                                .read(smsAuthProvider.notifier)
                                .submitPhone();
                        if (ok && context.mounted) {
                          final query = from != null ? '?from=$from' : '';
                          context.push('/auth/sms$query');
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
          ],
        ),
      ),
    );
  }
}
