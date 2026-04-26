import 'package:flutter/material.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step3_bio_screen.dart';

class Step2LocationScreen extends StatefulWidget {
  final OnboardingData data;
  const Step2LocationScreen({super.key, required this.data});

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

  Future<void> _next() async {
    widget.data.location = _locationController.text.trim();
    final didComplete = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => Step3BioScreen(data: widget.data)),
    );
    if (!mounted) return;
    if (didComplete == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const OnboardingProgressBar(currentStep: 2)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Where are you based?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Find events and people near your location.',
                style: TextStyle(fontSize: 16, color: AppColors.subtle),
              ),
              const SizedBox(height: 48),
              const Text(
                'Your Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'City, Neighborhood',
                ),
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
                  label: const Text(
                    'Auto-detect location',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
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
}
