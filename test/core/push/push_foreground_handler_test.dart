import 'dart:async';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/push/push_foreground_handler.dart';

void main() {
  test('foreground handler refreshes notifications on receive', () async {
    final controller = StreamController<void>.broadcast();
    var refreshCount = 0;

    final handler = PushForegroundHandler(
      receiveStream: () => controller.stream,
      showMessage: (_) {},
      refreshNotifications: () => refreshCount++,
    );

    handler.start();
    controller.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(refreshCount, 1);
    handler.dispose();
    await controller.close();
  });
}
