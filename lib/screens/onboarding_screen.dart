import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final interestsController = TextEditingController();
  final locationController = TextEditingController();
  String? selectedVibe;
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  final vibes = ['Chill', 'Party', 'Study', 'Adventure', 'Food', 'Sports'];

  Future<void> saveProfile() async {
    if (nameController.text.trim().isEmpty || selectedVibe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Name and Vibe are required'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final profileData = {
        'id': user.id,
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'interests': interestsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'location': locationController.text.trim(),
        'vibe_tag': selectedVibe,
        'email': user.email,
        'onboarding_complete': true,
      };

      await supabase.from('profiles').upsert(profileData);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e'), backgroundColor: AppColors.accent),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Set up your\nprofile', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary, height: 1.2)),
              const SizedBox(height: 8),
              Text('Tell people who you are', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
              const SizedBox(height: 40),

              _label('Your name'),
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'What should people call you?')),
              const SizedBox(height: 20),

              _label('Short bio'),
              TextField(controller: bioController, maxLines: 2, decoration: const InputDecoration(hintText: 'A few words about yourself...')),
              const SizedBox(height: 20),

              _label('Interests'),
              TextField(controller: interestsController, decoration: const InputDecoration(hintText: 'music, hiking, coffee (comma separated)')),
              const SizedBox(height: 20),

              _label('Location'),
              TextField(controller: locationController, decoration: const InputDecoration(hintText: 'Your city')),
              const SizedBox(height: 28),

              _label('Your vibe'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: vibes.map((v) {
                  final selected = selectedVibe == v;
                  return GestureDetector(
                    onTap: () => setState(() => selectedVibe = v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
                      ),
                      child: Text(v, style: TextStyle(
                        color: selected ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveProfile,
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save & Continue'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subtle, letterSpacing: 0.5)),
    );
  }
}
