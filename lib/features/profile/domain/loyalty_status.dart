enum LoyaltyStatus { superVip, vip, elite, premium, friend, clubMember }

LoyaltyStatus? loyaltyStatusFromJson(String? value) {
  if (value == null) {
    return null;
  }
  return switch (value) {
    'super_vip' => LoyaltyStatus.superVip,
    'vip' => LoyaltyStatus.vip,
    'elite' => LoyaltyStatus.elite,
    'premium' => LoyaltyStatus.premium,
    'friend' => LoyaltyStatus.friend,
    'club_member' => LoyaltyStatus.clubMember,
    _ => null,
  };
}

String loyaltyStatusToJson(LoyaltyStatus status) {
  return switch (status) {
    LoyaltyStatus.superVip => 'super_vip',
    LoyaltyStatus.vip => 'vip',
    LoyaltyStatus.elite => 'elite',
    LoyaltyStatus.premium => 'premium',
    LoyaltyStatus.friend => 'friend',
    LoyaltyStatus.clubMember => 'club_member',
  };
}
