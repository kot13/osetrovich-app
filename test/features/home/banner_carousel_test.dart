import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/widgets/safe_cached_network_image.dart';
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

  testWidgets('banner carousel shows SafeCachedNetworkImage when imageUrl set', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BannerCarousel(banners: bannersWithImages)),
      ),
    );

    expect(find.byType(SafeCachedNetworkImage), findsWidgets);
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

  testWidgets('banner carousel keeps page index bounded during long auto-scroll', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BannerCarousel(banners: placeholderBanners)),
      ),
    );
    await tester.pump();

    final controller =
        tester.widget<PageView>(find.byType(PageView)).controller!;

    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pumpAndSettle();

    expect(controller.page, lessThan(placeholderBanners.length));
    expect(controller.page, greaterThanOrEqualTo(0));
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

  testWidgets('banner keeps 20:9 aspect ratio on wide screen', (tester) async {
    const screenWidth = 800.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: screenWidth,
            child: BannerCarousel(banners: placeholderBanners),
          ),
        ),
      ),
    );

    final aspectRatios = tester.widgetList<AspectRatio>(
      find.descendant(
        of: find.byType(BannerCarousel),
        matching: find.byType(AspectRatio),
      ),
    );
    expect(aspectRatios, isNotEmpty);
    expect(aspectRatios.first.aspectRatio, kBannerAspectRatio);

    final carouselBox = tester.renderObject<RenderBox>(
      find.byType(BannerCarousel),
    );
    final slideWidth = screenWidth * 0.88 - 12;
    expect(
      carouselBox.size.height,
      closeTo(slideWidth / kBannerAspectRatio, 0.01),
    );
  });

  test('bannerCarouselHeightForWidth scales with width not fixed height', () {
    final narrow = bannerCarouselHeightForWidth(375, 3);
    final wide = bannerCarouselHeightForWidth(800, 3);

    expect(wide, greaterThan(narrow));
    expect(wide / 800, closeTo(narrow / 375, 0.01));
  });
}
