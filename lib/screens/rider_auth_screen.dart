import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RiderAuthScreen extends StatelessWidget {
  const RiderAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(24),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delivery_dining_rounded,
                    size: 44, color: AppColors.secondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Rider Section', style: AppText.h1, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Login or register as a rider to accept delivery orders.',
                textAlign: TextAlign.center,
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/rider-dashboard');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: const Text('Rider Login'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/rider-register');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.secondary, width: 1.4),
                  foregroundColor: AppColors.secondary,
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: const Text('Rider Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
