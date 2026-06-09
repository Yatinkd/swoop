import 'package:flutter/material.dart';

import '../../constants/vibe_tags.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/plan_cover_image.dart';
import '../common/vibe_tag_chip.dart';

/// Horizontal carousel height — keep in sync with [HomeScreen] list views.
const double kHorizontalPlanCardHeight = 310;

class PlanCard extends StatelessWidget {
  final String title;
  final String? hostName;
  final String? hostImage;
  final String location;
  final String dateTime;
  final int attendeeCount;
  final int? maxSize;
  final String? category;
  final String? coverImage;
  final double? distanceKm;
  final bool showJoinButton;
  final bool horizontal;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  const PlanCard({
    super.key,
    required this.title,
    this.hostName,
    this.hostImage,
    required this.location,
    required this.dateTime,
    required this.attendeeCount,
    this.maxSize,
    this.category,
    this.coverImage,
    this.distanceKm,
    this.showJoinButton = false,
    this.horizontal = false,
    this.onTap,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    if (horizontal) return _buildHorizontal(context);
    return _buildVertical(context);
  }

  Widget _buildHorizontal(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        height: kHorizontalPlanCardHeight,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.softShadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlanCoverImage(
              imageUrl: coverImage,
              category: category,
              title: title,
              height: 130,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category != null) ...[
                      VibeTagChip(
                        label: VibeTags.labelForCategory(category),
                        compact: true,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                    ),
                    if (hostName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'with $hostName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ],
                    const Spacer(),
                    _metaRow(compact: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVertical(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.softShadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PlanCoverImage(
              imageUrl: coverImage,
              category: category,
              title: title,
              height: 200,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (category != null)
                        Flexible(
                          child: VibeTagChip(
                            label: VibeTags.labelForCategory(category),
                            compact: true,
                          ),
                        ),
                      if (distanceKm != null) ...[
                        const Spacer(),
                        Text(
                          '${distanceKm!.toStringAsFixed(1)} km',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                  if (category != null) const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 19),
                  ),
                  if (hostName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Hosted by $hostName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _metaRow(),
                  if (showJoinButton) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onJoin ?? onTap,
                        child: const Text('Join'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow({bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(fontSize: compact ? 11 : 12),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 6),
        Row(
          children: [
            Icon(Icons.schedule_outlined, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                dateTime,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(fontSize: compact ? 11 : 12),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.people_outline, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 2),
            Text(
              maxSize != null ? '$attendeeCount/$maxSize' : '$attendeeCount',
              style: AppTextStyles.caption.copyWith(
                fontSize: compact ? 11 : 12,
                color: AppColors.navyMid,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
