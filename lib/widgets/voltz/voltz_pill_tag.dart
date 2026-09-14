import 'package:flutter/material.dart';
import '../../theme/voltz_theme.dart';

/// A selectable pill — used for delivery-speed options, add-on toggles, and
/// small inline tags across the Voltz screens.
class VoltzPillTag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const VoltzPillTag({
    super.key,
    required this.text,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VoltzSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? VoltzColors.neon.withAlpha(28) : VoltzColors.surfaceRaised,
            borderRadius: BorderRadius.circular(VoltzSpacing.radiusPill),
            border: Border.all(
              color: selected ? VoltzColors.neon : VoltzColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? VoltzColors.neon : VoltzColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: VoltzText.caption.copyWith(
                  color: selected ? VoltzColors.neon : VoltzColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
