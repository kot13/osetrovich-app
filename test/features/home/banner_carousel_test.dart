import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/home/domain/banner.dart' as home;
import 'package:osetrovich/features/home/presentation/banner_carousel.dart';

void main() {
  final banners = [
    const home.Banner(id: '1', imageUrl: '', sortOrder: 0),
    const home.Banner(id: '2', imageUrl: '', sortOrder: 1),
    const home.Banner(id: '3', imageUrl: '', sortOrder: 2),
  ];

  testWidgets('banner carousel shows three banners in loop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: BannerCarousel(banners: banners))),
    );

    expect(find.text('Баннер 1'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Баннер 2'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Баннер 3'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Баннер 1'), findsOneWidget);
  });

  testWidgets('banner carousel auto-scrolls every 5 seconds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: BannerCarousel(banners: banners))),
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
      MaterialApp(home: Scaffold(body: BannerCarousel(banners: banners))),
    );

    final controller =
        tester.widget<PageView>(find.byType(PageView)).controller;
    expect(controller!.viewportFraction, lessThan(1.0));
  });
}
