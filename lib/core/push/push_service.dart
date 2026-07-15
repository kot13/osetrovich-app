abstract class PushService {
  Future<void> syncPushEnabled(bool enabled);

  void listenForTokenUpdates(
    void Function(Map<String, String?> tokens) onTokens,
  );
}
