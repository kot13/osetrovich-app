import 'package:osetrovich/features/profile/domain/loyalty_status.dart';

String loyaltyStatusLabel(LoyaltyStatus status) {
  return switch (status) {
    LoyaltyStatus.superVip => 'Super VIP',
    LoyaltyStatus.vip => 'VIP',
    LoyaltyStatus.elite => 'Elite',
    LoyaltyStatus.premium => 'Premium',
    LoyaltyStatus.friend => 'Друг',
    LoyaltyStatus.clubMember => 'Участник клуба',
  };
}
