import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

enum DeliveryCardVariant { pending, active, history }

/// One card design shared by the pending/active/history lists so a rider
/// (or client) learns one visual language instead of three. `data` is a raw
/// Supabase row (snake_case columns from `deliveries`) — this widget only
/// reads, never writes.
class DeliveryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final DeliveryCardVariant variant;
  final VoidCallback? onPrimary;
  final String? primaryLabel;
  final VoidCallback? onSecondary;
  final String? secondaryLabel;
  final VoidCallback? onTap;

  const DeliveryCard({
    super.key,
    required this.data,
    required this.variant,
    this.onPrimary,
    this.primaryLabel,
    this.onSecondary,
    this.secondaryLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pickup = data['pickup_address'] as String? ?? 'Unknown pickup';
    final destination = data['dropoff_address'] as String? ?? 'Unknown destination';
    final status = data['status'] as String? ?? 'pending';
    final price = (data['price_naira'] as num?)?.toDouble() ?? 0.0;
    final weight = (data['weight_kg'] as num?)?.toDouble() ?? 0.0;
    final packageType = data['package_type'] as String? ?? 'Package';
    final id = data['id'] as String? ?? '';
    final shortId = id.length >= 6 ? id.substring(0, 6).toUpperCase() : id;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('#$shortId', style: AppText.label),
                      const SizedBox(width: 8),
                      StatusBadge(status: status, compact: true),
                    ],
                  ),
                  Text(
                    '₦${price.toStringAsFixed(0)}',
                    style: AppText.numericMd.copyWith(color: AppColors.money),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _RoutePreview(pickup: pickup, destination: destination),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('$packageType • ${weight.toStringAsFixed(1)}kg', style: AppText.caption),
                ],
              ),
              if (onPrimary != null || onSecondary != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    if (onSecondary != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onSecondary,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            minimumSize: const Size(0, 46),
                          ),
                          child: Text(secondaryLabel ?? 'Decline'),
                        ),
                      ),
                    if (onSecondary != null && onPrimary != null)
                      const SizedBox(width: AppSpacing.sm),
                    if (onPrimary != null)
                      Expanded(
                        flex: onSecondary != null ? 1 : 2,
                        child: ElevatedButton(
                          onPressed: onPrimary,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: variant == DeliveryCardVariant.pending
                                ? AppColors.signal
                                : AppColors.primary,
                            minimumSize: const Size(0, 46),
                          ),
                          child: Text(primaryLabel ?? 'Accept'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePreview extends StatelessWidget {
  final String pickup;
  final String destination;
  const _RoutePreview({required this.pickup, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(top: 5),
              decoration: const BoxDecoration(
                color: AppColors.accentGreen,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 26,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
            const Icon(Icons.location_on_rounded, size: 12, color: AppColors.danger),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pickup, style: AppText.body, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 14),
              Text(destination, style: AppText.body, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
