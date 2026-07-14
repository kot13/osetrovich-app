import 'package:flutter/material.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/empty_state.dart';

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabPromotions)),
      body: const EmptyState(message: AppStrings.nothingFound),
    );
  }
}
