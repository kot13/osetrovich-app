import 'package:osetrovich/features/profile/domain/loyalty_status.dart';
import 'package:osetrovich/features/profile/domain/loyalty_status_label.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

class HomeLoyaltyStatusUiModel {
  const HomeLoyaltyStatusUiModel({
    required this.statusLabel,
    required this.showsMaximumLevelBadge,
    required this.discountAppliesToAllPurchases,
    this.discountPercent,
    this.cardNumber,
  });

  final String statusLabel;
  final bool showsMaximumLevelBadge;
  final bool discountAppliesToAllPurchases;
  final int? discountPercent;
  final String? cardNumber;

  bool get hasDiscount => discountPercent != null && discountPercent! > 0;
}

bool loyaltyShowsMaximumLevelBadge(LoyaltyStatus status) {
  return status == LoyaltyStatus.superVip || status == LoyaltyStatus.vip;
}

bool loyaltyDiscountAppliesToAllPurchases(LoyaltyStatus status) {
  return loyaltyShowsMaximumLevelBadge(status);
}

String formatLoyaltyCardNumber(String cardNumber) {
  final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return cardNumber;
  }

  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && index % 4 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

HomeLoyaltyStatusUiModel buildHomeLoyaltyStatusUiModel(UserProfile profile) {
  final status = profile.loyaltyStatus;
  if (status == null) {
    throw StateError('loyaltyStatus is required to build loyalty UI model');
  }

  return HomeLoyaltyStatusUiModel(
    statusLabel: loyaltyStatusLabel(status),
    showsMaximumLevelBadge: loyaltyShowsMaximumLevelBadge(status),
    discountAppliesToAllPurchases: loyaltyDiscountAppliesToAllPurchases(status),
    discountPercent: profile.discount > 0 ? profile.discount : null,
    cardNumber:
        profile.card != null && profile.card!.isNotEmpty ? profile.card : null,
  );
}
