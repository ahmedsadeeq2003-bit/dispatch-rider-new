import 'package:flutter/material.dart';
import '../../theme/voltz_theme.dart';

/// A bordered stat card for the Voltz account/dashboard grids — an icon
/// chip, a big tabular-numeral value, and a caption label underneath.
class VoltzStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const VoltzStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accent = VoltzColors.neon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VoltzSpacing.md),
      decoration: BoxDecoration(
        color: VoltzColors.surface,
        borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
        border: Border.all(color: VoltzColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withAlpha(28),
              borderRadius: BorderRadius.circular(VoltzSpacing.radiusSm),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: VoltzSpacing.sm),
          Text(value, style: VoltzText.numericMd, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: VoltzText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
