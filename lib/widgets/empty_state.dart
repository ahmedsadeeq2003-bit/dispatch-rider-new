import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Friendly empty/error/permission state — used whenever a list has nothing
/// to show, a request failed, or a permission is missing. Always pairs the
/// icon+message with a recovery action when one exists, per the "never just
/// say 'something went wrong'" rule.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = AppColors.primary,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppText.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: AppText.bodyMuted, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
