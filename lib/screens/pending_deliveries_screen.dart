import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/delivery_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/motion.dart';

class PendingDeliveriesScreen extends StatefulWidget {
  const PendingDeliveriesScreen({super.key});

  @override
  State<PendingDeliveriesScreen> createState() =>
      _PendingDeliveriesScreenState();
}

class _PendingDeliveriesScreenState extends State<PendingDeliveriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pending Requests')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DeliveryService.getPendingDeliveries(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load requests',
              subtitle: '${snapshot.error}',
              color: AppColors.danger,
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: const [
                SkeletonDeliveryCard(),
                SkeletonDeliveryCard(),
              ],
            );
          }

          final deliveries = snapshot.data ?? [];

          if (deliveries.isEmpty) {
            return const EmptyState(
              icon: Icons.pending_actions_rounded,
              title: 'No pending requests',
              subtitle: 'New delivery requests in your area will show up here',
              color: AppColors.warning,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final data = deliveries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: index * 50),
                  child: DeliveryCard(
                    data: data,
                    variant: DeliveryCardVariant.pending,
                    primaryLabel: 'Accept',
                    secondaryLabel: 'Decline',
                    onSecondary: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Declined delivery ${data['id']}')),
                      );
                    },
                    onPrimary: () async {
                      try {
                        final currentUser = Supabase.instance.client.auth.currentUser;
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please log in to accept deliveries'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }
                        await DeliveryService.acceptDelivery(
                            data['id'] as String, currentUser.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Accepted! Head to pickup.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error accepting delivery: $e'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
