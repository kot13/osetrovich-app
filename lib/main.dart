import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/app.dart';
import 'package:osetrovich/core/analytics/analytics_bootstrap.dart';

Future<void> _launchApp() async {
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
