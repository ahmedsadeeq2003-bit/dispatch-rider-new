import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/delivery_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/motion.dart';
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
        backgroundColor: AppColors.background,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Active Deliveries')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DeliveryService.getActiveDeliveries(_currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: const [SkeletonDeliveryCard(), SkeletonDeliveryCard()],
            );
          }

          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load deliveries',
              subtitle: '${snapshot.error}',
              color: AppColors.danger,
            );
          }

          final deliveries = snapshot.data ?? [];

          if (deliveries.isEmpty) {
            return const EmptyState(
              icon: Icons.delivery_dining_rounded,
              title: 'No active deliveries',
              subtitle: 'Accept a pending request to see it here',
              color: AppColors.accentGreen,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final data = deliveries[index];
              final pickupLat = (data['pickup_lat'] as num?)?.toDouble();
              final pickupLng = (data['pickup_lng'] as num?)?.toDouble();
              final dropLat = (data['dropoff_lat'] as num?)?.toDouble();
              final dropLng = (data['dropoff_lng'] as num?)?.toDouble();

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: index * 50),
                  child: DeliveryCard(
                    data: data,
                    variant: DeliveryCardVariant.active,
                    primaryLabel: 'Continue',
                    onPrimary: () {
                      Navigator.push(
                        context,
                        AppPageRoute(
                          page: TrackOrderScreen(
                            orderId: data['id'] as String,
                            pickup: pickupLat != null && pickupLng != null
                                ? LatLng(pickupLat, pickupLng)
                                : null,
                            destination: dropLat != null && dropLng != null
                                ? LatLng(dropLat, dropLng)
                                : null,
                          ),
                        ),
                      );
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
