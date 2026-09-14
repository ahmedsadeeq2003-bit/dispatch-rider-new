import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small glanceable stat used in stat rows (today's earnings, deliveries
/// done, rating) — icon + big number + label, nothing to read, just scan.
class StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const StatChip({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppText.numericMd),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
