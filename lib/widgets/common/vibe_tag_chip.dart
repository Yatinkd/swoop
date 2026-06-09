import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class VibeTagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  const VibeTagChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 9,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : AppColors.card,
        borderRadius: BorderRadius.circular(compact ? 10 : 20),
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w500,
          color: selected ? Colors.white : AppColors.text,
        ),
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}
