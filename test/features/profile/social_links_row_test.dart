import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/profile/presentation/widgets/social_links_row.dart';

void main() {
  testWidgets('social links row shows two icon buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SocialLinksRow())),
    );

    expect(find.byType(IconButton), findsNWidgets(2));
  });
}
