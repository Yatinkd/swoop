import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.sectionHeading.copyWith(fontSize: 18)),
          const Spacer(),
          if (trailing != null)
            Text(trailing!, style: AppTextStyles.caption),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.text,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.border,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
