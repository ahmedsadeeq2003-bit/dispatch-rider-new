import 'package:flutter/material.dart';
import '../../theme/voltz_theme.dart';

/// Dark-theme counterpart to widgets/status_badge.dart — same status
/// vocabulary, Voltz colors/type. Status is always paired with an icon and
/// label, never color alone.
class VoltzStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const VoltzStatusBadge({super.key, required this.status, this.compact = false});

  static const Map<String, Color> _colors = {
    'pending': VoltzColors.warning,
    'accepted': VoltzColors.info,
    'picked_up': VoltzColors.warning,
    'in_transit': VoltzColors.info,
    'delivered': VoltzColors.neon,
    'completed': VoltzColors.neon,
    'cancelled': VoltzColors.danger,
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
    final color = _colors[key] ?? VoltzColors.textMuted;
    final label = _labels[key] ?? status;
    final icon = _icons[key] ?? Icons.circle;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(VoltzSpacing.radiusPill),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: VoltzText.caption.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
