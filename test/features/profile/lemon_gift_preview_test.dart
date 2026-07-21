import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/profile/domain/lemon_gift_preview.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

void main() {
  group('LemonGiftPreview', () {
    test('fromJson parses gift fields', () {
      final gift = LemonGiftPreview.fromJson({
        'productId': 501,
        'name': 'Икра горбуши',
        'weightLabel': '50 г',
        'imageUrl': 'https://example.com/ikra.jpg',
      });

      expect(gift.productId, 501);
      expect(gift.name, 'Икра горбуши');
      expect(gift.weightLabel, '50 г');
      expect(gift.imageUrl, 'https://example.com/ikra.jpg');
    });
  });

  group('UserProfile lemons', () {
    test('fromJson defaults lemons to 0 and lemonGift to null', () {
      final profile = UserProfile.fromJson({
        'id': 'u1',
        'name': 'Покупатель',
        'phone': '+79001234567',
        'emailVerified': false,
        'pushEnabled': true,
        'discount': 0,
      });

      expect(profile.lemons, 0);
      expect(profile.lemonGift, isNull);
    });

    test('fromJson parses lemons and lemonGift', () {
      final profile = UserProfile.fromJson({
        'id': 'u1',
        'name': 'Покупатель',
        'phone': '+79006666666',
        'emailVerified': false,
        'pushEnabled': true,
        'discount': 5,
        'lemons': 10,
        'lemonGift': {
          'productId': 501,
          'name': 'Икра горбуши',
          'weightLabel': '50 г',
        },
      });

      expect(profile.lemons, 10);
      expect(profile.lemonGift?.productId, 501);
    });
  });
}
