import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Displays a hosted event cover from [imageUrl] with a calm placeholder fallback.
class EventCoverImage extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final double height;
  final BorderRadius? borderRadius;

  const EventCoverImage({
    super.key,
    this.imageUrl,
    this.title,
    this.height = 180,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ??
        const BorderRadius.vertical(top: Radius.circular(AppColors.radiusLg));

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _placeholder(showLoader: true);
                },
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder({bool showLoader = false}) {
    return Container(
      color: AppColors.bgSecondary,
      child: Center(
        child: showLoader
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 36,
                    color: AppColors.textSecondary.withValues(alpha: 0.35),
                  ),
                  if (title != null && title!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
