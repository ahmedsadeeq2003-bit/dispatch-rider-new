import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

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
      appBar: AppBar(title: const Text('Pending Deliveries')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DeliveryService.getPendingDeliveries(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: AppText.bodyMuted),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final deliveries = snapshot.data ?? [];

          if (deliveries.isEmpty) {
            return const EmptyState(
              icon: Icons.pending_actions_rounded,
              title: 'No pending deliveries',
              subtitle: 'New delivery requests will show up here',
              color: AppColors.warning,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final data = deliveries[index];

              return _PendingDeliveryCard(
                deliveryId: data['id'] as String,
                data: data,
              );
            },
          );
        },
      ),
    );
  }
}

class _PendingDeliveryCard extends StatelessWidget {
  final String deliveryId;
  final Map<String, dynamic> data;

  const _PendingDeliveryCard({required this.deliveryId, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order $deliveryId', style: AppText.h3),
              const StatusBadge(status: 'pending'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: AppColors.accentGreen),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Pickup: ${data['pickup_address']}',
                    style: AppText.body),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 18, color: AppColors.danger),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Destination: ${data['dropoff_address']}',
                    style: AppText.body),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('${data['weight_kg']} kg',
                  style: AppText.bodyMuted.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentPurple)),
              const SizedBox(width: AppSpacing.md),
              Text('${data['package_type']}',
                  style: AppText.bodyMuted.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₦${data['price_naira']}',
                  style: AppText.h3.copyWith(color: AppColors.success)),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final currentUser =
                            Supabase.instance.client.auth.currentUser;
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please log in to accept deliveries'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }

                        // Accept delivery logic
                        await DeliveryService.acceptDelivery(
                            deliveryId, currentUser.id);

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Accepted delivery $deliveryId'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        // Navigate to active deliveries
                        Navigator.pushNamed(context, '/activedeliveries');
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () {
                      // Decline delivery logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Declined delivery $deliveryId'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
