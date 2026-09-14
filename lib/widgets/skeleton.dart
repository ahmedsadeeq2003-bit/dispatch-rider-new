import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A shimmering placeholder block — used while a stream's first snapshot is
/// still loading, so the rider sees "content is coming" instead of a blank
/// screen or a spinner for anything longer than a card list.
class Skeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadiusGeometry borderRadius;

  const Skeleton({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.surfaceSunken, AppColors.border, _controller.value),
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}

/// A full skeleton card matching DeliveryCard's rough shape.
class SkeletonDeliveryCard extends StatelessWidget {
  const SkeletonDeliveryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Skeleton(height: 18, width: 90),
              const Skeleton(height: 18, width: 60),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Skeleton(height: 14, width: double.infinity),
          const SizedBox(height: AppSpacing.sm),
          const Skeleton(height: 14, width: 160),
        ],
      ),
    );
  }
}
