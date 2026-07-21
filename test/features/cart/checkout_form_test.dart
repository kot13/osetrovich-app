import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/cart/presentation/widgets/checkout_form.dart';

void main() {
  testWidgets('shows apartment field between address and comment', (
    tester,
  ) async {
    final addressController = TextEditingController();
    final apartmentController = TextEditingController();
    final commentController = TextEditingController();
    addTearDown(addressController.dispose);
    addTearDown(apartmentController.dispose);
    addTearDown(commentController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckoutForm(
            addressController: addressController,
            apartmentController: apartmentController,
            commentController: commentController,
            onCheckout: () {},
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.cartAddressLabel), findsOneWidget);
    expect(find.text(AppStrings.cartApartmentLabel), findsOneWidget);
    expect(find.text(AppStrings.cartCommentLabel), findsOneWidget);

    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.length, 3);
    expect(fields[1].controller, apartmentController);
  });

  testWidgets('text fields have onTapOutside handler', (tester) async {
    final addressController = TextEditingController();
    final apartmentController = TextEditingController();
    final commentController = TextEditingController();
    addTearDown(addressController.dispose);
    addTearDown(apartmentController.dispose);
    addTearDown(commentController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckoutForm(
            addressController: addressController,
            apartmentController: apartmentController,
            commentController: commentController,
            onCheckout: () {},
          ),
        ),
      ),
    );

    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.onTapOutside, isNotNull);
    }
  });
}
