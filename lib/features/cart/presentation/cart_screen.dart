import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/empty_state.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabCart)),
      body: EmptyState(
        message: AppStrings.cartEmpty,
        actionLabel: AppStrings.goToCatalog,
        onAction: () => context.go('/catalog'),
      ),
    );
  }
}
