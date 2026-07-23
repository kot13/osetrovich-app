import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/widgets/shimmer_skeleton.dart';

class HomeLoyaltyStatusCardSkeleton extends StatelessWidget {
  const HomeLoyaltyStatusCardSkeleton({super.key});

  static const skeletonKey = Key('home_loyalty_status_skeleton');

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: skeletonKey,
      padding: const EdgeInsets.all(16),
      child: ShimmerScope(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBoxOnDark(
                      width: 36,
                      height: 36,
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBoxOnDark(width: 72, height: 12),
                          SizedBox(height: 8),
                          SkeletonBoxOnDark(width: 120, height: 22),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBoxOnDark(width: 80, height: 12),
                          SizedBox(height: 8),
                          SkeletonBoxOnDark(width: 48, height: 24),
                          SizedBox(height: 8),
                          SkeletonBoxOnDark(width: 90, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SkeletonBoxOnDark(
                  width: double.infinity,
                  height: 52,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
