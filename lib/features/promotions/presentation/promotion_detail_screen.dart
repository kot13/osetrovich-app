import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/utils/date_formatter.dart';
import 'package:osetrovich/core/widgets/empty_state.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/promotions/data/promotions_repository.dart';
import 'package:osetrovich/features/promotions/domain/promotion_article.dart';
import 'package:osetrovich/features/promotions/presentation/widgets/promotion_html_body.dart';

final promotionDetailProvider =
    FutureProvider.family<PromotionArticleDetail, String>((ref, id) {
      return ref.read(promotionsRepositoryProvider).getArticleById(id);
    });

class PromotionDetailScreen extends ConsumerWidget {
  const PromotionDetailScreen({super.key, required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(promotionDetailProvider(articleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tabPromotions),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailAsync.when(
        loading: () => const LoadingIndicator(),
        error:
            (_, __) => EmptyState(
              message: AppStrings.articleNotFound,
              actionLabel: AppStrings.back,
              onAction: () => context.pop(),
            ),
        data: (article) => _PromotionDetailBody(article: article),
      ),
    );
  }
}

class _PromotionDetailBody extends StatelessWidget {
  const _PromotionDetailBody({required this.article});

  final PromotionArticleDetail article;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: article.imageUrl,
              fit: BoxFit.cover,
              placeholder:
                  (_, __) => ColoredBox(
                    color: AppColors.background,
                    child: Icon(
                      Icons.image_outlined,
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
              errorWidget:
                  (_, __, ___) => ColoredBox(
                    color: AppColors.background,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  label: Text(article.type.typeLabel),
                  backgroundColor: AppColors.accent,
                  labelStyle: const TextStyle(color: AppColors.dark),
                ),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatPublishedDate(article.publishedAt),
                  style: TextStyle(
                    color: AppColors.dark.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                PromotionHtmlBody(html: article.bodyHtml),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
