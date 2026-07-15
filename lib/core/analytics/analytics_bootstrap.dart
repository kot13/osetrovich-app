import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:appmetrica_push_plugin/appmetrica_push_plugin.dart';
import 'package:flutter/foundation.dart';

abstract final class AnalyticsBootstrap {
  static const apiKeyDefine = 'APPMETRICA_API_KEY';

  static bool pushActivated = false;

  static String? get apiKey {
    const key = String.fromEnvironment(apiKeyDefine);
    return key.isEmpty ? null : key;
  }

  static bool get isEnabled => apiKey != null;

  static bool get isPushEnabled => isEnabled && pushActivated;

  static AppMetricaConfig? buildConfig() {
    final key = apiKey;
    if (key == null) {
      return null;
    }
    return AppMetricaConfig(
      key,
      logs: kDebugMode,
      flutterCrashReporting: true,
      crashReporting: true,
    );
  }

  /// Инициализация аналитики и крашей. Push активируется отдельно и не блокирует старт.
  static Future<void> initialize() async {
    final config = buildConfig();
    if (config == null) {
      return;
    }
    await AppMetrica.activate(config);
    await initializePush();
  }

  /// Push требует FCM (Android) / APNs (iOS). Без нативной настройки — тихий skip.
  static Future<bool> initializePush() async {
    if (!isEnabled) {
      pushActivated = false;
      return false;
    }
    try {
      await AppMetricaPush.activate();
      pushActivated = true;
      return true;
    } on Object catch (error, stackTrace) {
      pushActivated = false;
      if (kDebugMode) {
        debugPrint(
          'AppMetrica Push не активирован (нужен FCM/APNs): $error\n$stackTrace',
        );
      }
      return false;
    }
  }
}
