import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/bootstrap/app_bootstrap.dart';
import 'package:osetrovich/core/push/push_navigation_setup.dart';
import 'package:osetrovich/core/router/app_router.dart';
import 'package:osetrovich/core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapProvider);

    return bootstrap.when(
      loading:
          () => MaterialApp(
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
      error:
          (error, _) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: Center(child: Text('Ошибка: $error'))),
          ),
      data: (_) {
        final router = ref.watch(routerProvider);
        ref.watch(pushNavigationSetupProvider(router));
        return MaterialApp.router(
          title: 'Осетрович',
          theme: AppTheme.light,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
