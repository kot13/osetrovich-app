import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/app.dart';
import 'package:osetrovich/core/analytics/analytics_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsBootstrap.initialize();
  runApp(const ProviderScope(child: App()));
}
