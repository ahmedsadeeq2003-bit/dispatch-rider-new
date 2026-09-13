import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';
import 'track_order_screen.dart';
import 'package:latlong2/latlong.dart';

class ActiveDeliveriesScreen extends StatefulWidget {
  const ActiveDeliveriesScreen({super.key});

  @override
  State<ActiveDeliveriesScreen> createState() => _ActiveDeliveriesScreenState();
}

class _ActiveDeliveriesScreenState extends State<ActiveDeliveriesScreen> {
  final User? _currentUser = Supabase.instance.client.auth.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Deliveries')),
        body: const EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Please log in',
          subtitle: 'Log in to view your active deliveries',
          color: AppColors.info,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Active Deliveries')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DeliveryService.getActiveDeliveries(_currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: AppText.bodyMuted),
            );
          }

          final deliveries = snapshot.data ?? [];

          if (deliveries.isEmpty) {
            return const EmptyState(
              icon: Icons.delivery_dining_rounded,
              title: 'No active deliveries',
              subtitle: 'Your active deliveries will appear here',
              color: AppColors.accentGreen,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              final deliveryId = delivery['id'] as String;

              return _DeliveryCard(
                delivery: delivery,
                deliveryId: deliveryId,
                onComplete: () => _markAsCompleted(deliveryId),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAsCompleted(String deliveryId) async {
    try {
      await DeliveryService.updateDeliveryStatus(deliveryId, 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing delivery: $e')),
        );
      }
    }
  }
}

class _DeliveryCard extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final String deliveryId;
  final VoidCallback onComplete;

  const _DeliveryCard({
    required this.delivery,
    required this.deliveryId,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final pickupLocation =
        delivery['pickup_address'] as String? ?? 'Unknown pickup';
    final destination =
        delivery['dropoff_address'] as String? ?? 'Unknown destination';
    final status = delivery['status'] as String? ?? 'accepted';
    final price = (delivery['price_naira'] as num?)?.toDouble() ?? 0.0;
    final weight = (delivery['weight_kg'] as num?)?.toDouble() ?? 0.0;
    final packageType = delivery['package_type'] as String? ?? 'Package';

    final pickupLat = (delivery['pickup_lat'] as num?)?.toDouble();
    final pickupLon = (delivery['pickup_lng'] as num?)?.toDouble();
    final destLat = (delivery['dropoff_lat'] as num?)?.toDouble();
    final destLon = (delivery['dropoff_lng'] as num?)?.toDouble();

    LatLng? pickupCoords;
    LatLng? destCoords;
    if (pickupLat != null && pickupLon != null) {
      pickupCoords = LatLng(pickupLat, pickupLon);
    }
    if (destLat != null && destLon != null) {
      destCoords = LatLng(destLat, destLon);
    }

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
              StatusBadge(status: status),
              Text(
                '₦${price.toStringAsFixed(0)}',
                style: AppText.h3.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text('$packageType • ${weight.toStringAsFixed(1)}kg',
                  style: AppText.bodyMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _LocationLine(
            icon: Icons.circle,
            iconColor: AppColors.accentGreen,
            label: pickupLocation,
          ),
          const SizedBox(height: 4),
          _LocationLine(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.danger,
            label: destination,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackOrderScreen(
                          orderId: deliveryId,
                          pickup: pickupCoords,
                          destination: destCoords,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text('Track Live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle_rounded,
                      size: 18, color: AppColors.success),
                  label: const Text('Complete',
                      style: TextStyle(color: AppColors.success)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.success),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _LocationLine(
      {required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(icon, size: icon == Icons.circle ? 10 : 18, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppText.body)),
      ],
    );
  }
}
