import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/notifications/presentation/notification_navigation.dart';

void main() {
  group('notificationsListPathForLocation', () {
    test('resolves home branch', () {
      expect(notificationsListPathForLocation('/home'), '/home/notifications');
      expect(
        notificationsListPathForLocation('/home/notifications/1'),
        '/home/notifications',
      );
    });

    test('resolves catalog branch', () {
      expect(
        notificationsListPathForLocation('/catalog'),
        '/catalog/notifications',
      );
      expect(
        notificationsListPathForLocation('/catalog/product/42'),
        '/catalog/notifications',
      );
    });

    test('resolves promotions branch', () {
      expect(
        notificationsListPathForLocation('/promotions'),
        '/promotions/notifications',
      );
      expect(
        notificationsListPathForLocation('/promotions/article/a1'),
        '/promotions/notifications',
      );
    });

    test('resolves cart branch', () {
      expect(notificationsListPathForLocation('/cart'), '/cart/notifications');
    });

    test('resolves profile branch', () {
      expect(
        notificationsListPathForLocation('/profile'),
        '/profile/notifications',
      );
    });
  });
}
