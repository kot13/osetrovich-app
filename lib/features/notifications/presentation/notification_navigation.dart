import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Маршрут списка уведомлений для текущей ветки Tab Bar.
String notificationsListPathForLocation(String matchedLocation) {
  if (matchedLocation.startsWith('/catalog')) {
    return '/catalog/notifications';
  }
  if (matchedLocation.startsWith('/promotions')) {
    return '/promotions/notifications';
  }
  if (matchedLocation.startsWith('/cart')) {
    return '/cart/notifications';
  }
  if (matchedLocation.startsWith('/profile')) {
    return '/profile/notifications';
  }
  return '/home/notifications';
}

void openNotificationsList(BuildContext context) {
  final location = GoRouterState.of(context).matchedLocation;
  context.push(notificationsListPathForLocation(location));
}
