import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A bold, colorful tappable tile used on dashboards (e.g. "Dispatch",
/// "Track Order"). Replaces the old ad-hoc GestureDetector+Card pattern.
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg, horizontal: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(56),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, size: 26, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                style: AppText.h3.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
