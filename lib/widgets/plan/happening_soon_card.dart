import 'package:flutter/material.dart';

import '../../models/plan.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/plan_formatters.dart';

class HappeningSoonCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;

  const HappeningSoonCard({
    super.key,
    required this.plan,
    this.onJoin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spotsLeft = plan.spotsLeft;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: double.infinity,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              PlanFormatters.formatCountdown(plan.datetime),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 2),
            Text(
              spotsLeft > 0
                  ? 'Need $spotsLeft more'
                  : 'Almost full',
              style: AppTextStyles.caption,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: onJoin ?? onTap,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
