import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class QuickActionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const QuickActionChip({
    super.key,
    required this.label,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(
            color: isPrimary ? AppColors.accent : AppColors.border,
          ),
          boxShadow: isPrimary ? null : AppColors.softShadow(0.03),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isPrimary ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}
