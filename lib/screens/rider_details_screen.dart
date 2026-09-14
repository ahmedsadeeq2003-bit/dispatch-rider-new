import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import 'track_order_screen.dart';

/// Shown to the client the moment a rider accepts their delivery — the
/// "match found" moment before handing off to live tracking.
class RiderDetailsScreen extends StatefulWidget {
  const RiderDetailsScreen({super.key});

  @override
  State<RiderDetailsScreen> createState() => _RiderDetailsScreenState();
}

class _RiderDetailsScreenState extends State<RiderDetailsScreen> {
  Map<String, dynamic>? _riderProfile;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _loadRider();
  }

  Future<void> _loadRider() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final riderId = args['riderId'] as String?;
    if (riderId != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name, phone_number, rating')
            .eq('id', riderId)
            .maybeSingle();
        if (mounted) setState(() => _riderProfile = profile);
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final deliveryId = args['deliveryId'] as String?;
    final pickup = args['pickup'] as String? ?? '';
    final destination = args['destination'] as String? ?? '';
    final package = args['package'] as String? ?? '';
    final price = (args['price'] as num?)?.toDouble() ?? 0.0;
    final weight = (args['weight'] as num?)?.toDouble() ?? 0.0;

    final riderName = _riderProfile?['full_name'] as String? ?? 'Your rider';
    final rating = (_riderProfile?['rating'] as num?)?.toDouble() ?? 5.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rider Found')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            FadeSlideIn(
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
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withAlpha(46),
                      child: _loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              riderName.isNotEmpty ? riderName[0].toUpperCase() : '?',
                              style: AppText.h2.copyWith(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(riderName, style: AppText.h3.copyWith(color: Colors.white)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(rating.toStringAsFixed(1),
                                  style: AppText.bodyMuted.copyWith(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(icon: Icons.circle, iconColor: AppColors.accentGreen, label: 'Pickup', value: pickup),
                    const SizedBox(height: AppSpacing.md),
                    _InfoRow(icon: Icons.location_on_rounded, iconColor: AppColors.danger, label: 'Destination', value: destination),
                    const SizedBox(height: AppSpacing.md),
                    _InfoRow(icon: Icons.inventory_2_rounded, iconColor: AppColors.accentPurple, label: 'Package', value: '$package • ${weight}kg'),
                    const SizedBox(height: AppSpacing.md),
                    _InfoRow(icon: Icons.payments_rounded, iconColor: AppColors.money, label: 'Price', value: '₦${price.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: deliveryId == null
                    ? null
                    : () {
                        Navigator.pushReplacement(
                          context,
                          AppPageRoute(page: TrackOrderScreen(orderId: deliveryId)),
                        );
                      },
                child: const Text('Track Delivery'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.caption),
              Text(value, style: AppText.body),
            ],
          ),
        ),
      ],
    );
  }
}
