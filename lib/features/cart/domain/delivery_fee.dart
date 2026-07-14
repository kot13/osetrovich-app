const freeDeliveryThresholdRub = 2000;
const paidDeliveryFeeRub = 300;

int calculateDeliveryFeeRub(int itemsSubtotalRub) {
  return itemsSubtotalRub >= freeDeliveryThresholdRub ? 0 : paidDeliveryFeeRub;
}
