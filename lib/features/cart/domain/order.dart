enum OrderStatus { pending }

OrderStatus orderStatusFromJson(String value) {
  return switch (value) {
    'pending' => OrderStatus.pending,
    _ => OrderStatus.pending,
  };
}

String orderStatusToJson(OrderStatus status) {
  return switch (status) {
    OrderStatus.pending => 'pending',
  };
}

class OrderLineInput {
  const OrderLineInput({required this.productId, required this.quantity});

  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };
}

class CreateOrderRequest {
  const CreateOrderRequest({
    required this.items,
    required this.deliveryAddress,
    this.comment,
  });

  final List<OrderLineInput> items;
  final String deliveryAddress;
  final String? comment;

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
    'deliveryAddress': deliveryAddress,
    if (comment != null && comment!.isNotEmpty) 'comment': comment,
  };
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.weightLabel,
    required this.priceRub,
    required this.quantity,
    required this.lineTotalRub,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      productId: json['productId'] as String,
      name: json['name'] as String,
      weightLabel: json['weightLabel'] as String,
      priceRub: json['priceRub'] as int,
      quantity: json['quantity'] as int,
      lineTotalRub: json['lineTotalRub'] as int,
    );
  }

  final String productId;
  final String name;
  final String weightLabel;
  final int priceRub;
  final int quantity;
  final int lineTotalRub;
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.itemsSubtotalRub,
    required this.deliveryFeeRub,
    required this.totalRub,
    required this.deliveryAddress,
    required this.status,
    required this.createdAt,
    this.comment,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      items:
          (json['items'] as List<dynamic>)
              .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
              .toList(),
      itemsSubtotalRub: json['itemsSubtotalRub'] as int,
      deliveryFeeRub: json['deliveryFeeRub'] as int,
      totalRub: json['totalRub'] as int,
      deliveryAddress: json['deliveryAddress'] as String,
      comment: json['comment'] as String?,
      status: orderStatusFromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String orderNumber;
  final List<OrderLine> items;
  final int itemsSubtotalRub;
  final int deliveryFeeRub;
  final int totalRub;
  final String deliveryAddress;
  final String? comment;
  final OrderStatus status;
  final DateTime createdAt;
}
