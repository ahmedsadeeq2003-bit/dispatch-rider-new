import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/delivery_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/motion.dart';

/// Real earnings, computed client-side from the rider's own completed
/// deliveries (`price_naira` on rows already scoped by RLS to this rider) —
/// no new backend/schema needed, per "don't build unnecessary infrastructure".
class EarningsScreen extends StatelessWidget {
  final bool embedded;
  const EarningsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final riderId = Supabase.instance.client.auth.currentUser?.id;

    final body = riderId == null
        ? const EmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Please log in',
            subtitle: 'Log in to see your earnings',
            color: AppColors.info,
          )
        : StreamBuilder<List<Map<String, dynamic>>>(
            stream: DeliveryService.getCompletedDeliveries(riderId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: const [
                    Skeleton(height: 140, borderRadius: BorderRadius.all(Radius.circular(24))),
                    SizedBox(height: AppSpacing.lg),
                    SkeletonDeliveryCard(),
                    SkeletonDeliveryCard(),
                  ],
                );
              }

              final deliveries = snapshot.data!;
              final now = DateTime.now();
              final startOfDay = DateTime(now.year, now.month, now.day);
              final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));

              double sumSince(DateTime since) => deliveries
                  .where((d) {
                    final ts = DateTime.tryParse(d['completed_at'] as String? ?? '')?.toLocal();
                    return ts != null && ts.isAfter(since);
                  })
                  .fold<double>(0, (s, d) => s + ((d['price_naira'] as num?)?.toDouble() ?? 0));

              int countSince(DateTime since) => deliveries.where((d) {
                    final ts = DateTime.tryParse(d['completed_at'] as String? ?? '')?.toLocal();
                    return ts != null && ts.isAfter(since);
                  }).length;

              final today = sumSince(startOfDay);
              final week = sumSince(startOfWeek);
              final allTime = deliveries.fold<double>(
                  0, (s, d) => s + ((d['price_naira'] as num?)?.toDouble() ?? 0));

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TODAY\'S EARNINGS',
                              style: AppText.label.copyWith(color: Colors.white.withAlpha(210))),
                          const SizedBox(height: AppSpacing.xs),
                          Text('₦${today.toStringAsFixed(0)}',
                              style: AppText.display.copyWith(color: Colors.white)),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              _MiniStat(label: 'This week', value: '₦${week.toStringAsFixed(0)}'),
                              const SizedBox(width: AppSpacing.xl),
                              _MiniStat(
                                  label: 'Deliveries today', value: '${countSince(startOfDay)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _TotalTile(
                          label: 'All-time earnings',
                          value: '₦${allTime.toStringAsFixed(0)}',
                          icon: Icons.savings_rounded,
                          color: AppColors.money,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _TotalTile(
                          label: 'Total deliveries',
                          value: '${deliveries.length}',
                          icon: Icons.local_shipping_rounded,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Recent payouts'),
                  const SizedBox(height: AppSpacing.sm),
                  if (deliveries.isEmpty)
                    const EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No earnings yet',
                      subtitle: 'Complete your first delivery to start earning',
                      color: AppColors.money,
                    )
                  else
                    ...deliveries.take(15).map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _EarningsRow(delivery: d),
                        )),
                ],
              );
            },
          );

    if (embedded) {
      return Scaffold(backgroundColor: AppColors.background, body: SafeArea(child: body));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Earnings')),
      body: body,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.h3.copyWith(color: Colors.white)),
        Text(label, style: AppText.caption.copyWith(color: Colors.white.withAlpha(200))),
      ],
    );
  }
}

class _TotalTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _TotalTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppText.numericMd),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  final Map<String, dynamic> delivery;
  const _EarningsRow({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final price = (delivery['price_naira'] as num?)?.toDouble() ?? 0.0;
    final destination = delivery['dropoff_address'] as String? ?? 'Delivery';
    final completedAt = delivery['completed_at'] as String?;
    final dateLabel = completedAt != null
        ? DateTime.parse(completedAt).toLocal().toString().split(' ').first
        : '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.money.withAlpha(24),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.money, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(destination,
                    style: AppText.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(dateLabel, style: AppText.caption),
              ],
            ),
          ),
          Text('+₦${price.toStringAsFixed(0)}',
              style: AppText.h3.copyWith(color: AppColors.money)),
        ],
      ),
    );
  }
}
