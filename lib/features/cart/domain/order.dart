enum OrderStatus {
  accepted,
  processing,
  assembly,
  delivery,
  completed,
  pending,
}

OrderStatus orderStatusFromJson(String value) {
  return switch (value) {
    'accepted' => OrderStatus.accepted,
    'processing' => OrderStatus.processing,
    'assembly' => OrderStatus.assembly,
    'delivery' => OrderStatus.delivery,
    'completed' => OrderStatus.completed,
    'pending' => OrderStatus.accepted,
    _ => OrderStatus.accepted,
  };
}

String orderStatusToJson(OrderStatus status) {
  return switch (status) {
    OrderStatus.accepted || OrderStatus.pending => 'accepted',
    OrderStatus.processing => 'processing',
    OrderStatus.assembly => 'assembly',
    OrderStatus.delivery => 'delivery',
    OrderStatus.completed => 'completed',
  };
}

enum OrderRatingState {
  notApplicable,
  pending,
  submitted,
  skipped;

  static OrderRatingState fromJson(String value) {
    return switch (value) {
      'not_applicable' => OrderRatingState.notApplicable,
      'pending' => OrderRatingState.pending,
      'submitted' => OrderRatingState.submitted,
      'skipped' => OrderRatingState.skipped,
      _ => OrderRatingState.notApplicable,
    };
  }

  String toJson() {
    return switch (this) {
      OrderRatingState.notApplicable => 'not_applicable',
      OrderRatingState.pending => 'pending',
      OrderRatingState.submitted => 'submitted',
      OrderRatingState.skipped => 'skipped',
    };
  }
}

class OrderLineInput {
  const OrderLineInput({required this.id, required this.quantity});

  final int id;
  final int quantity;

  Map<String, dynamic> toJson() => {'id': id, 'quantity': quantity};
}

class CreateOrderRequest {
  const CreateOrderRequest({
    required this.items,
    required this.deliveryAddress,
    this.apartment,
    this.lat,
    this.lng,
    this.comment,
  });

  final List<OrderLineInput> items;
  final String deliveryAddress;
  final String? apartment;
  final double? lat;
  final double? lng;
  final String? comment;

  Map<String, dynamic> toJson() {
    final trimmedApartment = apartment?.trim();
    final trimmedComment = comment?.trim();

    return {
      'items': items.map((e) => e.toJson()).toList(),
      'deliveryAddress': deliveryAddress,
      if (trimmedApartment != null && trimmedApartment.isNotEmpty)
        'apartment': trimmedApartment,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (trimmedComment != null && trimmedComment.isNotEmpty)
        'comment': trimmedComment,
    };
  }
}

class OrderLine {
  const OrderLine({
    required this.id,
    required this.name,
    required this.weightLabel,
    required this.priceRub,
    required this.quantity,
    required this.lineTotalRub,
    this.isGift = false,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      id: json['id'] as int,
      name: json['name'] as String,
      weightLabel: json['weightLabel'] as String,
      priceRub: json['priceRub'] as int,
      quantity: json['quantity'] as int,
      lineTotalRub: json['lineTotalRub'] as int,
      isGift: json['isGift'] as bool? ?? false,
    );
  }

  final int id;
  final String name;
  final String weightLabel;
  final int priceRub;
  final int quantity;
  final int lineTotalRub;
  final bool isGift;
}

DateTime? _deliveryAtFromJson(Map<String, dynamic> json) {
  final raw = json['deliveryAt'] ?? json['delivery_at'];
  if (raw is String && raw.isNotEmpty) {
    return DateTime.parse(raw);
  }
  return null;
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
    this.apartment,
    this.lat,
    this.lng,
    this.comment,
    this.deliveryAt,
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
      apartment: json['apartment'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      comment: json['comment'] as String?,
      status: orderStatusFromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      deliveryAt: _deliveryAtFromJson(json),
    );
  }

  final String id;
  final String orderNumber;
  final List<OrderLine> items;
  final int itemsSubtotalRub;
  final int deliveryFeeRub;
  final int totalRub;
  final String deliveryAddress;
  final String? apartment;
  final double? lat;
  final double? lng;
  final String? comment;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? deliveryAt;
}

class CurrentOrder extends Order {
  const CurrentOrder({
    required super.id,
    required super.orderNumber,
    required super.items,
    required super.itemsSubtotalRub,
    required super.deliveryFeeRub,
    required super.totalRub,
    required super.deliveryAddress,
    required super.status,
    required super.createdAt,
    required this.ratingState,
    super.apartment,
    super.lat,
    super.lng,
    super.comment,
    super.deliveryAt,
    this.ratingStars,
  });

  factory CurrentOrder.fromJson(Map<String, dynamic> json) {
    return CurrentOrder(
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
      apartment: json['apartment'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      comment: json['comment'] as String?,
      status: orderStatusFromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      deliveryAt: _deliveryAtFromJson(json),
      ratingState: OrderRatingState.fromJson(json['ratingState'] as String),
      ratingStars: json['ratingStars'] as int?,
    );
  }

  final OrderRatingState ratingState;
  final int? ratingStars;

  CurrentOrder copyWith({
    OrderRatingState? ratingState,
    int? ratingStars,
    bool clearRatingStars = false,
    OrderStatus? status,
    DateTime? deliveryAt,
    bool clearDeliveryAt = false,
  }) {
    return CurrentOrder(
      id: id,
      orderNumber: orderNumber,
      items: items,
      itemsSubtotalRub: itemsSubtotalRub,
      deliveryFeeRub: deliveryFeeRub,
      totalRub: totalRub,
      deliveryAddress: deliveryAddress,
      apartment: apartment,
      lat: lat,
      lng: lng,
      comment: comment,
      status: status ?? this.status,
      createdAt: createdAt,
      deliveryAt: clearDeliveryAt ? null : (deliveryAt ?? this.deliveryAt),
      ratingState: ratingState ?? this.ratingState,
      ratingStars: clearRatingStars ? null : (ratingStars ?? this.ratingStars),
    );
  }
}

class SubmitOrderRatingRequest {
  const SubmitOrderRatingRequest({required this.stars, this.comment});

  final int stars;
  final String? comment;

  Map<String, dynamic> toJson() => {
    'stars': stars,
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
  };
}
