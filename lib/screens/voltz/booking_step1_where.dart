import 'package:flutter/material.dart';
import '../../theme/voltz_theme.dart';
import '../../widgets/voltz/voltz_step_indicator.dart';
import 'booking_draft.dart';
import 'booking_step2_parcel.dart';

/// Booking wizard — step 1 of 4: pickup and dropoff addresses.
class VoltzBookingStep1Where extends StatefulWidget {
  final VoltzBookingDraft? draft;
  const VoltzBookingStep1Where({super.key, this.draft});

  @override
  State<VoltzBookingStep1Where> createState() => _VoltzBookingStep1WhereState();
}

class _VoltzBookingStep1WhereState extends State<VoltzBookingStep1Where> {
  late final VoltzBookingDraft _draft = widget.draft ?? VoltzBookingDraft();
  late final _pickupController = TextEditingController(text: _draft.pickupAddress);
  late final _dropoffController = TextEditingController(text: _draft.dropoffAddress);

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _pickupController.text.trim().isNotEmpty && _dropoffController.text.trim().isNotEmpty;

  void _continue() {
    _draft.pickupAddress = _pickupController.text.trim();
    _draft.dropoffAddress = _dropoffController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VoltzBookingStep2Parcel(draft: _draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  currentStep: 1,
                  totalSteps: 4,
                  labels: ['Where', 'Parcel', 'Speed', 'Review'],
                ),
                const SizedBox(height: VoltzSpacing.xl),
                Text('Where is it going?', style: VoltzText.h1),
                const SizedBox(height: VoltzSpacing.xs),
                Text('Enter the pickup and drop-off points', style: VoltzText.bodyMuted),
                const SizedBox(height: VoltzSpacing.lg),
                Expanded(
                  child: ListView(
                    children: [
                      _AddressField(
                        icon: Icons.trip_origin_rounded,
                        iconColor: VoltzColors.neon,
                        label: 'Pickup address',
                        controller: _pickupController,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: VoltzSpacing.md),
                      _AddressField(
                        icon: Icons.location_on_rounded,
                        iconColor: VoltzColors.danger,
                        label: 'Drop-off address',
                        controller: _dropoffController,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canContinue ? _continue : null,
                    child: const Text('Continue'),
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

class _AddressField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _AddressField({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VoltzSpacing.md),
      decoration: BoxDecoration(
        color: VoltzColors.surfaceRaised,
        borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
        border: Border.all(color: VoltzColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: VoltzSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: VoltzText.body,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                labelText: label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
