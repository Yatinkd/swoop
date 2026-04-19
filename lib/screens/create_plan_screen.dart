import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({Key? key}) : super(key: key);

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDateTime;
  String? _selectedVibe;
  int _maxSize = 5;
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  final _vibes = ['Chill', 'Party', 'Study', 'Adventure', 'Food', 'Sports'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.accent, onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.accent)),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() => _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _formatDt() {
    if (_selectedDateTime == null) return 'Pick a date & time';
    final d = _selectedDateTime!;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = d.hour;
    final min = d.minute.toString().padLeft(2,'0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${d.day} ${months[d.month-1]}, $h12:$min $amPm';
  }

  Future<void> _createPlan() async {
    if (_titleController.text.trim().isEmpty) { _showError('Plan title is required'); return; }
    if (_locationController.text.trim().isEmpty) { _showError('Location is required'); return; }
    if (_selectedDateTime == null) { _showError('Date and time are required'); return; }
    if (_selectedVibe == null) { _showError('Please select a vibe'); return; }

    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      final profile = await supabase.from('profiles').select('name, profile_image').eq('id', user.id).single();

      await supabase.from('plans').insert({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'datetime': _selectedDateTime!.toIso8601String(),
        'host_id': user.id,
        'host_name': profile['name'] ?? 'Anonymous',
        'host_image': profile['profile_image'],
        'vibe': _selectedVibe,
        'max_size': _maxSize,
        'participants': [user.id],
        'is_boosted': false,
        'is_sponsored': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Plan created! 🎉'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('New Plan'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPlan,
            child: Text('Post', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _FieldLabel('What\'s the plan?'),
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
              decoration: const InputDecoration(hintText: 'Give it a great name...', hintStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              maxLines: 1,
            ),
            const SizedBox(height: 24),

            // Description
            _FieldLabel('Description (optional)'),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Describe the vibe, what to expect...'),
            ),
            const SizedBox(height: 24),

            // Location
            _FieldLabel('Where?'),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Add a location',
                prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.accent, size: 20),
              ),
            ),
            const SizedBox(height: 24),

            // Date & Time
            _FieldLabel('When?'),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _formatDt(),
                      style: TextStyle(
                        fontSize: 15,
                        color: _selectedDateTime != null ? AppColors.primary : AppColors.subtle,
                        fontWeight: _selectedDateTime != null ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Vibes
            _FieldLabel('Pick a Vibe'),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _vibes.map((v) {
                final sel = _selectedVibe == v;
                return GestureDetector(
                  onTap: () => setState(() => _selectedVibe = sel ? null : v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.vibeBg(v.toLowerCase()) : AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: sel ? AppColors.vibeFg(v.toLowerCase()).withOpacity(0.3) : AppColors.divider, width: sel ? 1.5 : 1),
                      boxShadow: sel ? [BoxShadow(color: AppColors.vibeFg(v.toLowerCase()).withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))] : [],
                    ),
                    child: Text(v, style: TextStyle(color: sel ? AppColors.vibeFg(v.toLowerCase()) : AppColors.subtle, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Group Size
            _FieldLabel('Max Group Size'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
              child: Row(
                children: [
                  Icon(Icons.people_alt_rounded, color: AppColors.accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Text('$_maxSize people', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary))),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _maxSize > 2 ? () => setState(() => _maxSize--) : null,
                        icon: Icon(Icons.remove_circle_outline_rounded, color: _maxSize > 2 ? AppColors.accent : AppColors.divider, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('$_maxSize', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ),
                      IconButton(
                        onPressed: _maxSize < 20 ? () => setState(() => _maxSize++) : null,
                        icon: Icon(Icons.add_circle_outline_rounded, color: _maxSize < 20 ? AppColors.accent : AppColors.divider, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
        padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.of(context).padding.bottom + 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createPlan,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Create Plan'),
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
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
  );
}