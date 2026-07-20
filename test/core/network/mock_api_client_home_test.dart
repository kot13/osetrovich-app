import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/home/domain/banner.dart';

const _testPhone = '+79001234567';
const _testAddress = 'г. Санкт-Петербург, ул. Тестовая, 1';

Future<CurrentOrder> _createOrderForRating(MockApiClient client) async {
  await client.verifySmsCode(_testPhone, MockApiClient.validCode);
  final created = await client.createOrder(
    const CreateOrderRequest(
      items: [OrderLineInput(id: 1000, quantity: 1)],
      deliveryAddress: _testAddress,
    ),
  );
  client.completeOrderForRating(created.id);
  final order = await client.getCurrentOrder();
  expect(order, isNotNull);
  return order!;
}

void main() {
  late MockApiClient client;

  setUp(() {
    client = MockApiClient();
  });

  test('getHomeBanners returns banners with link schema', () async {
    final banners = await client.getHomeBanners();
    expect(banners.length, greaterThanOrEqualTo(3));
    expect(banners.first.imageUrl, isNotEmpty);
    expect(banners.any((b) => b.link.type == BannerLinkType.external), isTrue);
    expect(banners.any((b) => b.link.type == BannerLinkType.product), isTrue);
  });

  test('getWeeklyProducts returns product summaries', () async {
    final products = await client.getWeeklyProducts();
    expect(products.length, greaterThanOrEqualTo(6));
    expect(products.first.id, greaterThan(0));
  });

  test('getCurrentOrder returns null without profile', () async {
    expect(() => client.getCurrentOrder(), throwsA(isA<ApiException>()));
  });

  test('getCurrentOrder returns null before createOrder', () async {
    await client.verifySmsCode(_testPhone, MockApiClient.validCode);
    expect(await client.getCurrentOrder(), isNull);
  });

  test('createOrder then completeOrderForRating returns completed pending order',
      () async {
    final order = await _createOrderForRating(client);
    expect(order.status, OrderStatus.completed);
    expect(order.ratingState, OrderRatingState.pending);
    expect(order.deliveryAt, isNotNull);
  });

  test('submitOrderRating updates order', () async {
    final order = await _createOrderForRating(client);
    final updated = await client.submitOrderRating(
      order.id,
      const SubmitOrderRatingRequest(stars: 5, comment: 'Отлично'),
    );
    expect(updated.ratingState, OrderRatingState.submitted);
    expect(updated.ratingStars, 5);
  });

  test('submitOrderRating throws on duplicate', () async {
    final order = await _createOrderForRating(client);
    await client.submitOrderRating(
      order.id,
      const SubmitOrderRatingRequest(stars: 4),
    );
    expect(
      () => client.submitOrderRating(
        order.id,
        const SubmitOrderRatingRequest(stars: 3),
      ),
      throwsA(
        predicate<ApiException>((e) => e.code == 'rating_already_set'),
      ),
    );
  });

  test('skipOrderRating updates order', () async {
    final order = await _createOrderForRating(client);
    final updated = await client.skipOrderRating(order.id);
    expect(updated.ratingState, OrderRatingState.skipped);
  });

  test('skipOrderRating throws when rating period expired', () async {
    final order = await _createOrderForRating(client);
    client.expireOrderRatingPeriod(order.id);
    expect(
      () => client.skipOrderRating(order.id),
      throwsA(
        predicate<ApiException>((e) => e.code == 'rating_period_expired'),
      ),
    );
  });

  test('submitOrderRating rejects invalid stars', () async {
    final order = await _createOrderForRating(client);
    expect(
      () => client.submitOrderRating(
        order.id,
        const SubmitOrderRatingRequest(stars: 0),
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('submitOrderRating throws when rating period expired', () async {
    final order = await _createOrderForRating(client);
    client.expireOrderRatingPeriod(order.id);
    expect(
      () => client.submitOrderRating(
        order.id,
        const SubmitOrderRatingRequest(stars: 5),
      ),
      throwsA(
        predicate<ApiException>((e) => e.code == 'rating_period_expired'),
      ),
    );
  });

  test('getCurrentOrder returns null for expired unrated order', () async {
    final order = await _createOrderForRating(client);
    client.expireOrderRatingPeriod(order.id);
    expect(await client.getCurrentOrder(), isNull);
  });
}
