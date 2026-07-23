import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/core/utils/product_weight_parser.dart';

/// Whether to show strikethrough old price on the add-to-cart button.
bool shouldShowStrikethroughOldPrice({
  required int oldPriceRub,
  required int priceRub,
}) {
  return oldPriceRub > priceRub;
}

/// Whether [priceRub] should be multiplied by weight for display on the button.
bool shouldMultiplyPriceByWeight({
  required bool pieceProduct,
  required String weightLabel,
}) {
  if (pieceProduct) {
    return false;
  }
  final weightKg = parseProductWeightKg(weightLabel);
  if (weightKg == null) {
    return false;
  }
  return weightKg != 1.0;
}

/// Price for the button and quantity bar, accounting for weight-based products.
int productDisplayPriceRub({
  required int priceRub,
  required String weightLabel,
  required bool pieceProduct,
}) {
  if (!shouldMultiplyPriceByWeight(
    pieceProduct: pieceProduct,
    weightLabel: weightLabel,
  )) {
    return priceRub;
  }
  final weightKg = parseProductWeightKg(weightLabel)!;
  return (priceRub * weightKg).round();
}

/// Resolved prices for catalog cards and product detail.
class ProductCatalogPriceDisplay {
  const ProductCatalogPriceDisplay({
    required this.buttonPriceRub,
    required this.buttonOldPriceRub,
    this.secondaryPriceLabel,
    this.priceWeightSuffix,
  });

  final int buttonPriceRub;
  final int buttonOldPriceRub;
  final String? secondaryPriceLabel;

  /// Suffix for price labels, e.g. « за 2 кг».
  final String? priceWeightSuffix;

  factory ProductCatalogPriceDisplay.resolve({
    required int priceRub,
    required int oldPriceRub,
    required int pricePerKgRub,
    required String weightLabel,
    required bool pieceProduct,
    required bool special,
  }) {
    final buttonPriceRub = productDisplayPriceRub(
      priceRub: priceRub,
      weightLabel: weightLabel,
      pieceProduct: pieceProduct,
    );
    final buttonOldPriceRub = productDisplayPriceRub(
      priceRub: oldPriceRub,
      weightLabel: weightLabel,
      pieceProduct: pieceProduct,
    );

    return ProductCatalogPriceDisplay(
      buttonPriceRub: buttonPriceRub,
      buttonOldPriceRub: buttonOldPriceRub,
      secondaryPriceLabel: _resolveSecondaryPriceLabel(
        special: special,
        pricePerKgRub: pricePerKgRub,
        priceRub: priceRub,
        weightLabel: weightLabel,
        pieceProduct: pieceProduct,
      ),
      priceWeightSuffix: productPriceWeightSuffix(
        pieceProduct: pieceProduct,
        weightLabel: weightLabel,
      ),
    );
  }
}

/// Suffix « за {вес}» для цены весового товара.
String? productPriceWeightSuffix({
  required bool pieceProduct,
  required String weightLabel,
}) {
  if (pieceProduct) {
    return null;
  }
  if (parseProductWeightKg(weightLabel) == null) {
    return null;
  }
  return ' за $weightLabel';
}

String? _resolveSecondaryPriceLabel({
  required bool special,
  required int pricePerKgRub,
  required int priceRub,
  required String weightLabel,
  required bool pieceProduct,
}) {
  if (special && pricePerKgRub > 0) {
    return formatPriceRub(
      productDisplayPriceRub(
        priceRub: priceRub,
        weightLabel: weightLabel,
        pieceProduct: pieceProduct,
      ),
    );
  }
  if (!special && pricePerKgRub > 0) {
    return formatPricePerKgRub(pricePerKgRub);
  }
  return null;
}
