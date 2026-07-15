import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/catalog/data/catalog_repository.dart';

class RepeatOrderResult {
  const RepeatOrderResult({
    required this.addedLineCount,
    required this.skippedProductIds,
  });

  final int addedLineCount;
  final List<String> skippedProductIds;
}

Future<RepeatOrderResult> repeatOrderToCart({
  required CurrentOrder order,
  required CartNotifier cart,
  required CatalogRepository catalog,
}) async {
  var addedLineCount = 0;
  final skippedProductIds = <String>[];

  for (final line in order.items) {
    try {
      await catalog.getProductById(line.productId);
      cart.addQuantity(line.productId, line.quantity);
      addedLineCount++;
    } on ApiException {
      skippedProductIds.add(line.productId);
    }
  }

  return RepeatOrderResult(
    addedLineCount: addedLineCount,
    skippedProductIds: skippedProductIds,
  );
}
