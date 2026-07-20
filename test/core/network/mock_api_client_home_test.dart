import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/home/domain/banner.dart';

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

  test('demo phone delivery returns active order', () async {
    await client.verifySmsCode(
      MockApiClient.demoPhoneDelivery,
      MockApiClient.validCode,
    );
    final order = await client.getCurrentOrder();
    expect(order, isNotNull);
    expect(order!.status, OrderStatus.delivery);
    expect(order.ratingState, OrderRatingState.notApplicable);
  });

  test('demo phone rating pending returns completed order', () async {
    await client.verifySmsCode(
      MockApiClient.demoPhoneRatingPending,
      MockApiClient.validCode,
    );
    final order = await client.getCurrentOrder();
    expect(order?.status, OrderStatus.completed);
    expect(order?.ratingState, OrderRatingState.pending);
  });

  test('submitOrderRating updates order', () async {
    await client.verifySmsCode(
      MockApiClient.demoPhoneRatingPending,
      MockApiClient.validCode,
    );
    final order = await client.getCurrentOrder();
    final updated = await client.submitOrderRating(
      order!.id,
      const SubmitOrderRatingRequest(stars: 5, comment: 'Отлично'),
    );
    expect(updated.ratingState, OrderRatingState.submitted);
    expect(updated.ratingStars, 5);
  });

  test('submitOrderRating throws 409 on duplicate', () async {
    await client.verifySmsCode(
      MockApiClient.demoPhoneRatingPending,
      MockApiClient.validCode,
    );
    final order = await client.getCurrentOrder();
    await client.submitOrderRating(
      order!.id,
      const SubmitOrderRatingRequest(stars: 4),
    );
    expect(
      () => client.submitOrderRating(
        order.id,
        const SubmitOrderRatingRequest(stars: 3),
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('skipOrderRating updates order', () async {
    await client.verifySmsCode(
      MockApiClient.demoPhoneRatingPending,
      MockApiClient.validCode,
    );
    final order = await client.getCurrentOrder();
    final updated = await client.skipOrderRating(order!.id);
    expect(updated.ratingState, OrderRatingState.skipped);
  });

  test('submitOrderRating rejects invalid stars', () async {
    await client.verifySmsCode(
      MockApiClient.demoPhoneRatingPending,
      MockApiClient.validCode,
    );
    final order = await client.getCurrentOrder();
    expect(
      () => client.submitOrderRating(
        order!.id,
        const SubmitOrderRatingRequest(stars: 0),
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
