import 'dart:convert';

import 'package:go_router/go_router.dart';

/// Маршрутизация push-payload → go_router (контракт push-deeplink.yaml).
class PushDeeplinkHandler {
  const PushDeeplinkHandler();

  String resolveRoute(Map<String, dynamic> payload) {
    final type = payload['type'] as String?;
    if (type == null || type.isEmpty) {
      return '/home/notifications';
    }
    final targetId = payload['targetId'] as String?;

    return switch (type) {
      'home' => '/home',
      'order' => '/home',
      'promotion' => _routeWithTarget('/promotions/article', targetId),
      'notification' => _routeWithTarget('/home/notifications', targetId),
      'product' => _routeWithTarget('/catalog/product', targetId),
      _ => '/home/notifications',
    };
  }

  String resolveRouteFromPayloadString(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return '/home/notifications';
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return '/home/notifications';
      }
      return resolveRoute(decoded);
    } on Object {
      return '/home/notifications';
    }
  }

  void navigate(GoRouter router, String? payload) {
    final route = resolveRouteFromPayloadString(payload);
    router.go(route);
  }

  String _routeWithTarget(String prefix, String? targetId) {
    if (targetId == null || targetId.isEmpty) {
      return prefix == '/home/notifications' ? '/home/notifications' : '/home';
    }
    return '$prefix/$targetId';
  }
}
