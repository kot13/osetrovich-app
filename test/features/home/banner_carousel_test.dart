import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/home/domain/banner.dart' as home;
import 'package:osetrovich/features/home/presentation/banner_carousel.dart';

void main() {
  final bannersWithImages = [
    home.Banner(
      id: '1',
      imageUrl: 'https://example.com/b1.jpg',
      sortOrder: 0,
      link: home.BannerLink.none(),
    ),
    home.Banner(
      id: '2',
      imageUrl: 'https://example.com/b2.jpg',
      sortOrder: 1,
      link: const home.BannerLink(
        type: home.BannerLinkType.product,
        targetId: 'p1',
      ),
    ),
    home.Banner(
      id: '3',
      imageUrl: 'https://example.com/b3.jpg',
      sortOrder: 2,
      link: home.BannerLink.none(),
    ),
  ];

  final placeholderBanners = [
    home.Banner(
      id: '1',
      imageUrl: '',
      sortOrder: 0,
      link: home.BannerLink.none(),
    ),
    home.Banner(
      id: '2',
      imageUrl: '',
      sortOrder: 1,
      link: home.BannerLink.none(),
    ),
    home.Banner(
      id: '3',
      imageUrl: '',
      sortOrder: 2,
      link: home.BannerLink.none(),
    ),
  ];

  testWidgets('banner carousel shows CachedNetworkImage when imageUrl set', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BannerCarousel(banners: bannersWithImages)),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsWidgets);
  });

  testWidgets('banner carousel shows placeholder text when imageUrl empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BannerCarousel(banners: placeholderBanners)),
      ),
    );

    expect(find.text('Баннер 1'), findsOneWidget);
  });

  testWidgets('banner carousel loops through banners', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BannerCarousel(banners: placeholderBanners)),
      ),
    );

    expect(find.text('Баннер 1'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Баннер 2'), findsOneWidget);
  });

  testWidgets('banner carousel auto-scrolls every 5 seconds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BannerCarousel(banners: placeholderBanners)),
      ),
    );

    expect(find.text('Баннер 1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Баннер 2'), findsOneWidget);
  });

  testWidgets('banner carousel uses peek viewport for multiple banners', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BannerCarousel(banners: placeholderBanners)),
      ),
    );

    final controller =
        tester.widget<PageView>(find.byType(PageView)).controller;
    expect(controller!.viewportFraction, lessThan(1.0));
  });

  testWidgets('tappable banner has InkWell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BannerCarousel(banners: bannersWithImages)),
      ),
    );

    expect(find.byType(InkWell), findsWidgets);
  });
}
