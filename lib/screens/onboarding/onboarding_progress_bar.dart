import 'package:flutter/material.dart';
import '../../main.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: index < currentStep ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
