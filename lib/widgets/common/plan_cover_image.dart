import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PlanCoverImage extends StatelessWidget {
  final String? imageUrl;
  final String? category;
  final String title;
  final double height;

  const PlanCoverImage({
    super.key,
    this.imageUrl,
    this.category,
    required this.title,
    this.height = 160,
  });

  IconData get _categoryIcon {
    return switch (category?.toLowerCase()) {
      'food' => Icons.local_cafe_outlined,
      'sports' => Icons.sports_tennis_outlined,
      'party' || 'concert' => Icons.music_note_outlined,
      'study' => Icons.menu_book_outlined,
      'chill' => Icons.nightlife_outlined,
      'adventure' => Icons.terrain_outlined,
      _ => Icons.event_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppColors.radiusLg)),
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
      color: AppColors.inputFill,
      child: Center(
        child: showLoader
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _categoryIcon,
                size: 32,
                color: AppColors.textSecondary.withValues(alpha: 0.4),
              ),
      ),
    );
  }
}
