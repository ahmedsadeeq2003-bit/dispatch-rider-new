import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RiderDetailsScreen extends StatelessWidget {
  const RiderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;

    final riderName = args["riderName"];
    final riderRating = args["riderRating"];
    final riderBike = args["riderBike"];
    final eta = args["eta"];
    final pickup = args["pickup"];
    final destination = args["destination"];
    final package = args["package"];
    final price = args["price"];
    final weight = args["weight"];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rider Details')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // RIDER CARD
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(20),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.secondary,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(riderName, style: AppText.h3),
                      Text("Rating: ⭐ $riderRating", style: AppText.bodyMuted),
                      Text("Bike: $riderBike", style: AppText.bodyMuted),
                      Text("ETA: $eta", style: AppText.bodyMuted),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // TRIP INFO
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pickup:", style: AppText.h3),
                  Text(pickup, style: AppText.body),
                  const SizedBox(height: AppSpacing.sm),
                  Text("Destination:", style: AppText.h3),
                  Text(destination, style: AppText.body),
                  const SizedBox(height: AppSpacing.sm),
                  Text("Package:", style: AppText.h3),
                  Text(package, style: AppText.body),
                  const SizedBox(height: AppSpacing.sm),
                  Text("Weight:", style: AppText.h3),
                  Text("$weight kg", style: AppText.body),
                  const SizedBox(height: AppSpacing.sm),
                  Text("Price:", style: AppText.h3),
                  Text("₦${price.toStringAsFixed(0)}",
                      style: AppText.body.copyWith(color: AppColors.success)),
                ],
              ),
            ),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {},
              child: const Text("Start Delivery"),
            ),

            const SizedBox(height: AppSpacing.sm),

            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}
