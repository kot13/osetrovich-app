import 'package:osetrovich/features/profile/domain/loyalty_status.dart';
import 'package:osetrovich/features/profile/domain/lemon_gift_preview.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.emailVerified,
    required this.pushEnabled,
    required this.discount,
    this.lemons = 0,
    this.email,
    this.loyaltyStatus,
    this.card,
    this.lemonGift,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final lemonGiftJson = json['lemonGift'];
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      emailVerified: json['emailVerified'] as bool,
      pushEnabled: json['pushEnabled'] as bool,
      loyaltyStatus: loyaltyStatusFromJson(json['loyaltyStatus'] as String?),
      discount: json['discount'] as int? ?? 0,
      card: json['card'] as String?,
      lemons: json['lemons'] as int? ?? 0,
      lemonGift:
          lemonGiftJson == null
              ? null
              : LemonGiftPreview.fromJson(
                lemonGiftJson as Map<String, dynamic>,
              ),
    );
  }

  final String id;
  final String name;
  final String phone;
  final String? email;
  final bool emailVerified;
  final bool pushEnabled;
  final LoyaltyStatus? loyaltyStatus;
  final int discount;
  final String? card;
  final int lemons;
  final LemonGiftPreview? lemonGift;

  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    bool? emailVerified,
    bool? pushEnabled,
    LoyaltyStatus? loyaltyStatus,
    int? discount,
    String? card,
    int? lemons,
    LemonGiftPreview? lemonGift,
    bool clearEmail = false,
    bool clearLoyaltyStatus = false,
    bool clearCard = false,
    bool clearLemonGift = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: clearEmail ? null : (email ?? this.email),
      emailVerified: emailVerified ?? this.emailVerified,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      loyaltyStatus:
          clearLoyaltyStatus ? null : (loyaltyStatus ?? this.loyaltyStatus),
      discount: discount ?? this.discount,
      card: clearCard ? null : (card ?? this.card),
      lemons: lemons ?? this.lemons,
      lemonGift: clearLemonGift ? null : (lemonGift ?? this.lemonGift),
    );
  }
}

class ProfilePreferences {
  const ProfilePreferences({required this.pushEnabled});

  factory ProfilePreferences.fromJson(Map<String, dynamic> json) {
    return ProfilePreferences(pushEnabled: json['pushEnabled'] as bool);
  }

  final bool pushEnabled;
}
