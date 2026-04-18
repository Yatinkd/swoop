import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({Key? key}) : super(key: key);

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  DateTime? selectedDateTime;
  String? selectedVibe;
  int maxSize = 5;
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  final vibes = ['Chill', 'Party', 'Study', 'Adventure', 'Food', 'Sports'];

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context, initialDate: DateTime.now(),
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() => selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> createPlan() async {
    if (titleController.text.trim().isEmpty || locationController.text.trim().isEmpty || selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Fill all required fields'), backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      final profile = await supabase.from('profiles').select('name, profile_image').eq('id', user.id).single();

      await supabase.from('plans').insert({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'location': locationController.text.trim(),
        'datetime': selectedDateTime!.toIso8601String(),
        'host_id': user.id,
        'host_name': profile['name'] ?? 'Anonymous',
        'host_image': profile['profile_image'],
        'vibe': selectedVibe,
        'max_size': maxSize,
        'participants': [user.id],
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Create Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Title'),
            TextField(controller: titleController, decoration: const InputDecoration(hintText: "What's the plan?")),
            const SizedBox(height: 20),

            _label('Description (optional)'),
            TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(hintText: 'Tell people more...')),
            const SizedBox(height: 20),

            _label('Location'),
            TextField(controller: locationController, decoration: const InputDecoration(hintText: 'Where is it?')),
            const SizedBox(height: 20),

            _label('Date & Time'),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: AppColors.subtle),
                    const SizedBox(width: 12),
                    Text(
                      selectedDateTime == null ? 'Pick a date & time' : '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} at ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: selectedDateTime == null ? AppColors.subtle : AppColors.primary, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _label('Vibe'),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: vibes.map((v) {
                final sel = selectedVibe == v;
                return GestureDetector(
                  onTap: () => setState(() => selectedVibe = sel ? null : v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.accent : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(v, style: TextStyle(color: sel ? Colors.white : AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            _label('Max Group Size'),
            Row(
              children: [
                IconButton(
                  onPressed: maxSize > 2 ? () => setState(() => maxSize--) : null,
                  icon: Icon(Icons.remove_circle_outline, color: maxSize > 2 ? AppColors.primary : AppColors.divider),
                ),
                Text('$maxSize', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: maxSize < 20 ? () => setState(() => maxSize++) : null,
                  icon: Icon(Icons.add_circle_outline, color: maxSize < 20 ? AppColors.primary : AppColors.divider),
                ),
              ],
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : createPlan,
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Post Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subtle, letterSpacing: 0.5)),
  );
}