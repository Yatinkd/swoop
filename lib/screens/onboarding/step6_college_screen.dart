import 'package:flutter/material.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step7_preview_screen.dart';

class Step6CollegeScreen extends StatefulWidget {
  final OnboardingData data;
  const Step6CollegeScreen({super.key, required this.data});

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

  Future<void> _next() async {
    widget.data.university = _uniController.text.trim();
    widget.data.major = _majorController.text.trim();
    widget.data.gradYear = _gradYearController.text.trim();
    final didComplete = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => Step7PreviewScreen(data: widget.data)),
    );
    if (!mounted) return;
    if (didComplete == true) {
      Navigator.pop(context, true);
    }
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
      appBar: AppBar(title: const OnboardingProgressBar(currentStep: 6)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'College Info',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Optional. Connect with alumni.',
                style: TextStyle(fontSize: 16, color: AppColors.subtle),
              ),
              const SizedBox(height: 48),
              const Text(
                'University',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _uniController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Stanford University',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Major',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _majorController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Computer Science',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Graduation Year',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _gradYearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 2026'),
              ),
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
}
