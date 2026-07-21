class LemonGiftPreview {
  const LemonGiftPreview({
    required this.productId,
    required this.name,
    required this.weightLabel,
    this.imageUrl,
  });

  factory LemonGiftPreview.fromJson(Map<String, dynamic> json) {
    return LemonGiftPreview(
      productId: json['productId'] as int,
      name: json['name'] as String,
      weightLabel: json['weightLabel'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final int productId;
  final String name;
  final String weightLabel;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'weightLabel': weightLabel,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}
