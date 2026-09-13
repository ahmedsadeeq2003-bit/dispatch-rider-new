import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

class CompletedDeliveriesScreen extends StatefulWidget {
  const CompletedDeliveriesScreen({super.key});

  @override
  State<CompletedDeliveriesScreen> createState() =>
      _CompletedDeliveriesScreenState();
}

class _CompletedDeliveriesScreenState extends State<CompletedDeliveriesScreen> {
  final User? _currentUser = Supabase.instance.client.auth.currentUser;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', uid)
        .maybeSingle();
    if (!mounted) return;
    setState(() => _role = profile?['role'] as String? ?? 'client');
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Completed Deliveries')),
        body: const EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Please log in',
          subtitle: 'Log in to view completed deliveries',
          color: AppColors.info,
        ),
      );
    }

    if (_role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final isRider = _role == 'rider';
    final stream = isRider
        ? DeliveryService.getCompletedDeliveries(_currentUser.id)
        : DeliveryService.getCompletedDeliveriesForClient(_currentUser.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Completed Deliveries')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
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
              icon: Icons.check_circle_rounded,
              title: 'No completed deliveries yet',
              subtitle: 'Finished deliveries will show up here',
              color: AppColors.success,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: deliveries.length,
            itemBuilder: (context, i) => _CompletedCard(
              delivery: deliveries[i],
              showRateButton: !isRider,
            ),
          );
        },
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final bool showRateButton;

  const _CompletedCard({required this.delivery, required this.showRateButton});

  @override
  Widget build(BuildContext context) {
    final pickup = delivery['pickup_address'] as String? ?? 'Unknown pickup';
    final destination =
        delivery['dropoff_address'] as String? ?? 'Unknown destination';
    final price = (delivery['price_naira'] as num?)?.toDouble() ?? 0.0;
    final weight = (delivery['weight_kg'] as num?)?.toDouble() ?? 0.0;
    final packageType = delivery['package_type'] as String? ?? 'Package';
    final completedAt = delivery['completed_at'] as String?;
    final ratingSubmitted = delivery['rating_submitted'] == true;
    final deliveryId = delivery['id'] as String;

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
              const StatusBadge(status: 'completed'),
              Text('₦${price.toStringAsFixed(0)}',
                  style: AppText.h3.copyWith(color: AppColors.success)),
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
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: AppColors.accentGreen),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(pickup, style: AppText.body)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 18, color: AppColors.danger),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(destination, style: AppText.body)),
            ],
          ),
          if (completedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Completed: ${DateTime.parse(completedAt).toLocal().toString().split('.').first}',
              style: AppText.caption,
            ),
          ],
          if (showRateButton) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ratingSubmitted
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.star_rounded),
                      label: const Text('Rated'),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/rate-rider',
                        arguments: {'deliveryId': deliveryId},
                      ),
                      icon: const Icon(Icons.star_rounded),
                      label: const Text('Rate your rider'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
