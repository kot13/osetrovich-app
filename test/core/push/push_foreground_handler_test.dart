import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/push/push_foreground_handler.dart';
import 'package:osetrovich/core/push/push_incoming_message.dart';

void main() {
  test('foreground handler refreshes notifications on receive', () async {
    final controller = StreamController<PushIncomingMessage>.broadcast();
    var refreshCount = 0;
  PushIncomingMessage? bannerMessage;

    final handler = PushForegroundHandler(
      receiveStream: controller.stream,
      refreshNotifications: () => refreshCount++,
      showBanner: (message) => bannerMessage = message,
      onBannerTap: (_) {},
    );

    handler.start();
    controller.add(
      const PushIncomingMessage(
        title: 'Заголовок',
        body: 'Текст',
        notificationId: '1',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(refreshCount, 1);
    expect(bannerMessage?.title, 'Заголовок');
    expect(bannerMessage?.body, 'Текст');
    handler.dispose();
    await controller.close();
  });

  test('handleBannerTap invokes onBannerTap with deeplink message', () {
    PushIncomingMessage? tapped;
    final handler = PushForegroundHandler(
      receiveStream: const Stream.empty(),
      refreshNotifications: () {},
      showBanner: (_) {},
      onBannerTap: (message) => tapped = message,
    );

    const message = PushIncomingMessage(
      deeplink: 'osetrovich://notifications/9',
      notificationId: '9',
    );
    handler.handleBannerTap(message);

    expect(tapped?.toNavigationPayload(), 'osetrovich://notifications/9');
  });
}
