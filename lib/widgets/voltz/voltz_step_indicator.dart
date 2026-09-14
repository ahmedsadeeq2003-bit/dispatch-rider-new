import 'package:flutter/material.dart';
import '../../theme/voltz_theme.dart';

/// Horizontal progress indicator for the booking wizard: a row of segments
/// joined by connector lines, filled neon-green up to [currentStep].
/// [currentStep] is 1-indexed (step 1 of [totalSteps]).
class VoltzStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? labels;

  const VoltzStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (i) {
            if (i.isOdd) {
              final connectorDone = (i ~/ 2) + 1 < currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: connectorDone ? VoltzColors.neon : VoltzColors.border,
                ),
              );
            }
            final step = i ~/ 2 + 1;
            final done = step < currentStep;
            final active = step == currentStep;
            return Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active ? VoltzColors.neon : VoltzColors.surfaceRaised,
                border: Border.all(
                  color: done || active ? VoltzColors.neon : VoltzColors.border,
                  width: 1.4,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: VoltzColors.surfaceSunken)
                  : Text(
                      '$step',
                      style: VoltzText.caption.copyWith(
                        color: active ? VoltzColors.surfaceSunken : VoltzColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            );
          }),
        ),
        if (labels != null) ...[
          const SizedBox(height: VoltzSpacing.sm),
          Row(
            children: List.generate(labels!.length, (i) {
              final step = i + 1;
              final active = step == currentStep;
              return Expanded(
                child: Text(
                  labels![i],
                  textAlign: i == 0
                      ? TextAlign.start
                      : (i == labels!.length - 1 ? TextAlign.end : TextAlign.center),
                  style: VoltzText.caption.copyWith(
                    color: active ? VoltzColors.textPrimary : VoltzColors.textMuted,
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
