import 'package:flutter/material.dart';
import 'package:osetrovich/core/widgets/shimmer_skeleton.dart';

class HomeLemonGamificationCardSkeleton extends StatelessWidget {
  const HomeLemonGamificationCardSkeleton({super.key});

  static const skeletonKey = Key('home_lemon_gamification_skeleton');

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: skeletonKey,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ShimmerScope(
        child: SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonBox(
                width: 180,
                height: 18,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (_) => SkeletonBox(
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SkeletonBox(
                width: double.infinity,
                height: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 14),
              SkeletonBox(
                width: double.infinity,
                height: 72,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 14),
              Center(
                child: SkeletonBox(
                  width: 220,
                  height: 14,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFECECEC)),
              const SizedBox(height: 8),
              SkeletonBox(
                width: double.infinity,
                height: 36,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
