import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/features/home/domain/home_lemon_gamification_ui_model.dart';
import 'package:osetrovich/features/home/presentation/lemon_progress_icon.dart';

class HomeLemonGamificationCard extends StatelessWidget {
  const HomeLemonGamificationCard({required this.model, super.key});

  static const cardKey = Key('home_lemon_gamification_card');
  static const termsLinkKey = Key('home_lemon_gamification_terms_link');

  final HomeLemonGamificationUiModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      key: cardKey,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.homeLemonGamificationTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < model.totalSlots; i++)
                    LemonProgressIcon(filled: i < model.filledCount),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: model.progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE8E8E8),
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 14),
              _GiftPromoBox(model: model),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🍋', style: TextStyle(fontSize: 16, height: 1.1)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppStrings.homeLemonGamificationCaption,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.dark.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFECECEC)),
              const SizedBox(height: 8),
              InkWell(
                key: termsLinkKey,
                onTap:
                    () => context.push(
                      '/promotions/article/${AppStrings.homeLemonGamificationTermsArticleId}',
                    ),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: AppColors.primary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.homeLemonGamificationTermsLink,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftPromoBox extends StatelessWidget {
  const _GiftPromoBox({required this.model});

  final HomeLemonGamificationUiModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle =
        model.isGiftReady
            ? AppStrings.homeLemonGamificationGiftReady
            : AppStrings.homeLemonGamificationRemaining(
              model.remainingUntilGift,
            );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dark.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.card_giftcard,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.homeLemonGamificationGiftTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.dark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.dark.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Text(
                      '${model.filledCount} / ${model.totalSlots}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.homeLemonGamificationLemonsCounterLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.dark.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
