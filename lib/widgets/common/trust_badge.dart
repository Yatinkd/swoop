import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class TrustBadge extends StatelessWidget {
  final UserProfile profile;
  final bool compact;

  const TrustBadge({super.key, required this.profile, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            profile.rating.toStringAsFixed(1),
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hosted ${profile.plansHosted} · Joined ${profile.plansJoined}'
              '${profile.isVerified ? ' · Verified' : ''}',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}
