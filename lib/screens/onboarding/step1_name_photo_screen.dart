import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step2_location_screen.dart';

class Step1NamePhotoScreen extends StatefulWidget {
  final OnboardingData? initialData;
  const Step1NamePhotoScreen({super.key, this.initialData});

  @override
  State<Step1NamePhotoScreen> createState() => _Step1NamePhotoScreenState();
}

class _Step1NamePhotoScreenState extends State<Step1NamePhotoScreen> {
  late OnboardingData data;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    data = widget.initialData ?? OnboardingData();
    _nameController.text = data.name;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          data.profileImageBytes = bytes;
          data.profileImageType = picked.name.split('.').last;
        });
      }
    } catch (_) {}
  }

  Future<void> _next() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Name is required',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.accent,
        ),
      );
      return;
    }
    data.name = _nameController.text.trim();
    final didComplete = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => Step2LocationScreen(data: data)),
    );
    if (!mounted) return;
    if (didComplete == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const OnboardingProgressBar(currentStep: 1),
        leading: data.isEditing
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                data.isEditing
                    ? 'Update your identity'
                    : 'Welcome to Antigravity',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.isEditing
                    ? 'Make any tweaks you need.'
                    : "Let's set up your profile.",
                style: const TextStyle(fontSize: 16, color: AppColors.subtle),
              ),
              const SizedBox(height: 48),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.inputFill,
                        backgroundImage: data.profileImageBytes != null
                            ? MemoryImage(data.profileImageBytes!)
                            : (data.existingImageUrl != null
                                      ? NetworkImage(data.existingImageUrl!)
                                      : null)
                                  as ImageProvider?,
                        child:
                            data.profileImageBytes == null &&
                                data.existingImageUrl == null
                            ? const Icon(
                                Icons.person_outline_rounded,
                                size: 40,
                                color: AppColors.subtle,
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Your Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. Alex Walker'),
                textCapitalization: TextCapitalization.words,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
