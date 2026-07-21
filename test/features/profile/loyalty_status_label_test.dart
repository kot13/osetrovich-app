import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/profile/domain/loyalty_status.dart';
import 'package:osetrovich/features/profile/domain/loyalty_status_label.dart';

void main() {
  test('loyaltyStatusFromJson maps all API values', () {
    expect(loyaltyStatusFromJson('super_vip'), LoyaltyStatus.superVip);
    expect(loyaltyStatusFromJson('vip'), LoyaltyStatus.vip);
    expect(loyaltyStatusFromJson('elite'), LoyaltyStatus.elite);
    expect(loyaltyStatusFromJson('premium'), LoyaltyStatus.premium);
    expect(loyaltyStatusFromJson('friend'), LoyaltyStatus.friend);
    expect(loyaltyStatusFromJson('club_member'), LoyaltyStatus.clubMember);
    expect(loyaltyStatusFromJson(null), isNull);
    expect(loyaltyStatusFromJson('unknown'), isNull);
  });

  test('loyaltyStatusLabel returns display names', () {
    expect(loyaltyStatusLabel(LoyaltyStatus.superVip), 'Super VIP');
    expect(loyaltyStatusLabel(LoyaltyStatus.vip), 'VIP');
    expect(loyaltyStatusLabel(LoyaltyStatus.elite), 'Elite');
    expect(loyaltyStatusLabel(LoyaltyStatus.premium), 'Premium');
    expect(loyaltyStatusLabel(LoyaltyStatus.friend), 'Друг');
    expect(loyaltyStatusLabel(LoyaltyStatus.clubMember), 'Участник клуба');
  });

  test('loyaltyStatusToJson round-trips', () {
    for (final status in LoyaltyStatus.values) {
      expect(loyaltyStatusFromJson(loyaltyStatusToJson(status)), status);
    }
  });
}
