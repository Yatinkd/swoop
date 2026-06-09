import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CoverPhotoPicker extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final String title;
  final String subtitle;
  final double height;

  const CoverPhotoPicker({
    super.key,
    required this.bytes,
    required this.onPick,
    required this.onRemove,
    this.title = 'Add cover photo',
    this.subtitle = 'Optional — shown on your event card',
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null;

    return GestureDetector(
      onTap: hasImage ? null : onPick,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(bytes!, fit: BoxFit.cover),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _CoverAction(icon: Icons.edit_outlined, onTap: onPick),
                        const SizedBox(width: 8),
                        _CoverAction(icon: Icons.close, onTap: onRemove),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(title, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
      ),
    );
  }
}

class _CoverAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CoverAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
