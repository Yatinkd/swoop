import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'main_layout.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final bioController = TextEditingController();
  Uint8List? _profileImageBytes;
  String? _profileImageType;

  // Step 2
  final universityController = TextEditingController();
  final majorController = TextEditingController();
  final gradYearController = TextEditingController();

  // Step 3
  final interestsController = TextEditingController();
  List<String> selectedVibes = [];
  final vibes = ['Chill', 'Party', 'Study', 'Adventure', 'Food', 'Sports'];

  bool isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _profileImageBytes = bytes;
          _profileImageType = picked.name.split('.').last;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _nextPage() {
    if (_currentPage == 0 && (nameController.text.trim().isEmpty || bioController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Bio are absolutely required!'), backgroundColor: AppColors.accent));
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevPage() => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  Future<void> saveProfile() async {
    if (selectedVibes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick at least one vibe!'), backgroundColor: AppColors.accent));
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String? imageUrl;
      if (_profileImageBytes != null) {
        final ext = _profileImageType ?? 'jpg';
        final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from('avatars').uploadBinary(fileName, _profileImageBytes!, fileOptions: const FileOptions(upsert: true));
        imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final profileData = {
        'id': user.id,
        'email': user.email,
        'name': nameController.text.trim(),
        'location': locationController.text.trim(),
        'bio': bioController.text.trim(),
        'university': universityController.text.trim(),
        'major': majorController.text.trim(),
        'graduation_year': gradYearController.text.trim(),
        'interests': interestsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'vibe_tags': selectedVibes,
        if (imageUrl != null) 'profile_image': imageUrl,
        'onboarding_complete': true,
      };

      await supabase.from('profiles').upsert(profileData);
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.accent));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: _currentPage > 0 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage) : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 30, height: 4,
            decoration: BoxDecoration(color: index <= _currentPage ? AppColors.primary : AppColors.divider, borderRadius: BorderRadius.circular(2)),
          )),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [_step1Basics(), _step2College(), _step3Vibe()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : (_currentPage == 2 ? saveProfile : _nextPage),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_currentPage == 2 ? 'Save & Continue' : 'Next'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _step1Basics() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.inputFill,
              backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
              child: _profileImageBytes == null ? const Icon(Icons.add_a_photo, size: 30, color: AppColors.subtle) : null,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text('The Basics', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text("Let's start with who you are", style: TextStyle(fontSize: 16, color: AppColors.subtle)),
        const SizedBox(height: 40),
        _label('Your name *'),
        TextField(controller: nameController, decoration: const InputDecoration(hintText: 'What should people call you?')),
        const SizedBox(height: 20),
        _label('Location'),
        TextField(controller: locationController, decoration: const InputDecoration(hintText: 'City, Neighborhood')),
        const SizedBox(height: 20),
        _label('Short bio *'),
        TextField(controller: bioController, maxLines: 3, decoration: const InputDecoration(hintText: 'A few things about you...')),
      ],
    ),
  );

  Widget _step2College() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('College Info', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text('Connect with students & alumni', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
        const SizedBox(height: 40),
        _label('University'),
        TextField(controller: universityController, decoration: const InputDecoration(hintText: 'e.g. NYU, UCLA')),
        const SizedBox(height: 20),
        _label('Major / Course'),
        TextField(controller: majorController, decoration: const InputDecoration(hintText: 'e.g. Computer Science')),
        const SizedBox(height: 20),
        _label('Graduation Year'),
        TextField(controller: gradYearController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 2026')),
      ],
    ),
  );

  Widget _step3Vibe() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('The Vibe', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text('What are you looking for?', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
        const SizedBox(height: 40),
        _label('Interests'),
        TextField(controller: interestsController, decoration: const InputDecoration(hintText: 'music, hiking, coffee (comma separated)')),
        const SizedBox(height: 28),
        _label('Your Vibes * (Select all that apply)'),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: vibes.map((v) {
            final sel = selectedVibes.contains(v);
            return GestureDetector(
              onTap: () => setState(() {
                if (sel) selectedVibes.remove(v);
                else selectedVibes.add(v);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(30), border: Border.all(color: sel ? AppColors.primary : AppColors.divider),
                ),
                child: Text(v, style: TextStyle(color: sel ? Colors.white : AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subtle, letterSpacing: 0.5)),
  );
}
