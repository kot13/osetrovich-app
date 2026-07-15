import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/catalog/data/catalog_repository.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:osetrovich/features/home/domain/repeat_order.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient api;
  late CatalogRepository catalog;
  late ProviderContainer container;
  late CartNotifier cart;

  setUp(() {
    api = _MockApiClient();
    catalog = CatalogRepository(api);
    container = ProviderContainer();
    cart = container.read(cartNotifierProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  CurrentOrder orderWith(List<OrderLine> items) {
    return CurrentOrder(
      id: 'ord-1',
      orderNumber: 'ORD-1',
      items: items,
      itemsSubtotalRub: 1000,
      deliveryFeeRub: 0,
      totalRub: 1000,
      deliveryAddress: 'адрес',
      status: OrderStatus.completed,
      createdAt: DateTime.utc(2026, 7, 15),
      ratingState: OrderRatingState.skipped,
    );
  }

  test('adds all available lines to cart', () async {
    when(() => api.getProductById('p1')).thenAnswer(
      (_) async => const ProductDetail(
        id: 'p1',
        name: 'Товар 1',
        weightLabel: '500 г',
        priceRub: 100,
        imageUrls: ['https://example.com/1.jpg'],
        description: 'desc',
        categoryIds: ['fish'],
      ),
    );

    final result = await repeatOrderToCart(
      order: orderWith(const [
        OrderLine(
          productId: 'p1',
          name: 'Товар 1',
          weightLabel: '500 г',
          priceRub: 100,
          quantity: 2,
          lineTotalRub: 200,
        ),
      ]),
      cart: cart,
      catalog: catalog,
    );

    expect(result.addedLineCount, 1);
    expect(cart.quantityOf('p1'), 2);
  });

  test('merges quantities with existing cart items', () async {
    when(() => api.getProductById('p1')).thenAnswer(
      (_) async => const ProductDetail(
        id: 'p1',
        name: 'Товар 1',
        weightLabel: '500 г',
        priceRub: 100,
        imageUrls: ['https://example.com/1.jpg'],
        description: 'desc',
        categoryIds: ['fish'],
      ),
    );
    cart.add('p1');

    await repeatOrderToCart(
      order: orderWith(const [
        OrderLine(
          productId: 'p1',
          name: 'Товар 1',
          weightLabel: '500 г',
          priceRub: 100,
          quantity: 2,
          lineTotalRub: 200,
        ),
      ]),
      cart: cart,
      catalog: catalog,
    );

    expect(cart.quantityOf('p1'), 3);
  });

  test('skips unavailable products', () async {
    when(() => api.getProductById('missing')).thenThrow(
      ApiException(code: 'NOT_FOUND', message: 'Товар не найден'),
    );

    final result = await repeatOrderToCart(
      order: orderWith(const [
        OrderLine(
          productId: 'missing',
          name: 'Нет',
          weightLabel: '500 г',
          priceRub: 100,
          quantity: 1,
          lineTotalRub: 100,
        ),
      ]),
      cart: cart,
      catalog: catalog,
    );

    expect(result.addedLineCount, 0);
    expect(result.skippedProductIds, ['missing']);
  });
}
