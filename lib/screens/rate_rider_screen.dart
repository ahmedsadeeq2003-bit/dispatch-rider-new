import 'package:flutter/material.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';

/// Pushed with arguments {deliveryId: String, riderName: String?}.
class RateRiderScreen extends StatefulWidget {
  const RateRiderScreen({super.key});

  @override
  State<RateRiderScreen> createState() => _RateRiderScreenState();
}

class _RateRiderScreenState extends State<RateRiderScreen> {
  int _stars = 5;
  bool _submitting = false;
  bool _submitted = false;

  Future<void> _submit(String deliveryId) async {
    setState(() => _submitting = true);
    try {
      await DeliveryService.submitRating(deliveryId, _stars.toDouble());
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final deliveryId = args['deliveryId'] as String;
    final riderName = args['riderName'] as String? ?? 'your rider';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rate Your Rider')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _submitted ? _buildThanks(context) : _buildForm(riderName, deliveryId),
      ),
    );
  }

  Widget _buildThanks(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.success),
          const SizedBox(height: AppSpacing.md),
          Text('Thanks for your feedback!', style: AppText.h2),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(String riderName, String deliveryId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How was your delivery with $riderName?', style: AppText.h2),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your rating helps other clients pick a great rider.',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return IconButton(
                iconSize: 44,
                onPressed: () => setState(() => _stars = i + 1),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.warning,
                ),
              );
            }),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _submitting ? null : () => _submit(deliveryId),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit Rating'),
          ),
        ),
      ],
    );
  }
}
