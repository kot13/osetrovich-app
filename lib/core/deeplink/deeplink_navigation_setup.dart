import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/deeplink/deeplink_navigation.dart';
import 'package:osetrovich/core/deeplink/deeplink_providers.dart';

/// Подписка на входящие `osetrovich://` (cold start + foreground/background).
final deeplinkNavigationSetupProvider = Provider.family<void, GoRouter>((
  ref,
  router,
) {
  final appLinks = AppLinks();
  final resolver = ref.watch(deepLinkResolverProvider);
  final subscriptions = <StreamSubscription<Uri>>[];

  appLinks
      .getInitialLink()
      .then((uri) {
        if (uri != null) {
          DeepLinkNavigation.navigateFromUrl(
            router,
            ref.read,
            uri.toString(),
            resolver: resolver,
          );
        }
      })
      .catchError((_) {});

  subscriptions.add(
    appLinks.uriLinkStream.listen((uri) {
      DeepLinkNavigation.navigateFromUrl(
        router,
        ref.read,
        uri.toString(),
        resolver: resolver,
      );
    }),
  );

  ref.onDispose(() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  });
});
