import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/app.dart';
import 'package:osetrovich/core/analytics/analytics_bootstrap.dart';
import 'package:osetrovich/core/push/firebase_push_bootstrap.dart';

Future<void> _launchApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebasePushBootstrap.initialized = true;
  } on Object catch (error, stackTrace) {
    FirebasePushBootstrap.initialized = false;
    if (kDebugMode) {
      debugPrint('Firebase не инициализирован: $error\n$stackTrace');
    }
  }

  try {
    await AnalyticsBootstrap.initialize();
  } on Object catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('AnalyticsBootstrap failed: $error\n$stackTrace');
    }
  }
  runApp(const ProviderScope(child: App()));
}

void main() {
  if (AnalyticsBootstrap.isEnabled) {
    AppMetrica.runZoneGuarded(() {
      _launchApp();
    });
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  _launchApp();
}
