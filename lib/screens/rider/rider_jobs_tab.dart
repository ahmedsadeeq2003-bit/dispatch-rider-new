import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/delivery_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/menu_row_card.dart';
import '../../widgets/motion.dart';
import '../pending_deliveries_screen.dart';
import '../active_deliveries_screen.dart';
import '../completed_deliveries_screen.dart';

/// Entry point for the three delivery lists. Kept as a menu (rather than an
/// in-tab TabBarView) so each destination stays its own full screen with its
/// own AppBar/back behavior — simpler and safer than nesting scaffolds.
class RiderJobsTab extends StatelessWidget {
  const RiderJobsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final riderId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Deliveries')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (riderId != null)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: DeliveryService.getPendingDeliveries(),
              builder: (context, snapshot) {
                return FadeSlideIn(
                  child: MenuRowCard(
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.warning,
                    title: 'Pending Requests',
                    subtitle: 'New jobs waiting to be accepted',
                    badgeCount: snapshot.data?.length,
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute(page: const PendingDeliveriesScreen()),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          if (riderId != null)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: DeliveryService.getActiveDeliveries(riderId),
              builder: (context, snapshot) {
                return FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: MenuRowCard(
                    icon: Icons.local_shipping_rounded,
                    color: AppColors.accentBlue,
                    title: 'Active Deliveries',
                    subtitle: 'Jobs you\'re currently working on',
                    badgeCount: snapshot.data?.length,
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute(page: const ActiveDeliveriesScreen()),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: MenuRowCard(
              icon: Icons.history_rounded,
              color: AppColors.accentPurple,
              title: 'Delivery History',
              subtitle: 'Completed and past deliveries',
              onTap: () => Navigator.push(
                context,
                AppPageRoute(page: const CompletedDeliveriesScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
