import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Senditt', style: AppText.h1),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    ),
                    child: Text('English', style: AppText.caption),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Scrollable middle section (animation + tagline) so small
              // screens never overflow — the buttons below stay pinned.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Lottie.asset(
                        'assets/animations/Delivery Riding.json',
                        height: 220,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Deliveries Made Simple',
                        style: AppText.h1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Fast, safe, and reliable dispatch service for everyone.',
                        style: AppText.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),

              // Buttons — always visible, never pushed off-screen
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/dispatch');
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Sign Up'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/rider');
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      side: const BorderSide(
                          color: AppColors.secondary, width: 1.4),
                      foregroundColor: AppColors.secondary,
                    ),
                    child: const Text('Rider'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
