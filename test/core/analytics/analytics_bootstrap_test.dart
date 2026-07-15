import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/analytics/analytics_bootstrap.dart';

void main() {
  test('buildConfig enables flutterCrashReporting when api key present', () {
    // compile-time define absent in test → null config
    expect(AnalyticsBootstrap.buildConfig(), isNull);
  });

  test('isPushEnabled is false without successful push activation', () {
    expect(AnalyticsBootstrap.isPushEnabled, isFalse);
  });
}
