import 'package:flutter/material.dart';
import '../../theme/voltz_theme.dart';
import '../../widgets/voltz/voltz_pill_tag.dart';
import '../../widgets/voltz/voltz_step_indicator.dart';
import 'booking_draft.dart';
import 'booking_step4_review.dart';

/// Booking wizard — step 3 of 4: delivery speed and optional add-ons.
class VoltzBookingStep3Speed extends StatefulWidget {
  final VoltzBookingDraft draft;
  const VoltzBookingStep3Speed({super.key, required this.draft});

  @override
  State<VoltzBookingStep3Speed> createState() => _VoltzBookingStep3SpeedState();
}

class _VoltzBookingStep3SpeedState extends State<VoltzBookingStep3Speed> {
  static const _speeds = [
    (label: 'Express', hint: 'Arrives in under 1 hour', icon: Icons.bolt_rounded),
    (label: 'Standard', hint: 'Arrives today', icon: Icons.schedule_rounded),
    (label: 'Scheduled', hint: 'Pick a time that works for you', icon: Icons.event_rounded),
  ];

  late String _speed =
      widget.draft.deliverySpeed.isNotEmpty ? widget.draft.deliverySpeed : 'Standard';
  final Set<String> _addOns = {};

  @override
  void initState() {
    super.initState();
    _addOns.addAll(widget.draft.addOns);
  }

  void _continue() {
    widget.draft.deliverySpeed = _speed;
    widget.draft.addOns = _addOns;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VoltzBookingStep4Review(draft: widget.draft)),
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
                  currentStep: 3,
                  totalSteps: 4,
                  labels: ['Where', 'Parcel', 'Speed', 'Review'],
                ),
                const SizedBox(height: VoltzSpacing.xl),
                Text('How fast do you need it?', style: VoltzText.h1),
                const SizedBox(height: VoltzSpacing.xs),
                Text('Choose a delivery speed and any add-ons', style: VoltzText.bodyMuted),
                const SizedBox(height: VoltzSpacing.lg),
                Expanded(
                  child: ListView(
                    children: [
                      ..._speeds.map((s) {
                        final selected = _speed == s.label;
                        final price = VoltzBookingDraft.speedBasePrice[s.label] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: VoltzSpacing.sm),
                          child: GestureDetector(
                            onTap: () => setState(() => _speed = s.label),
                            child: Container(
                              padding: const EdgeInsets.all(VoltzSpacing.md),
                              decoration: BoxDecoration(
                                color: selected ? VoltzColors.neon.withAlpha(18) : VoltzColors.surface,
                                borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
                                border: Border.all(
                                  color: selected ? VoltzColors.neon : VoltzColors.border,
                                  width: selected ? 1.4 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(s.icon, color: selected ? VoltzColors.neon : VoltzColors.textSecondary),
                                  const SizedBox(width: VoltzSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(s.label, style: VoltzText.h3),
                                            const SizedBox(width: VoltzSpacing.sm),
                                            if (s.label == 'Express') const VoltzPillTag(text: 'FASTEST'),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(s.hint, style: VoltzText.caption),
                                      ],
                                    ),
                                  ),
                                  Text('₦${price.toStringAsFixed(0)}',
                                      style: VoltzText.numericMd.copyWith(fontSize: 15)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: VoltzSpacing.md),
                      Text('Add-ons', style: VoltzText.h3),
                      const SizedBox(height: VoltzSpacing.sm),
                      ...VoltzBookingDraft.addOnPrice.entries.map((entry) {
                        final checked = _addOns.contains(entry.key);
                        return Container(
                          margin: const EdgeInsets.only(bottom: VoltzSpacing.sm),
                          decoration: BoxDecoration(
                            color: VoltzColors.surface,
                            borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
                            border: Border.all(color: VoltzColors.border),
                          ),
                          child: CheckboxListTile(
                            value: checked,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _addOns.add(entry.key);
                              } else {
                                _addOns.remove(entry.key);
                              }
                            }),
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(entry.key, style: VoltzText.body),
                            secondary: Text('+₦${entry.value.toStringAsFixed(0)}', style: VoltzText.caption),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _continue,
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
