import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/analytics/analytics_bootstrap.dart';
import 'package:osetrovich/core/analytics/analytics_service.dart';
import 'package:osetrovich/core/analytics/appmetrica_analytics_service.dart';
import 'package:osetrovich/core/analytics/no_op_analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  if (!AnalyticsBootstrap.isEnabled) {
    return NoOpAnalyticsService();
  }
  return AppMetricaAnalyticsService();
});
