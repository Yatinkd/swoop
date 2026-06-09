import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
/// Lets users add/remove custom vibe tags (max 3 words each).
class ProfileVibeTagsEditor extends StatefulWidget {
  final List<String> initialTags;
  final ValueChanged<List<String>>? onTagsChanged;

  const ProfileVibeTagsEditor({
    super.key,
    required this.initialTags,
    this.onTagsChanged,
  });

  @override
  State<ProfileVibeTagsEditor> createState() => _ProfileVibeTagsEditorState();
}

class _ProfileVibeTagsEditorState extends State<ProfileVibeTagsEditor> {
  static const _maxTags = 8;

  late List<String> _tags;
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.initialTags);
  }

  @override
  void didUpdateWidget(ProfileVibeTagsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTags != widget.initialTags) {
      _tags = List<String>.from(widget.initialTags);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidVibe(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return false;
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return words.length <= 3;
  }

  String _normalizeVibe(String raw) {
    return raw.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).join(' ');
  }

  Future<void> _persist() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'vibe_tags': _tags})
          .eq('id', userId);
      widget.onTagsChanged?.call(_tags);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save vibe tags: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addTag() async {
    final vibe = _normalizeVibe(_controller.text);
    if (!_isValidVibe(vibe)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keep vibes short — 3 words max'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_tags.length >= _maxTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can add up to $_maxTags vibe tags'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_tags.any((t) => t.toLowerCase() == vibe.toLowerCase())) {
      _controller.clear();
      return;
    }

    setState(() => _tags = [..._tags, vibe]);
    _controller.clear();
    await _persist();
  }

  Future<void> _removeTag(String tag) async {
    setState(() => _tags.remove(tag));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vibe tags', style: AppTextStyles.label),
        const SizedBox(height: 6),
        Text(
          'Add short tags that describe your energy — 3 words max each.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 12),
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return InputChip(
                label: Text(tag, style: AppTextStyles.caption.copyWith(color: AppColors.navy)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: _saving ? null : () => _removeTag(tag),
                backgroundColor: AppColors.card,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          )
        else
          Text('No vibe tags yet', style: AppTextStyles.bodySmall),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textBody),
                decoration: const InputDecoration(
                  hintText: 'e.g. Cafe Hopper',
                  isDense: true,
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _addTag,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
