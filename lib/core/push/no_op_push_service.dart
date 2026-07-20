import 'package:osetrovich/core/push/push_service.dart';

class NoOpPushService implements PushService {
  @override
  void listenForTokenUpdates(
    void Function(Map<String, String?> tokens) onTokens,
  ) {}

  @override
  Future<void> syncPushEnabled(bool enabled) async {}

  @override
  Future<Map<String, String?>> getTokens() async => const {};
}
