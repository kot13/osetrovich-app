import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingCheckout {
  const PendingCheckout({required this.address, required this.comment});

  final String address;
  final String comment;
}

class PendingCheckoutNotifier extends Notifier<PendingCheckout?> {
  @override
  PendingCheckout? build() => null;

  void save({required String address, required String comment}) {
    state = PendingCheckout(address: address, comment: comment);
  }

  void clear() {
    state = null;
  }
}

final pendingCheckoutProvider =
    NotifierProvider<PendingCheckoutNotifier, PendingCheckout?>(
      PendingCheckoutNotifier.new,
    );
