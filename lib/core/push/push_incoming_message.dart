/// Нормализованное входящее push-сообщение (FCM / AppMetrica payload).
class PushIncomingMessage {
  const PushIncomingMessage({
    this.title,
    this.body,
    this.deeplink,
    this.notificationId,
  });

  final String? title;
  final String? body;
  final String? deeplink;
  final String? notificationId;

  /// Payload для [PushDeeplinkHandler.navigate] — только data-поля, не title/body.
  String? toNavigationPayload() {
    if (deeplink != null && deeplink!.trim().isNotEmpty) {
      return deeplink!.trim();
    }
    if (notificationId != null && notificationId!.trim().isNotEmpty) {
      return 'osetrovich://notifications/${notificationId!.trim()}';
    }
    return null;
  }

  bool get hasNavigationTarget => toNavigationPayload() != null;
}
