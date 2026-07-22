import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/deeplink/deeplink_navigation.dart';
import 'package:osetrovich/core/deeplink/deeplink_resolver.dart';
import 'package:osetrovich/core/deeplink/deeplink_target.dart';

/// Маршрутизация push-payload → go_router (контракт push-deeplink-v2.yaml).
class PushDeeplinkHandler {
  const PushDeeplinkHandler({DeepLinkResolver resolver = const DeepLinkResolver()})
    : _resolver = resolver;

  final DeepLinkResolver _resolver;

  String resolveRoute(Map<String, dynamic> payload) {
    return resolveTarget(payload).path;
  }

  DeepLinkTarget resolveTarget(Map<String, dynamic> payload) {
    final deeplink =
        payload['deeplink'] as String? ?? payload['url'] as String?;
    if (deeplink != null && deeplink.trim().startsWith('osetrovich://')) {
      return _resolver.resolve(deeplink);
    }

    final notificationId = payload['notification_id'] as String?;
    if (notificationId != null && notificationId.trim().isNotEmpty) {
      return _resolver.resolve(
        'osetrovich://notifications/${notificationId.trim()}',
      );
    }

    final type = payload['type'] as String?;
    if (type == null || type.isEmpty) {
      return const DeepLinkTarget(path: '/home/notifications');
    }
    final targetId = payload['targetId'] as String?;

    final path = switch (type) {
      'home' => '/home',
      'order' => '/home',
      'promotion' => _routeWithTarget('/promotions/article', targetId),
      'notification' => _routeWithTarget('/home/notifications', targetId),
      'product' => _routeWithTarget('/catalog/product', targetId),
      _ => '/home/notifications',
    };
    return DeepLinkTarget(path: path);
  }

  String resolveRouteFromPayloadString(String? payload) {
    return resolveTargetFromPayloadString(payload).path;
  }

  DeepLinkTarget resolveTargetFromPayloadString(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return const DeepLinkTarget(path: '/home/notifications');
    }

    final trimmed = payload.trim();
    if (trimmed.startsWith('osetrovich://')) {
      return _resolver.resolve(trimmed);
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        return const DeepLinkTarget(path: '/home/notifications');
      }
      return resolveTarget(decoded);
    } on Object {
      return const DeepLinkTarget(path: '/home/notifications');
    }
  }

  void navigate(GoRouter router, Ref ref, String? payload) {
    final target = resolveTargetFromPayloadString(payload);
    DeepLinkNavigation.navigate(router, ref.read, target);
  }

  String _routeWithTarget(String prefix, String? targetId) {
    if (targetId == null || targetId.isEmpty) {
      return prefix == '/home/notifications' ? '/home/notifications' : '/home';
    }
    return '$prefix/$targetId';
  }
}
