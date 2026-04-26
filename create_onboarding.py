import os

os.makedirs("lib/screens/onboarding", exist_ok=True)

data_content = """import 'dart:typed_data';

class OnboardingData {
  String name = '';
  Uint8List? profileImageBytes;
  String? profileImageType;
  String location = '';
  String bio = '';
  List<String> vibes = [];
  String interests = '';
  String university = '';
  String major = '';
  String gradYear = '';
}"""
with open("lib/screens/onboarding/onboarding_data.dart", "w") as f: f.write(data_content)

progress_bar_content = """import 'package:flutter/material.dart';
import '../../main.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressBar({Key? key, required this.currentStep, this.totalSteps = 7}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 30, height: 4,
          decoration: BoxDecoration(
            color: index < currentStep ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}"""
with open("lib/screens/onboarding/onboarding_progress_bar.dart", "w") as f: f.write(progress_bar_content)

step1_content = """import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step2_location_screen.dart';

class Step1NamePhotoScreen extends StatefulWidget {
  final OnboardingData? initialData;
  const Step1NamePhotoScreen({Key? key, this.initialData}) : super(key: key);

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
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          data.profileImageBytes = bytes;
          data.profileImageType = picked.name.split('.').last;
        });
      }
    } catch (_) {}
  }

  void _next() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    data.name = _nameController.text.trim();
    Navigator.push(context, MaterialPageRoute(builder: (_) => Step2LocationScreen(data: data)));
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
        leading: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Welcome to Antigravity', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text('Let\\'s set up your identity.', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
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
                        backgroundImage: data.profileImageBytes != null ? MemoryImage(data.profileImageBytes!) : null,
                        child: data.profileImageBytes == null ? const Icon(Icons.person_outline_rounded, size: 40, color: AppColors.subtle) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.add_a_photo_rounded, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Text('Your Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
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
}"""
with open("lib/screens/onboarding/step1_name_photo_screen.dart", "w") as f: f.write(step1_content)

step2_content = """import 'package:flutter/material.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step3_bio_screen.dart';

class Step2LocationScreen extends StatefulWidget {
  final OnboardingData data;
  const Step2LocationScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<Step2LocationScreen> createState() => _Step2LocationScreenState();
}

class _Step2LocationScreenState extends State<Step2LocationScreen> {
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.data.location;
  }

  void _next() {
    widget.data.location = _locationController.text.trim();
    Navigator.push(context, MaterialPageRoute(builder: (_) => Step3BioScreen(data: widget.data)));
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const OnboardingProgressBar(currentStep: 2),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Where are you based?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text('Find events and people near your location.', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
              const SizedBox(height: 48),
              const Text('Your Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(hintText: 'City, Neighborhood'),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    // Logic to auto-detect mock
                    _locationController.text = 'San Francisco, CA';
                  },
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('Auto-detect location', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
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
}"""
with open("lib/screens/onboarding/step2_location_screen.dart", "w") as f: f.write(step2_content)

step3_content = """import 'package:flutter/material.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step4_vibes_screen.dart';

class Step3BioScreen extends StatefulWidget {
  final OnboardingData data;
  const Step3BioScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<Step3BioScreen> createState() => _Step3BioScreenState();
}

class _Step3BioScreenState extends State<Step3BioScreen> {
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bioController.text = widget.data.bio;
  }

  void _next() {
    widget.data.bio = _bioController.text.trim();
    Navigator.push(context, MaterialPageRoute(builder: (_) => Step4VibesScreen(data: widget.data)));
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const OnboardingProgressBar(currentStep: 3),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Write a short bio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text('A small blurb about what you like.', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
              const SizedBox(height: 48),
              const Text('Your Bio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(hintText: 'I love trying new coffee spots...', counterText: ""),
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
}"""
with open("lib/screens/onboarding/step3_bio_screen.dart", "w") as f: f.write(step3_content)

step4_content = """import 'package:flutter/material.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step5_interests_screen.dart';

class Step4VibesScreen extends StatefulWidget {
  final OnboardingData data;
  const Step4VibesScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<Step4VibesScreen> createState() => _Step4VibesScreenState();
}

class _Step4VibesScreenState extends State<Step4VibesScreen> {
  final List<String> _allVibes = ['Chill', 'Party', 'Study', 'Adventure', 'Food', 'Sports'];
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.data.vibes);
  }

  void _next() {
    widget.data.vibes = _selected;
    Navigator.push(context, MaterialPageRoute(builder: (_) => Step5InterestsScreen(data: widget.data)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const OnboardingProgressBar(currentStep: 4),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('What are your vibes?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text('Select all that match your energy.', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
              const SizedBox(height: 48),
              Wrap(
                spacing: 12,
                runSpacing: 16,
                children: _allVibes.map((v) {
                  final isSel = _selected.contains(v);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSel) _selected.remove(v);
                        else _selected.add(v);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: isSel ? AppColors.primary : AppColors.divider),
                      ),
                      child: Text(
                        v,
                        style: TextStyle(
                          color: isSel ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected.isNotEmpty ? _next : null,
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
}"""
with open("lib/screens/onboarding/step4_vibes_screen.dart", "w") as f: f.write(step4_content)

step5_content = """import 'package:flutter/material.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step6_college_screen.dart';

class Step5InterestsScreen extends StatefulWidget {
  final OnboardingData data;
  const Step5InterestsScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<Step5InterestsScreen> createState() => _Step5InterestsScreenState();
}

class _Step5InterestsScreenState extends State<Step5InterestsScreen> {
  final _interestsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _interestsController.text = widget.data.interests;
  }

  void _next() {
    widget.data.interests = _interestsController.text.trim();
    Navigator.push(context, MaterialPageRoute(builder: (_) => Step6CollegeScreen(data: widget.data)));
  }

  @override
  void dispose() {
    _interestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const OnboardingProgressBar(currentStep: 5),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Any specific interests?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text('Optional. Comma separated list.', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
              const SizedBox(height: 48),
              const Text('Interests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 8),
              TextField(
                controller: _interestsController,
                decoration: const InputDecoration(hintText: 'music, film, deep talks'),
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
}"""
with open("lib/screens/onboarding/step5_interests_screen.dart", "w") as f: f.write(step5_content)

step6_content = """import 'package:flutter/material.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step7_preview_screen.dart';

class Step6CollegeScreen extends StatefulWidget {
  final OnboardingData data;
  const Step6CollegeScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<Step6CollegeScreen> createState() => _Step6CollegeScreenState();
}

class _Step6CollegeScreenState extends State<Step6CollegeScreen> {
  final _uniController = TextEditingController();
  final _majorController = TextEditingController();
  final _gradYearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _uniController.text = widget.data.university;
    _majorController.text = widget.data.major;
    _gradYearController.text = widget.data.gradYear;
  }

  void _next() {
    widget.data.university = _uniController.text.trim();
    widget.data.major = _majorController.text.trim();
    widget.data.gradYear = _gradYearController.text.trim();
    Navigator.push(context, MaterialPageRoute(builder: (_) => Step7PreviewScreen(data: widget.data)));
  }

  @override
  void dispose() {
    _uniController.dispose();
    _majorController.dispose();
    _gradYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const OnboardingProgressBar(currentStep: 6),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('College Info', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text('Optional. Connect with alumni.', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
              const SizedBox(height: 48),
              const Text('University', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 8),
              TextField(controller: _uniController, decoration: const InputDecoration(hintText: 'e.g. Stanford University')),
              const SizedBox(height: 24),
              const Text('Major', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 8),
              TextField(controller: _majorController, decoration: const InputDecoration(hintText: 'e.g. Computer Science')),
              const SizedBox(height: 24),
              const Text('Graduation Year', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 8),
              TextField(controller: _gradYearController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 2026')),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: const Text('Review Profile'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}"""
with open("lib/screens/onboarding/step6_college_screen.dart", "w") as f: f.write(step6_content)

step7_content = """import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../main_layout.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';

class Step7PreviewScreen extends StatefulWidget {
  final OnboardingData data;
  const Step7PreviewScreen({Key? key, required this.data}) : super(key: key);

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

      String? imageUrl;
      if (widget.data.profileImageBytes != null) {
        final ext = widget.data.profileImageType ?? 'jpg';
        final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from('avatars').uploadBinary(fileName, widget.data.profileImageBytes!, fileOptions: const FileOptions(upsert: true));
        imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final profileData = {
        'id': user.id,
        'email': user.email,
        'name': widget.data.name,
        'location': widget.data.location,
        'bio': widget.data.bio,
        'university': widget.data.university,
        'major': widget.data.major,
        'graduation_year': widget.data.gradYear,
        'interests': widget.data.interests.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'vibe_tags': widget.data.vibes,
        if (imageUrl != null) 'profile_image': imageUrl,
        'onboarding_complete': true,
      };

      await supabase.from('profiles').upsert(profileData);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.accent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const OnboardingProgressBar(currentStep: 7),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Looks Good?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text('Here is how your profile will look.', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
              const SizedBox(height: 32),
              
              // Preview Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.inputFill,
                      backgroundImage: widget.data.profileImageBytes != null ? MemoryImage(widget.data.profileImageBytes!) : null,
                      child: widget.data.profileImageBytes == null
                          ? Text(widget.data.name.isNotEmpty ? widget.data.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary))
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.data.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    if (widget.data.location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.subtle),
                          const SizedBox(width: 4),
                          Text(widget.data.location, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.subtle)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Align(alignment: Alignment.centerLeft, child: Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(widget.data.bio.isEmpty ? '--' : widget.data.bio, style: const TextStyle(color: AppColors.primary, height: 1.5)),
                    ),
                    const SizedBox(height: 24),
                    const Align(alignment: Alignment.centerLeft, child: Text('Vibes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: widget.data.vibes.isEmpty 
                        ? const Text('--') 
                        : Wrap(
                            spacing: 8, runSpacing: 8,
                            children: widget.data.vibes.map((v) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            )).toList(),
                          ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              if (_isLoading)
                 const Center(child: CircularProgressIndicator(color: AppColors.accent))
              else ...[
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Looks good'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Edit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.subtle)),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}"""
with open("lib/screens/onboarding/step7_preview_screen.dart", "w") as f: f.write(step7_content)

print("done generating screens")
