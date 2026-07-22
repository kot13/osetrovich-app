import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:osetrovich/core/push/push_incoming_mapper.dart';
import 'package:osetrovich/core/push/push_incoming_message.dart';

/// Источник foreground push-сообщений (FCM onMessage).
abstract class FcmForegroundPushService {
  Stream<PushIncomingMessage> get messages;

  void start();

  void dispose();
}

class FirebaseFcmForegroundPushService implements FcmForegroundPushService {
  FirebaseFcmForegroundPushService({
    Stream<RemoteMessage> Function()? onMessageStream,
  }) : _onMessageStream = onMessageStream ?? (() => FirebaseMessaging.onMessage);

  final Stream<RemoteMessage> Function() _onMessageStream;
  final _controller = StreamController<PushIncomingMessage>.broadcast();
  StreamSubscription<RemoteMessage>? _subscription;

  @override
  Stream<PushIncomingMessage> get messages => _controller.stream;

  @override
  void start() {
    _subscription ??= _onMessageStream().listen((message) {
      _controller.add(PushIncomingMapper.fromFcm(message));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

class NoOpFcmForegroundPushService implements FcmForegroundPushService {
  @override
  Stream<PushIncomingMessage> get messages => const Stream.empty();

  @override
  void start() {}

  @override
  void dispose() {}
}
