import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/vibe_tags.dart';
import '../services/event_image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/cover_photo_picker.dart';
import '../widgets/common/vibe_tag_chip.dart';

class CreateHostedEventScreen extends StatefulWidget {
  const CreateHostedEventScreen({super.key});

  @override
  State<CreateHostedEventScreen> createState() => _CreateHostedEventScreenState();
}

class _CreateHostedEventScreenState extends State<CreateHostedEventScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final priceController = TextEditingController();
  final ticketLinkController = TextEditingController();
  final _imageService = EventImageService();
  final _picker = ImagePicker();

  DateTime? selectedDateTime;
  int maxAttendees = 20;
  String? selectedVibe;
  Uint8List? _coverBytes;
  String? _coverExtension;
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    priceController.dispose();
    ticketLinkController.dispose();
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
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';

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
      () => selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  String _formatDt() {
    if (selectedDateTime == null) return 'Pick a date & time';
    final d = selectedDateTime!;
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

  Future<void> _create() async {
    if (titleController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        selectedDateTime == null) {
      _showError('Please fill in all required fields');
      return;
    }
    final price = double.tryParse(priceController.text);
    if (price == null) {
      _showError('Enter a valid ticket price');
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final profile = await supabase
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .single();

      String? imgUrl;
      if (_coverBytes != null) {
        try {
          imgUrl = await _imageService.uploadImage(
            userId: user.id,
            bytes: _coverBytes!,
            fileExtension: _coverExtension ?? 'jpg',
          );
        } catch (e) {
          if (!mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusLg),
              ),
              title: const Text('Image upload failed'),
              content: const Text(
                'We couldn\'t upload your cover photo. You can still create the event without it.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Create without image'),
                ),
              ],
            ),
          );
          if (proceed != true) {
            setState(() => isLoading = false);
            return;
          }
        }
      }

      await supabase.from('hosted_events').insert({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': price,
        'location': locationController.text.trim(),
        'datetime': selectedDateTime!.toIso8601String(),
        'host_id': user.id,
        'host_name': profile['name'] ?? 'Organizer',
        'img_url': imgUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imgUrl != null ? 'Event created with cover photo' : 'Event created',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError('Error creating event: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
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
        title: const Text('Host an Experience'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverPhotoPicker(
              bytes: _coverBytes,
              onPick: _pickCoverImage,
              onRemove: _removeCoverImage,
              title: 'Add event cover',
              subtitle: 'Helps people feel excited to join',
            ),
            const SizedBox(height: 24),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Event title *'),
                  TextField(
                    controller: titleController,
                    style: AppTextStyles.cardTitle,
                    decoration: const InputDecoration(hintText: 'What\'s happening?'),
                  ),
                  const SizedBox(height: 16),
                  _label('Description'),
                  TextField(
                    controller: descriptionController,
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
                  _label('Location *'),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      hintText: 'Where is it?',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('Date & time *'),
                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppColors.radiusSm),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _formatDt(),
                            style: AppTextStyles.body.copyWith(
                              color: selectedDateTime != null
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
                  _label('Ticket price *'),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money, color: AppColors.success),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('Optional ticket link'),
                  TextField(
                    controller: ticketLinkController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.link_outlined, size: 20),
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
                  _label('Maximum attendees'),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('$maxAttendees people', style: AppTextStyles.bodyMedium),
                      ),
                      IconButton(
                        onPressed: maxAttendees > 2
                            ? () => setState(() => maxAttendees--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$maxAttendees', style: AppTextStyles.cardTitle),
                      IconButton(
                        onPressed: maxAttendees < 100
                            ? () => setState(() => maxAttendees++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Vibe tag'),
                  const SizedBox(height: 4),
                  Text(
                    'Helps the right people find your event',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: VibeTags.all.map((v) {
                      final sel = selectedVibe == v.label;
                      return VibeTagChip(
                        label: v.label,
                        selected: sel,
                        onTap: () => setState(() {
                          selectedVibe = sel ? null : v.label;
                        }),
                      );
                    }).toList(),
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
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _create,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Create event'),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: AppTextStyles.label),
      );
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow(0.03),
      ),
      child: child,
    );
  }
}
