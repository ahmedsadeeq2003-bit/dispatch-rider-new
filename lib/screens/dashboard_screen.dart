import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/action_tile.dart';
import '../widgets/motion.dart';

/// Client home. Simpler than the rider shell — a client's core loop is
/// "dispatch a package, track it, see history", not a multi-tab work app.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Senditt'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              // Admin access is gated inside AdminDashboardScreen itself
              // (profiles.role check) and again server-side by the
              // admin-* Edge Functions — safe to leave this reachable by
              // anyone until a proper account/profile menu exists.
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withAlpha(30),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Send anything, anywhere 📦', style: AppText.h1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'A rider is always nearby, ready to pick up.',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.lg),

              FadeSlideIn(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/dispatch'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: AppGradients.heroBrand,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      boxShadow: AppShadows.floating,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(46),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_box_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dispatch a package', style: AppText.h2.copyWith(color: Colors.white)),
                              const SizedBox(height: 2),
                              Text('Get a rider in minutes',
                                  style: AppText.bodyMuted.copyWith(color: Colors.white.withAlpha(210))),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Your deliveries', style: AppText.h2),
              const SizedBox(height: AppSpacing.sm),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.15,
                children: [
                  ActionTile(
                    icon: Icons.location_searching_rounded,
                    label: 'Track Order',
                    color: AppColors.accentBlue,
                    onTap: () => Navigator.pushNamed(context, '/trackorder'),
                  ),
                  ActionTile(
                    icon: Icons.delivery_dining_rounded,
                    label: 'Active Deliveries',
                    color: AppColors.accentGreen,
                    onTap: () => Navigator.pushNamed(context, '/activedeliveries'),
                  ),
                  ActionTile(
                    icon: Icons.check_circle_rounded,
                    label: 'Completed',
                    color: AppColors.accentPurple,
                    onTap: () => Navigator.pushNamed(context, '/completed-deliveries'),
                  ),
                  ActionTile(
                    icon: Icons.support_agent_rounded,
                    label: 'Contact Us',
                    color: AppColors.accentTeal,
                    onTap: () => Navigator.pushNamed(context, '/contact-us'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
