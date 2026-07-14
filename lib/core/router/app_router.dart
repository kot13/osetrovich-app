import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/features/auth/presentation/phone_input_screen.dart';
import 'package:osetrovich/features/auth/presentation/sms_code_screen.dart';
import 'package:osetrovich/features/cart/presentation/cart_screen.dart';
import 'package:osetrovich/features/catalog/presentation/catalog_screen.dart';
import 'package:osetrovich/features/home/presentation/home_screen.dart';
import 'package:osetrovich/features/notifications/presentation/notification_detail_screen.dart';
import 'package:osetrovich/features/notifications/presentation/notifications_list_screen.dart';
import 'package:osetrovich/features/profile/presentation/change_phone_code_screen.dart';
import 'package:osetrovich/features/profile/presentation/change_phone_screen.dart';
import 'package:osetrovich/features/profile/presentation/email_code_screen.dart';
import 'package:osetrovich/features/profile/presentation/email_verify_screen.dart';
import 'package:osetrovich/features/profile/presentation/profile_screen.dart';
import 'package:osetrovich/features/promotions/presentation/promotions_screen.dart';
import 'package:osetrovich/features/shell/presentation/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/auth/phone',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/auth/sms',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SmsCodeScreen(),
      ),
      GoRoute(
        path: '/profile/change-phone',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChangePhoneScreen(),
      ),
      GoRoute(
        path: '/profile/change-phone/code',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChangePhoneCodeScreen(),
      ),
      GoRoute(
        path: '/profile/email',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EmailVerifyScreen(),
      ),
      GoRoute(
        path: '/profile/email/code',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EmailCodeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder:
                        (context, state) => const NotificationsListScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return NotificationDetailScreen(notificationId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalog',
                builder: (context, state) => const CatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/promotions',
                builder: (context, state) => const PromotionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
