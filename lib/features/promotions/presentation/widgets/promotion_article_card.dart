import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/utils/date_formatter.dart';
import 'package:osetrovich/core/widgets/safe_cached_network_image.dart';
import 'package:osetrovich/features/promotions/domain/promotion_article.dart';

class PromotionArticleCard extends StatelessWidget {
  const PromotionArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  final PromotionArticleSummary article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: SafeCachedNetworkImage(
                imageUrl: article.imageUrl,
                fit: BoxFit.cover,
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
