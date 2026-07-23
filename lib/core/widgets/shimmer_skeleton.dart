import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';

/// Обёртка для группы скелетон-плейсхолдеров с общей shimmer-анимацией.
class ShimmerScope extends StatefulWidget {
  const ShimmerScope({required this.child, super.key});

  final Widget child;

  static Animation<double>? animationOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ShimmerScopeData>()
        ?.animation;
  }

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScopeData(
      animation: _controller,
      child: widget.child,
    );
  }
}

class _ShimmerScopeData extends InheritedWidget {
  const _ShimmerScopeData({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_ShimmerScopeData oldWidget) {
    return animation != oldWidget.animation;
  }
}

/// Прямоугольный плейсхолдер с shimmer-градиентом.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final animation = ShimmerScope.animationOf(context);
    final base = baseColor ?? const Color(0xFFE4E6E8);
    final highlight = highlightColor ?? const Color(0xFFF4F5F5);

    if (animation == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: base, borderRadius: borderRadius),
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final slide = -1.0 + 2.0 * animation.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment(slide - 1, 0),
              end: Alignment(slide + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}

/// Скелетон на тёмном фоне (блок статуса лояльности).
class SkeletonBoxOnDark extends StatelessWidget {
  const SkeletonBoxOnDark({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
      baseColor: Colors.white.withValues(alpha: 0.12),
      highlightColor: Colors.white.withValues(alpha: 0.22),
    );
  }
}

/// Карточка-скелетон на светлом фоне с тенью (как лимонный блок).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
      child: Padding(padding: padding, child: child),
    );
  }
}
