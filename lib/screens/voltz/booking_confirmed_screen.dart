import 'dart:math';

import 'package:flutter/material.dart';
import '../../theme/voltz_theme.dart';
import 'booking_draft.dart';

/// Booking wizard — final screen: success checkmark, order reference, and
/// a CO2-saved banner reflecting the choice made in step 3.
class VoltzBookingConfirmedScreen extends StatelessWidget {
  final VoltzBookingDraft draft;
  const VoltzBookingConfirmedScreen({super.key, required this.draft});

  String get _orderRef {
    final rnd = Random(identityHashCode(draft));
    final n = 100000 + rnd.nextInt(899999);
    return 'VLTZ-$n';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: VoltzTheme.dark,
      child: Scaffold(
        backgroundColor: VoltzColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(VoltzSpacing.lg),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: VoltzColors.neon,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 52, color: VoltzColors.surfaceSunken),
                ),
                const SizedBox(height: VoltzSpacing.lg),
                Text('Delivery booked', style: VoltzText.h1, textAlign: TextAlign.center),
                const SizedBox(height: VoltzSpacing.xs),
                Text(
                  'A rider will be assigned shortly. You can track progress from Active deliveries.',
                  style: VoltzText.bodyMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VoltzSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: VoltzColors.surface,
                    borderRadius: BorderRadius.circular(VoltzSpacing.radiusPill),
                    border: Border.all(color: VoltzColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 16, color: VoltzColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(_orderRef,
                          style: VoltzText.body.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                    ],
                  ),
                ),
                const SizedBox(height: VoltzSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(VoltzSpacing.md),
                  decoration: BoxDecoration(
                    color: VoltzColors.neon.withAlpha(18),
                    borderRadius: BorderRadius.circular(VoltzSpacing.radiusLg),
                    border: Border.all(color: VoltzColors.neon.withAlpha(70)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco_rounded, color: VoltzColors.neon),
                      const SizedBox(width: VoltzSpacing.md),
                      Expanded(
                        child: Text(
                          'This delivery is estimated to save 1.1 kg of CO2 versus a solo car trip.',
                          style: VoltzText.caption.copyWith(color: VoltzColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
