import 'package:flutter/material.dart';
import '../../theme/voltz_theme.dart';
import '../../widgets/voltz/voltz_step_indicator.dart';
import 'booking_draft.dart';
import 'booking_step3_speed.dart';

/// Booking wizard — step 2 of 4: parcel size and contents type.
class VoltzBookingStep2Parcel extends StatefulWidget {
  final VoltzBookingDraft draft;
  const VoltzBookingStep2Parcel({super.key, required this.draft});

  @override
  State<VoltzBookingStep2Parcel> createState() => _VoltzBookingStep2ParcelState();
}

class _VoltzBookingStep2ParcelState extends State<VoltzBookingStep2Parcel> {
  static const _sizes = [
    (label: 'Small', hint: 'Fits in a bag', icon: Icons.inbox_rounded),
    (label: 'Medium', hint: 'Shoebox size', icon: Icons.all_inbox_rounded),
    (label: 'Large', hint: 'Suitcase size', icon: Icons.move_to_inbox_rounded),
    (label: 'Extra large', hint: 'Needs two hands', icon: Icons.inventory_2_rounded),
  ];

  static const _contents = [
    'Documents', 'Electronics', 'Food', 'Clothing', 'Fragile items', 'Other',
  ];

  late String _size = widget.draft.parcelSize;
  late String _contentsType = widget.draft.parcelContents;

  bool get _canContinue => _size.isNotEmpty && _contentsType.isNotEmpty;

  void _continue() {
    widget.draft.parcelSize = _size;
    widget.draft.parcelContents = _contentsType;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VoltzBookingStep3Speed(draft: widget.draft)),
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
                  currentStep: 2,
                  totalSteps: 4,
                  labels: ['Where', 'Parcel', 'Speed', 'Review'],
                ),
                const SizedBox(height: VoltzSpacing.xl),
                Text('What are you sending?', style: VoltzText.h1),
                const SizedBox(height: VoltzSpacing.xs),
                Text('Pick a size and tell us what\'s inside', style: VoltzText.bodyMuted),
                const SizedBox(height: VoltzSpacing.lg),
                Expanded(
                  child: ListView(
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: VoltzSpacing.sm,
                        crossAxisSpacing: VoltzSpacing.sm,
                        childAspectRatio: 1.5,
                        children: _sizes.map((s) {
                          final selected = _size == s.label;
                          return _SizeCard(
                            icon: s.icon,
                            label: s.label,
                            hint: s.hint,
                            selected: selected,
                            onTap: () => setState(() => _size = s.label),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: VoltzSpacing.lg),
                      Text('Contents', style: VoltzText.h3),
                      const SizedBox(height: VoltzSpacing.sm),
                      Wrap(
                        spacing: VoltzSpacing.sm,
                        runSpacing: VoltzSpacing.sm,
                        children: _contents.map((c) {
                          final selected = _contentsType == c;
                          return GestureDetector(
                            onTap: () => setState(() => _contentsType = c),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? VoltzColors.neon.withAlpha(28) : VoltzColors.surfaceRaised,
                                borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
                                border: Border.all(
                                  color: selected ? VoltzColors.neon : VoltzColors.border,
                                ),
                              ),
                              child: Text(
                                c,
                                style: VoltzText.caption.copyWith(
                                  color: selected ? VoltzColors.neon : VoltzColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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

class _SizeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _SizeCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(VoltzSpacing.md),
        decoration: BoxDecoration(
          color: selected ? VoltzColors.neon.withAlpha(18) : VoltzColors.surface,
          borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
          border: Border.all(color: selected ? VoltzColors.neon : VoltzColors.border, width: selected ? 1.4 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? VoltzColors.neon : VoltzColors.textSecondary, size: 22),
            const Spacer(),
            Text(label, style: VoltzText.h3),
            Text(hint, style: VoltzText.caption),
          ],
        ),
      ),
    );
  }
}
