import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class CreateHostedEventScreen extends StatefulWidget {
  const CreateHostedEventScreen({Key? key}) : super(key: key);

  @override
  State<CreateHostedEventScreen> createState() =>
      _CreateHostedEventScreenState();
}

class _CreateHostedEventScreenState extends State<CreateHostedEventScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final priceController = TextEditingController();
  DateTime? selectedDateTime;
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
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

  Future<void> _create() async {
    if (titleController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fill all fields'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final price = double.tryParse(priceController.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid price'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

      await supabase.from('hosted_events').insert({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': price,
        'location': locationController.text.trim(),
        'datetime': selectedDateTime!.toIso8601String(),
        'host_id': user.id,
        'host_name': profile['name'] ?? 'Organizer',
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Host Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Event Title'),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: "What's happening?"),
            ),
            const SizedBox(height: 20),
            _label('Description'),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Details about the event...',
              ),
            ),
            const SizedBox(height: 20),
            _label('Venue'),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(hintText: 'Where is it?'),
            ),
            const SizedBox(height: 20),
            _label('Ticket Price'),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixIcon: Icon(Icons.attach_money, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 20),
            _label('Date & Time'),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppColors.subtle,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedDateTime == null
                          ? 'Pick a date & time'
                          : '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} at ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: selectedDateTime == null
                            ? AppColors.subtle
                            : AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _create,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Create Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.subtle,
        letterSpacing: 0.5,
      ),
    ),
  );
}
