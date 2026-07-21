import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/home/domain/home_loyalty_status_ui_model.dart';
import 'package:osetrovich/features/profile/domain/loyalty_status.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

void main() {
  test(
    'buildHomeLoyaltyStatusUiModel includes discount and card when present',
    () {
      final model = buildHomeLoyaltyStatusUiModel(
        const UserProfile(
          id: 'u1',
          name: 'Покупатель',
          phone: '+79001111111',
          emailVerified: false,
          pushEnabled: true,
          discount: 10,
          loyaltyStatus: LoyaltyStatus.premium,
          card: '1234567890',
        ),
      );

      expect(model.statusLabel, 'Premium');
      expect(model.discountPercent, 10);
      expect(model.cardNumber, '1234567890');
      expect(model.showsMaximumLevelBadge, isFalse);
      expect(model.discountAppliesToAllPurchases, isFalse);
    },
  );

  test('buildHomeLoyaltyStatusUiModel sets vip flags', () {
    final model = buildHomeLoyaltyStatusUiModel(
      const UserProfile(
        id: 'u3',
        name: 'Покупатель',
        phone: '+79001111111',
        emailVerified: false,
        pushEnabled: true,
        discount: 25,
        loyaltyStatus: LoyaltyStatus.superVip,
      ),
    );

    expect(model.showsMaximumLevelBadge, isTrue);
    expect(model.discountAppliesToAllPurchases, isTrue);
  });

  test('formatLoyaltyCardNumber groups digits by four', () {
    expect(formatLoyaltyCardNumber('1234567890123456'), '1234 5678 9012 3456');
  });

  test('buildHomeLoyaltyStatusUiModel hides discount when zero', () {
    final model = buildHomeLoyaltyStatusUiModel(
      const UserProfile(
        id: 'u2',
        name: 'Покупатель',
        phone: '+79002222222',
        emailVerified: false,
        pushEnabled: true,
        discount: 0,
        loyaltyStatus: LoyaltyStatus.vip,
      ),
    );

    expect(model.statusLabel, 'VIP');
    expect(model.discountPercent, isNull);
    expect(model.cardNumber, isNull);
  });

  test('buildHomeLoyaltyStatusUiModel maps all status labels', () {
    final statuses = <LoyaltyStatus, String>{
      LoyaltyStatus.superVip: 'Super VIP',
      LoyaltyStatus.vip: 'VIP',
      LoyaltyStatus.elite: 'Elite',
      LoyaltyStatus.premium: 'Premium',
      LoyaltyStatus.friend: 'Друг',
      LoyaltyStatus.clubMember: 'Участник клуба',
    };

    for (final entry in statuses.entries) {
      final model = buildHomeLoyaltyStatusUiModel(
        UserProfile(
          id: 'u',
          name: 'Покупатель',
          phone: '+79001234567',
          emailVerified: false,
          pushEnabled: true,
          discount: 0,
          loyaltyStatus: entry.key,
        ),
      );

      expect(model.statusLabel, entry.value);
    }
  });
}
