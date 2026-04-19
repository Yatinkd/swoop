import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentProfile;
  const EditProfileScreen({Key? key, required this.currentProfile}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;
  
  late TextEditingController nameController;
  late TextEditingController bioController;
  late TextEditingController locationController;
  late TextEditingController interestsController;
  late TextEditingController universityController;
  late TextEditingController majorController;
  late TextEditingController gradYearController;
  
  List<String> selectedVibes = [];
  Uint8List? _profileImageBytes;
  String? _profileImageType;
  String? _existingImageUrl;
  bool isLoading = false;
  
  final vibes = ['Chill', 'Party', 'Study', 'Adventure', 'Food', 'Sports'];

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    
    nameController = TextEditingController(text: p['name'] ?? '');
    bioController = TextEditingController(text: p['bio'] ?? '');
    locationController = TextEditingController(text: p['location'] ?? '');
    
    final interests = p['interests'] as List<dynamic>?;
    interestsController = TextEditingController(text: interests?.join(', ') ?? '');
    
    universityController = TextEditingController(text: p['university'] ?? '');
    majorController = TextEditingController(text: p['major'] ?? '');
    gradYearController = TextEditingController(text: p['graduation_year'] ?? '');
    
    if (p['vibe_tags'] != null) {
      selectedVibes = List<String>.from(p['vibe_tags']);
    } else if (p['vibe_tag'] != null) {
      selectedVibes = [p['vibe_tag']]; // Fallback for old data
    }
    _existingImageUrl = p['profile_image'];
  }

  @override
  void dispose() {
    nameController.dispose(); bioController.dispose(); locationController.dispose();
    interestsController.dispose(); universityController.dispose();
    majorController.dispose(); gradYearController.dispose();
    super.dispose();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> saveChanges() async {
    if (nameController.text.trim().isEmpty || bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Bio are required!'), backgroundColor: AppColors.accent));
      return;
    }
    if (selectedVibes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick at least one vibe!'), backgroundColor: AppColors.accent));
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? imageUrl = _existingImageUrl;
      if (_profileImageBytes != null) {
        final ext = _profileImageType ?? 'jpg';
        final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from('avatars').uploadBinary(fileName, _profileImageBytes!, fileOptions: const FileOptions(upsert: true));
        imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final updates = {
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'location': locationController.text.trim(),
        'interests': interestsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'university': universityController.text.trim(),
        'major': majorController.text.trim(),
        'graduation_year': gradYearController.text.trim(),
        'vibe_tags': selectedVibes,
        if (imageUrl != null) 'profile_image': imageUrl,
      };

      await supabase.from('profiles').update(updates).eq('id', user.id);
      
      if (!mounted) return;
      Navigator.pop(context, true); 
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
        title: const Text('Edit Profile'),
        actions: [
          if (isLoading)
            const Padding(padding: EdgeInsets.only(right: 20), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))))
          else
            TextButton(
              onPressed: saveChanges,
              child: Text('Save', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.inputFill,
                  backgroundImage: _profileImageBytes != null 
                      ? MemoryImage(_profileImageBytes!) 
                      : (_existingImageUrl != null ? NetworkImage(_existingImageUrl!) : null) as ImageProvider?,
                  child: _profileImageBytes == null && _existingImageUrl == null 
                      ? const Icon(Icons.add_a_photo, size: 30, color: AppColors.subtle) : null,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _sectionTitle('The Basics'),
            _field('Name *', nameController),
            _field('Location', locationController),
            _field('Bio *', bioController, maxLines: 3),
            
            const SizedBox(height: 24),
            _sectionTitle('College Info'),
            _field('University', universityController),
            _field('Major / Course', majorController),
            _field('Graduation Year', gradYearController, keyboardType: TextInputType.number),
            
            const SizedBox(height: 24),
            _sectionTitle('The Vibe'),
            _field('Interests (comma separated)', interestsController),
            
            const SizedBox(height: 12),
            Text('Your Vibes *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subtle)),
            const SizedBox(height: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(30), 
                      border: Border.all(color: sel ? AppColors.primary : AppColors.divider),
                    ),
                    child: Text(v, style: TextStyle(color: sel ? Colors.white : AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 16, top: 8), child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)));
  Widget _field(String label, TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subtle)), const SizedBox(height: 8), TextField(controller: controller, maxLines: maxLines, keyboardType: keyboardType, style: const TextStyle(fontSize: 15))],
    ),
  );
}
