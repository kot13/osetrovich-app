import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:osetrovich/core/deeplink/deeplink_resolver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('DeepLinkResolver integration', () {
    const resolver = DeepLinkResolver();

    test('maps home deeplink', () {
      expect(resolver.resolve('osetrovich://home').path, '/home');
    });

    test('maps catalog deeplink with all categories', () {
      final target = resolver.resolve('osetrovich://catalog');
      expect(target.path, '/catalog');
      expect(target.categoryId, 0);
    });

    test('maps product deeplink', () {
      expect(
        resolver.resolve('osetrovich://catalog/product/1000').path,
        '/catalog/product/1000',
      );
    });
  });
}
