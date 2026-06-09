import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SwoopEmptyState extends StatelessWidget {
  final String headline;
  final String subheadline;
  final String? primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const SwoopEmptyState({
    super.key,
    required this.headline,
    required this.subheadline,
    this.primaryLabel,
    this.secondaryLabel,
    this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          Text(subheadline, style: AppTextStyles.bodySmall),
          if (primaryLabel != null || secondaryLabel != null) ...[
            const SizedBox(height: 20),
            if (primaryLabel != null)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onPrimary,
                  child: Text(primaryLabel!),
                ),
              ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
