enum BannerLinkType {
  none,
  external,
  promotion,
  news,
  product;

  static BannerLinkType fromJson(String value) {
    return BannerLinkType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BannerLinkType.none,
    );
  }

  String toJson() => name;
}

class BannerLink {
  const BannerLink({required this.type, this.url, this.targetId});

  factory BannerLink.fromJson(Map<String, dynamic> json) {
    return BannerLink(
      type: BannerLinkType.fromJson(json['type'] as String? ?? 'none'),
      url: json['url'] as String?,
      targetId: json['targetId'] as String?,
    );
  }

  factory BannerLink.none() => const BannerLink(type: BannerLinkType.none);

  final BannerLinkType type;
  final String? url;
  final String? targetId;

  Map<String, dynamic> toJson() => {
    'type': type.toJson(),
    if (url != null) 'url': url,
    if (targetId != null) 'targetId': targetId,
  };
}

class Banner {
  const Banner({
    required this.id,
    required this.imageUrl,
    required this.sortOrder,
    required this.link,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    final linkJson = json['link'];
    return Banner(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      sortOrder: json['sortOrder'] as int,
      link:
          linkJson is Map<String, dynamic>
              ? BannerLink.fromJson(linkJson)
              : BannerLink.none(),
    );
  }

  final String id;
  final String imageUrl;
  final BannerLink link;
  final int sortOrder;
}
