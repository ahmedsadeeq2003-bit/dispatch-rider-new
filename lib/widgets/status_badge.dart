import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Status communication never relies on color alone — every state pairs a
/// color with a distinct icon and label, so it still reads correctly for a
/// rider glancing in bright sunlight or with color-vision deficiency.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  static const Map<String, Color> _colors = {
    'pending': AppColors.warning,
    'accepted': AppColors.info,
    'picked_up': AppColors.accentAmber,
    'in_transit': AppColors.accentPurple,
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

  static const Map<String, IconData> _icons = {
    'pending': Icons.schedule_rounded,
    'accepted': Icons.handshake_rounded,
    'picked_up': Icons.inventory_2_rounded,
    'in_transit': Icons.local_shipping_rounded,
    'delivered': Icons.task_alt_rounded,
    'completed': Icons.task_alt_rounded,
    'cancelled': Icons.cancel_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final key = status.toLowerCase();
    final color = _colors[key] ?? AppColors.textMuted;
    final label = _labels[key] ?? status;
    final icon = _icons[key] ?? Icons.circle;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
