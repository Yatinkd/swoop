import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/event_cover_image.dart';

class HostedEventCard extends StatelessWidget {
  final String title;
  final String hostName;
  final String location;
  final String dateTime;
  final double price;
  final String? imageUrl;
  final VoidCallback? onTap;

  const HostedEventCard({
    super.key,
    required this.title,
    required this.hostName,
    required this.location,
    required this.dateTime,
    required this.price,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          children: [
            EventCoverImage(
              imageUrl: imageUrl,
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
                      Text(hostName, style: AppTextStyles.caption),
                      const Spacer(),
                      _priceBadge(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(title, style: AppTextStyles.cardTitle.copyWith(fontSize: 20)),
                  const SizedBox(height: 14),
                  _infoRow(Icons.location_on_outlined, location),
                  const SizedBox(height: 8),
                  _infoRow(Icons.schedule_outlined, dateTime),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        price == 0 ? 'FREE' : '\$${price.toStringAsFixed(2)}',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
