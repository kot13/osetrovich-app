class Banner {
  const Banner({
    required this.id,
    required this.imageUrl,
    required this.sortOrder,
    this.linkUrl,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      sortOrder: json['sortOrder'] as int,
      linkUrl: json['linkUrl'] as String?,
    );
  }

  final String id;
  final String imageUrl;
  final String? linkUrl;
  final int sortOrder;
}
