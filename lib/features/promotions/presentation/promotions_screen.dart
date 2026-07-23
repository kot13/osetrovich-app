import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/empty_state.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/promotions/domain/promotions_notifier.dart';
import 'package:osetrovich/features/promotions/domain/selected_type_provider.dart';
import 'package:osetrovich/features/promotions/presentation/widgets/promotion_article_card.dart';
import 'package:osetrovich/features/promotions/presentation/widgets/promotion_type_chips.dart';
import 'package:osetrovich/features/notifications/presentation/widgets/notification_bell_action.dart';

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = ref.watch(selectedPromotionTypeProvider);
    final articlesAsync = ref.watch(promotionsNotifierProvider);

    ref.listen(selectedPromotionTypeProvider, (previous, next) {
      if (previous != next && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tabPromotions),
        actions: const [NotificationBellAction()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PromotionTypeChips(
            selectedType: selectedType,
            onSelected: (type) {
              ref.read(selectedPromotionTypeProvider.notifier).select(type);
            },
          ),
          Expanded(
            child: articlesAsync.when(
              loading: () => const LoadingIndicator(),
              error:
                  (_, __) => EmptyState(
                    message: AppStrings.articlesLoadFailed,
                    actionLabel: AppStrings.retry,
                    onAction:
                        () =>
                            ref
                                .read(promotionsNotifierProvider.notifier)
                                .reload(),
                  ),
              data: (articles) {
                if (articles.isEmpty) {
                  return const EmptyState(message: AppStrings.nothingFound);
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return PromotionArticleCard(
                      article: article,
                      onTap:
                          () =>
                              context.push('/promotions/article/${article.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
