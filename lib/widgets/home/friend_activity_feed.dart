import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/activity_feed_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class FriendActivityFeed extends StatelessWidget {
  final List<ActivityFeedItem> items;
  final void Function(ActivityFeedItem)? onTap;

  const FriendActivityFeed({
    super.key,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => _ActivityTile(item: item, onTap: onTap)).toList(),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityFeedItem item;
  final void Function(ActivityFeedItem)? onTap;

  const _ActivityTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(item) : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.chipBg,
              child: Text(
                item.userName.isNotEmpty ? item.userName[0] : '?',
                style: AppTextStyles.caption.copyWith(color: AppColors.text),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                  children: [
                    TextSpan(
                      text: item.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
                    ),
                    TextSpan(text: ' ${item.actionText} '),
                    TextSpan(
                      text: item.planTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              timeago.format(item.timestamp, locale: 'en_short'),
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
