import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/sms_auth_notifier.dart';

void main() {
  test('resend timer counts down to zero', () async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    final notifier = container.read(smsAuthProvider.notifier);

    notifier.updatePhone('+79161234567');
    await notifier.submitPhone();

    var state = container.read(smsAuthProvider);
    expect(state.resendSecondsRemaining, 60);
    expect(state.canResend, isFalse);

    await Future<void>.delayed(const Duration(seconds: 2));
    state = container.read(smsAuthProvider);
    expect(state.resendSecondsRemaining, lessThan(60));
  });
}
