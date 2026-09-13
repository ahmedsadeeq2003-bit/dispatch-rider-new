import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/action_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              // Admin access is gated inside AdminDashboardScreen itself
              // (profiles.role check) and again server-side by the
              // admin-* Edge Functions — safe to leave this reachable by
              // anyone until a proper account/profile menu exists.
              onTap: () => Navigator.pushNamed(context, '/admin'),
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
              const Text('Welcome back, Rider! 👋', style: AppText.h1),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'What would you like to do today?',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.lg),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.05,
                children: [
                  ActionTile(
                    icon: Icons.add_box_rounded,
                    label: 'Dispatch',
                    color: AppColors.primary,
                    onTap: () => Navigator.pushNamed(context, '/dispatch'),
                  ),
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
                    onTap: () =>
                        Navigator.pushNamed(context, '/activedeliveries'),
                  ),
                  ActionTile(
                    icon: Icons.check_circle_rounded,
                    label: 'Completed',
                    color: AppColors.accentPurple,
                    onTap: () =>
                        Navigator.pushNamed(context, '/completed-deliveries'),
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
