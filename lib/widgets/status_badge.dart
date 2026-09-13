import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small pill badge used across delivery lists and tracking screens to show
/// a status like "Accepted", "In Transit", "Delivered".
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  static const Map<String, Color> _colors = {
    'pending': AppColors.warning,
    'accepted': AppColors.info,
    'picked_up': AppColors.accentYellow,
    'in_transit': AppColors.secondary,
    'delivered': AppColors.success,
    'completed': AppColors.success,
    'cancelled': AppColors.danger,
  };

  static const Map<String, String> _labels = {
    'pending': 'Pending',
    'accepted': 'Accepted',
    'picked_up': 'Picked Up',
    'in_transit': 'In Transit',
    'delivered': 'Delivered',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    final key = status.toLowerCase();
    final color = _colors[key] ?? AppColors.textSecondary;
    final label = _labels[key] ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
