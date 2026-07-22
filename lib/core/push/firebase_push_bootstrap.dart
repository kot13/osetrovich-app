/// Состояние инициализации Firebase для FCM (независимо от AppMetrica Push).
abstract final class FirebasePushBootstrap {
  static bool initialized = false;

  static bool get isFcmAvailable => initialized;
}
