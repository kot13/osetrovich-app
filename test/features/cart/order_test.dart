import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/cart/domain/order.dart';

void main() {
  group('CreateOrderRequest.toJson', () {
    test('uses integer id in items', () {
      final json =
          const CreateOrderRequest(
            items: [OrderLineInput(id: 1000, quantity: 2)],
            deliveryAddress: 'г. Санкт-Петербург, ул. Тестовая, 1',
          ).toJson();

      expect(json['items'], [
        {'id': 1000, 'quantity': 2},
      ]);
      expect(json.containsKey('productId'), isFalse);
    });

    test('omits empty apartment and comment', () {
      final json =
          const CreateOrderRequest(
            items: [OrderLineInput(id: 1000, quantity: 1)],
            deliveryAddress: 'адрес',
            apartment: '   ',
            comment: '',
          ).toJson();

      expect(json.containsKey('apartment'), isFalse);
      expect(json.containsKey('comment'), isFalse);
    });

    test('includes trimmed apartment and comment when set', () {
      final json =
          const CreateOrderRequest(
            items: [OrderLineInput(id: 1000, quantity: 1)],
            deliveryAddress: 'адрес',
            apartment: '42',
            comment: 'звонить',
          ).toJson();

      expect(json['apartment'], '42');
      expect(json['comment'], 'звонить');
    });

    test('omits lat and lng when null', () {
      final json =
          const CreateOrderRequest(
            items: [OrderLineInput(id: 1000, quantity: 1)],
            deliveryAddress: 'адрес',
          ).toJson();

      expect(json.containsKey('lat'), isFalse);
      expect(json.containsKey('lng'), isFalse);
    });
  });

  group('OrderLine.fromJson', () {
    test('parses integer id', () {
      final line = OrderLine.fromJson({
        'id': 1000,
        'name': 'Сёмга',
        'weightLabel': '500 г',
        'priceRub': 890,
        'quantity': 1,
        'lineTotalRub': 890,
      });

      expect(line.id, 1000);
    });
  });
}
