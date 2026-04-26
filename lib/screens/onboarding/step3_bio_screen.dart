import 'package:flutter/material.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step4_vibes_screen.dart';

class Step3BioScreen extends StatefulWidget {
  final OnboardingData data;
  const Step3BioScreen({super.key, required this.data});

  @override
  State<Step3BioScreen> createState() => _Step3BioScreenState();
}

class _Step3BioScreenState extends State<Step3BioScreen> {
  final _enjoyController = TextEditingController();
  final _weekendController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _enjoyController.text = widget.data.bioEnjoy;
    _weekendController.text = widget.data.bioWeekend;
  }

  Future<void> _next() async {
    widget.data.bioEnjoy = _enjoyController.text.trim();
    widget.data.bioWeekend = _weekendController.text.trim();
    final didComplete = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => Step4VibesScreen(data: widget.data)),
    );
    if (!mounted) return;
    if (didComplete == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _enjoyController.dispose();
    _weekendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const OnboardingProgressBar(currentStep: 3)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Smart Prompts',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Answer these to help people know you.',
                style: TextStyle(fontSize: 16, color: AppColors.subtle),
              ),
              const SizedBox(height: 48),

              const Text(
                'What do you enjoy?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _enjoyController,
                maxLines: 2,
                maxLength: 80,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Exploring new coffee shops and film photography.',
                  counterText: "",
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Perfect weekend?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weekendController,
                maxLines: 2,
                maxLength: 80,
                decoration: const InputDecoration(
                  hintText: 'e.g. A long hike followed by reading at a park.',
                  counterText: "",
                ),
              ),

              const SizedBox(height: 60),
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
