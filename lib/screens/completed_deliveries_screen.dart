import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CompletedDeliveriesScreen extends StatelessWidget {
  const CompletedDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for completed deliveries
    final completedDeliveries = [
      {
        'id': 'ORD001',
        'pickup': 'Lagos Island',
        'destination': 'Victoria Island',
        'distance': 5.2,
        'weight': 2.5,
        'packageType': 'Small Package',
        'price': 1500,
        'rating': 5.0,
        'completedAt': '2024-01-15 14:30',
        'customerFeedback': 'Great service!',
      },
      {
        'id': 'ORD002',
        'pickup': 'Ikeja',
        'destination': 'Surulere',
        'distance': 8.1,
        'weight': 6.0,
        'packageType': 'Large Package',
        'price': 3200,
        'rating': 4.8,
        'completedAt': '2024-01-15 12:15',
        'customerFeedback': 'Package arrived on time',
      },
      {
        'id': 'ORD003',
        'pickup': 'Abuja Central',
        'destination': 'Wuse',
        'distance': 3.8,
        'weight': 1.2,
        'packageType': 'Small Package',
        'price': 1200,
        'rating': 4.9,
        'completedAt': '2024-01-15 10:45',
        'customerFeedback': 'Excellent rider!',
      },
      {
        'id': 'ORD004',
        'pickup': 'Port Harcourt',
        'destination': 'GRA Phase 2',
        'distance': 12.5,
        'weight': 4.0,
        'packageType': 'Small Package',
        'price': 2800,
        'rating': 5.0,
        'completedAt': '2024-01-14 16:20',
        'customerFeedback': 'Very professional',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Completed Deliveries')),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: completedDeliveries.length,
        itemBuilder: (context, index) {
          final delivery = completedDeliveries[index];
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
                    Text('Order ${delivery['id']}', style: AppText.h3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(28),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        'Completed',
                        style: AppText.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.circle,
                        size: 10, color: AppColors.accentGreen),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text('Pickup: ${delivery['pickup']}',
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
                      child: Text('Destination: ${delivery['destination']}',
                          style: AppText.body),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text('${delivery['distance']} km',
                        style: AppText.bodyMuted.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentBlue)),
                    const SizedBox(width: AppSpacing.md),
                    Text('${delivery['weight']} kg',
                        style: AppText.bodyMuted.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentPurple)),
                    const SizedBox(width: AppSpacing.md),
                    Text('${delivery['packageType']}',
                        style: AppText.bodyMuted.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₦${delivery['price']}',
                        style: AppText.h3.copyWith(color: AppColors.success)),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 4),
                        Text('${delivery['rating']}',
                            style: AppText.h3),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Completed: ${delivery['completedAt']}',
                    style: AppText.caption),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: AppColors.textSecondary, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '"${delivery['customerFeedback']}"',
                          style: AppText.bodyMuted
                              .copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
