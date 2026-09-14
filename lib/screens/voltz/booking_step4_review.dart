import 'package:flutter/material.dart';
import '../../theme/voltz_theme.dart';
import '../../widgets/voltz/voltz_step_indicator.dart';
import 'booking_confirmed_screen.dart';
import 'booking_draft.dart';

/// Booking wizard — step 4 of 4: review the full order before confirming.
class VoltzBookingStep4Review extends StatefulWidget {
  final VoltzBookingDraft draft;
  const VoltzBookingStep4Review({super.key, required this.draft});

  @override
  State<VoltzBookingStep4Review> createState() => _VoltzBookingStep4ReviewState();
}

class _VoltzBookingStep4ReviewState extends State<VoltzBookingStep4Review> {
  bool _confirming = false;

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    // Simulated submit delay — wire to DeliveryService.createDelivery once
    // the booking wizard is connected to real dispatch.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => VoltzBookingConfirmedScreen(draft: widget.draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Theme(
      data: VoltzTheme.dark,
      child: Scaffold(
        backgroundColor: VoltzColors.background,
        appBar: AppBar(title: const Text('New delivery')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(VoltzSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VoltzStepIndicator(
                  currentStep: 4,
                  totalSteps: 4,
                  labels: ['Where', 'Parcel', 'Speed', 'Review'],
                ),
                const SizedBox(height: VoltzSpacing.xl),
                Text('Review your order', style: VoltzText.h1),
                const SizedBox(height: VoltzSpacing.xs),
                Text('Double-check the details before you confirm', style: VoltzText.bodyMuted),
                const SizedBox(height: VoltzSpacing.lg),
                Expanded(
                  child: ListView(
                    children: [
                      _Section(
                        title: 'Route',
                        child: Column(
                          children: [
                            _RouteRow(
                              icon: Icons.trip_origin_rounded,
                              iconColor: VoltzColors.neon,
                              label: 'Pickup',
                              value: draft.pickupAddress,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: EdgeInsets.only(left: 9),
                                child: SizedBox(
                                  height: 16,
                                  child: VerticalDivider(color: VoltzColors.border, width: 1, thickness: 1.4),
                                ),
                              ),
                            ),
                            _RouteRow(
                              icon: Icons.location_on_rounded,
                              iconColor: VoltzColors.danger,
                              label: 'Drop-off',
                              value: draft.dropoffAddress,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: VoltzSpacing.md),
                      _Section(
                        title: 'Parcel',
                        child: Column(
                          children: [
                            _KeyValueRow(label: 'Size', value: draft.parcelSize),
                            _KeyValueRow(label: 'Contents', value: draft.parcelContents),
                            _KeyValueRow(label: 'Speed', value: draft.deliverySpeed),
                            if (draft.addOns.isNotEmpty)
                              _KeyValueRow(label: 'Add-ons', value: draft.addOns.join(', ')),
                          ],
                        ),
                      ),
                      const SizedBox(height: VoltzSpacing.md),
                      _Section(
                        title: 'Price breakdown',
                        child: Column(
                          children: [
                            _KeyValueRow(
                              label: '${draft.deliverySpeed} delivery',
                              value: '₦${draft.basePrice.toStringAsFixed(0)}',
                            ),
                            ...draft.addOns.map((a) => _KeyValueRow(
                                  label: a,
                                  value: '₦${(VoltzBookingDraft.addOnPrice[a] ?? 0).toStringAsFixed(0)}',
                                )),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(color: VoltzColors.border),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total', style: VoltzText.h3),
                                Text('₦${draft.total.toStringAsFixed(0)}',
                                    style: VoltzText.numericMd.copyWith(color: VoltzColors.neon)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirming ? null : _confirm,
                    child: _confirming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: VoltzColors.surfaceSunken,
                            ),
                          )
                        : const Text('Confirm & book'),
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

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoltzSpacing.md),
      decoration: BoxDecoration(
        color: VoltzColors.surface,
        borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
        border: Border.all(color: VoltzColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: VoltzText.label),
          const SizedBox(height: VoltzSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _RouteRow({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: VoltzSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: VoltzText.caption),
              Text(value.isEmpty ? '—' : value, style: VoltzText.body),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  const _KeyValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: VoltzText.bodyMuted),
          Flexible(
            child: Text(value.isEmpty ? '—' : value,
                style: VoltzText.body, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
