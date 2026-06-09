import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/vibe_tag_chip.dart';

/// Height for the home-screen people carousel — keep in sync with [HomeScreen].
const double kRecommendedPersonCardHeight = 188;

class RecommendedPersonCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onTap;

  const RecommendedPersonCard({
    super.key,
    required this.profile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = profile.name.trim().isEmpty
        ? '?'
        : profile.name.trim()[0].toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: kRecommendedPersonCardHeight,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.softShadow(0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.bgSecondary,
                  backgroundImage: profile.profileImage != null
                      ? NetworkImage(profile.profileImage!)
                      : null,
                  child: profile.profileImage == null
                      ? Text(initials, style: AppTextStyles.bodyMedium)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '★ ${profile.rating.toStringAsFixed(1)}',
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (profile.vibeMatchPercent > 0)
              Text(
                '${profile.vibeMatchPercent}% vibe match',
                style: AppTextStyles.caption.copyWith(color: AppColors.navyMid),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const Spacer(),
            if (profile.vibeTags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.vibeTags
                    .take(2)
                    .map(
                      (t) => VibeTagChip(
                        label: t,
                        compact: true,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
