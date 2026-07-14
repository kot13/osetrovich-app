import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_image_gallery.dart';

void main() {
  testWidgets('single image gallery has no page dots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ProductImageGallery(imageUrls: ['https://example.com/1.jpg']),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('multi image gallery shows page view', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ProductImageGallery(
            imageUrls: [
              'https://example.com/1.jpg',
              'https://example.com/2.jpg',
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PageView), findsOneWidget);
  });
}
