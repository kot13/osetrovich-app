import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/deeplink/deeplink_resolver.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';

void main() {
  const resolver = DeepLinkResolver();

  group('valid routes', () {
    test('home', () {
      final target = resolver.resolve('osetrovich://home');
      expect(target.path, '/home');
      expect(target.isFallback, isFalse);
    });

    test('catalog all', () {
      final target = resolver.resolve('osetrovich://catalog');
      expect(target.path, '/catalog');
      expect(target.categoryId, kAllCategoriesId);
    });

    test('catalog category', () {
      final target = resolver.resolve('osetrovich://catalog/category/200');
      expect(target.path, '/catalog');
      expect(target.categoryId, 200);
    });

    test('catalog product', () {
      final target = resolver.resolve('osetrovich://catalog/product/1000');
      expect(target.path, '/catalog/product/1000');
      expect(target.categoryId, isNull);
    });

    test('promotions list', () {
      expect(resolver.resolve('osetrovich://promotions').path, '/promotions');
    });

    test('promotions article', () {
      expect(
        resolver.resolve('osetrovich://promotions/articles/news-1').path,
        '/promotions/article/news-1',
      );
    });

    test('profile', () {
      expect(resolver.resolve('osetrovich://profile').path, '/profile');
    });

    test('notifications list', () {
      expect(
        resolver.resolve('osetrovich://notifications').path,
        '/home/notifications',
      );
    });

    test('notification detail', () {
      expect(
        resolver.resolve('osetrovich://notifications/notif-1').path,
        '/home/notifications/notif-1',
      );
    });
  });

  group('fallback', () {
    test('unknown host', () {
      final target = resolver.resolve('osetrovich://unknown');
      expect(target.path, '/home');
      expect(target.isFallback, isTrue);
    });

    test('invalid product id', () {
      final target = resolver.resolve('osetrovich://catalog/product/abc');
      expect(target.path, '/home');
      expect(target.isFallback, isTrue);
    });

    test('invalid category id', () {
      final target = resolver.resolve('osetrovich://catalog/category/abc');
      expect(target.isFallback, isTrue);
    });

    test('non osetrovich scheme', () {
      expect(resolver.resolve('https://osetrovich.ru').isFallback, isTrue);
    });
  });
}
