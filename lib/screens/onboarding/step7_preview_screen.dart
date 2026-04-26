import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../main_layout.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';

class Step7PreviewScreen extends StatefulWidget {
  final OnboardingData data;
  const Step7PreviewScreen({super.key, required this.data});

  @override
  State<Step7PreviewScreen> createState() => _Step7PreviewScreenState();
}

class _Step7PreviewScreenState extends State<Step7PreviewScreen> {
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String? imageUrl = widget.data.existingImageUrl;
      if (widget.data.profileImageBytes != null) {
        final ext = widget.data.profileImageType ?? 'jpg';
        final fileName =
            '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage
            .from('avatars')
            .uploadBinary(
              fileName,
              widget.data.profileImageBytes!,
              fileOptions: const FileOptions(upsert: true),
            );
        imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final profileData = {
        'id': user.id,
        'email': user.email,
        'name': widget.data.name,
        'location': widget.data.location,
        'bio': widget.data.consolidatedBio,
        'university': widget.data.university,
        'major': widget.data.major,
        'graduation_year': widget.data.gradYear,
        'interests': widget.data.interestsList,
        'vibe_tags': widget.data.vibes,
        'onboarding_complete': true,
      };
      if (imageUrl != null) {
        profileData['profile_image'] = imageUrl;
      }

      if (widget.data.isEditing) {
        // Safe UPDATE if editing
        await supabase.from('profiles').update(profileData).eq('id', user.id);
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        // Standard UPSERT
        await supabase.from('profiles').upsert(profileData);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.accent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const OnboardingProgressBar(currentStep: 7)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Looks Good?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Here is how your profile will look.',
                style: TextStyle(fontSize: 16, color: AppColors.subtle),
              ),
              const SizedBox(height: 32),

              // Preview Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.inputFill,
                      backgroundImage: widget.data.profileImageBytes != null
                          ? MemoryImage(widget.data.profileImageBytes!)
                          : (widget.data.existingImageUrl != null
                                    ? NetworkImage(
                                        widget.data.existingImageUrl!,
                                      )
                                    : null)
                                as ImageProvider?,
                      child:
                          widget.data.profileImageBytes == null &&
                              widget.data.existingImageUrl == null
                          ? Text(
                              widget.data.name.isNotEmpty
                                  ? widget.data.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.data.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if (widget.data.location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.subtle,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.data.location,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.subtle,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'About',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.data.consolidatedBio.isEmpty
                            ? '--'
                            : widget.data.consolidatedBio,
                        style: const TextStyle(
                          color: AppColors.primary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Vibes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: widget.data.vibes.isEmpty
                          ? const Text('--')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.data.vibes
                                  .map(
                                    (v) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.inputFill,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        v,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              else ...[
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(
                    widget.data.isEditing ? 'Save changes' : 'Looks good',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    widget.data.isEditing ? 'Edit again' : 'Edit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subtle,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
