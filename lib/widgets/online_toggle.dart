import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The single most important control on the rider home screen: am I
/// available for work, and how do I change that with one thumb. Large
/// touch target, unmistakable color+icon+label state, animated on change.
class OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onTap;
  final bool loading;

  const OnlineToggle({
    super.key,
    required this.isOnline,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.standard,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
        decoration: BoxDecoration(
          gradient: isOnline ? AppGradients.heroOnline : AppGradients.heroOffline,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: (isOnline ? AppColors.online : AppColors.offline).withAlpha(70),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.base,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(46),
                shape: BoxShape.circle,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isOnline ? Icons.bolt_rounded : Icons.power_settings_new_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? "You're online" : "You're offline",
                    style: AppText.h2.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOnline
                        ? 'Visible for nearby delivery requests'
                        : 'Tap to start receiving delivery requests',
                    style: AppText.bodyMuted.copyWith(color: Colors.white.withAlpha(210)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(46),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                isOnline ? 'GO OFFLINE' : 'GO ONLINE',
                style: AppText.label.copyWith(color: Colors.white, letterSpacing: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
