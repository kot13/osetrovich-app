import 'dart:convert';

import 'package:go_router/go_router.dart';

/// Маршрутизация push-payload → go_router (контракт push-deeplink.yaml).
class PushDeeplinkHandler {
  const PushDeeplinkHandler();

  String resolveRoute(Map<String, dynamic> payload) {
    final type = payload['type'] as String?;
    final targetId = payload['targetId'] as String?;

    return switch (type) {
      'home' => '/home',
      'order' => '/home',
      'promotion' => _routeWithTarget('/promotions/article', targetId),
      'notification' => _routeWithTarget('/home/notifications', targetId),
      'product' => _routeWithTarget('/catalog/product', targetId),
      _ => '/home',
    };
  }

  String resolveRouteFromPayloadString(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return '/home';
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return '/home';
      }
      return resolveRoute(decoded);
    } on Object {
      return '/home';
    }
  }

  void navigate(GoRouter router, String? payload) {
    final route = resolveRouteFromPayloadString(payload);
    router.go(route);
  }

  String _routeWithTarget(String prefix, String? targetId) {
    if (targetId == null || targetId.isEmpty) {
      return '/home';
    }
    return '$prefix/$targetId';
  }
}
