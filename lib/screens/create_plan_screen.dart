import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../services/plan_image_service.dart';
import '../theme/app_text_styles.dart';

class CreatePlanScreen extends StatefulWidget {
  final String? initialVibe;

  const CreatePlanScreen({super.key, this.initialVibe});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageService = PlanImageService();
  final _picker = ImagePicker();

  DateTime? _selectedDateTime;
  late String? _selectedVibe;
  int _maxSize = 5;
  bool _isLoading = false;
  Uint8List? _coverBytes;
  String? _coverExtension;

  final supabase = Supabase.instance.client;
  final _vibes = ['Chill', 'Party', 'Study', 'Adventure', 'Food', 'Sports'];

  @override
  void initState() {
    super.initState();
    _selectedVibe = widget.initialVibe;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last
          : 'jpg';

      setState(() {
        _coverBytes = bytes;
        _coverExtension = ext;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Could not pick image: $e');
    }
  }

  void _removeCoverImage() {
    setState(() {
      _coverBytes = null;
      _coverExtension = null;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(
      () => _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  String _formatDt() {
    if (_selectedDateTime == null) return 'Pick a date & time';
    final d = _selectedDateTime!;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour;
    final min = d.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${d.day} ${months[d.month - 1]}, $h12:$min $amPm';
  }

  Future<void> _createPlan() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Plan title is required');
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      _showError('Location is required');
      return;
    }
    if (_selectedDateTime == null) {
      _showError('Date and time are required');
      return;
    }
    if (_selectedVibe == null) {
      _showError('Please select a vibe');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final profile = await supabase
          .from('profiles')
          .select('name, profile_image')
          .eq('id', user.id)
          .single();

      String? coverImageUrl;
      if (_coverBytes != null) {
        coverImageUrl = await _imageService.uploadCover(
          userId: user.id,
          bytes: _coverBytes!,
          fileExtension: _coverExtension ?? 'jpg',
        );
      }

      await supabase.from('plans').insert({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'datetime': _selectedDateTime!.toIso8601String(),
        'host_id': user.id,
        'host_name': profile['name'] ?? 'Anonymous',
        'host_image': profile['profile_image'],
        'vibe': _selectedVibe,
        'category': _selectedVibe,
        'max_size': _maxSize,
        'participants': [user.id],
        'cover_image': coverImageUrl,
        'is_boosted': false,
        'is_sponsored': false,
        'status': 'active',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            coverImageUrl != null ? 'Plan posted with photo' : 'Plan created',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('plan-covers') || msg.contains('Bucket not found')) {
        _showError(
          'Photo upload failed. Create the plan-covers bucket in Supabase '
          '(see supabase/storage_plan_covers.sql) and try again.',
        );
      } else {
        _showError('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('New Plan'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPlan,
            child: Text(
              'Post',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoverPhotoPicker(
              bytes: _coverBytes,
              onPick: _pickCoverImage,
              onRemove: _removeCoverImage,
            ),
            const SizedBox(height: 20),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('What\'s the plan? *'),
                  TextField(
                    controller: _titleController,
                    style: AppTextStyles.cardTitle,
                    decoration: const InputDecoration(hintText: 'Give it a name'),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Description'),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    minLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'What should people expect?',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Where? *'),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'Location or venue',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('When? *'),
                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _formatDt(),
                            style: AppTextStyles.body.copyWith(
                              color: _selectedDateTime != null
                                  ? AppColors.text
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Category *'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _vibes.map((v) {
                      final sel = _selectedVibe == v;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedVibe = sel ? null : v),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.accent : AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel ? AppColors.accent : AppColors.border,
                            ),
                          ),
                          child: Text(
                            v,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: sel ? Colors.white : AppColors.text,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Max group size *'),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('$_maxSize people', style: AppTextStyles.bodyMedium),
                      ),
                      IconButton(
                        onPressed: _maxSize > 2 ? () => setState(() => _maxSize--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_maxSize', style: AppTextStyles.cardTitle),
                      IconButton(
                        onPressed: _maxSize < 20 ? () => setState(() => _maxSize++) : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createPlan,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Post plan'),
          ),
        ),
      ),
    );
  }
}

class _CoverPhotoPicker extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _CoverPhotoPicker({
    required this.bytes,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null;

    return GestureDetector(
      onTap: hasImage ? null : onPick,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(bytes!, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _CoverAction(
                          icon: Icons.edit_outlined,
                          onTap: onPick,
                        ),
                        const SizedBox(width: 8),
                        _CoverAction(
                          icon: Icons.close,
                          onTap: onRemove,
                        ),
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
                    size: 32,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add cover photo',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.text),
                  ),
                  Text(
                    'Optional — shown on your plan card',
                    style: AppTextStyles.caption,
                  ),
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
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTextStyles.label),
      );
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
