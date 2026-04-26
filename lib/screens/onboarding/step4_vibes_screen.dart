import 'package:flutter/material.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step5_interests_screen.dart';

class Step4VibesScreen extends StatefulWidget {
  final OnboardingData data;
  const Step4VibesScreen({super.key, required this.data});

  @override
  State<Step4VibesScreen> createState() => _Step4VibesScreenState();
}

class _Step4VibesScreenState extends State<Step4VibesScreen> {
  final List<String> _allVibes = [
    'Chill',
    'Party',
    'Study',
    'Adventure',
    'Food',
    'Sports',
  ];
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.data.vibes);
  }

  Future<void> _next() async {
    widget.data.vibes = _selected;
    final didComplete = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => Step5InterestsScreen(data: widget.data),
      ),
    );
    if (!mounted) return;
    if (didComplete == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const OnboardingProgressBar(currentStep: 4)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'What are your vibes?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select all that match your energy.',
                style: TextStyle(fontSize: 16, color: AppColors.subtle),
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 12,
                runSpacing: 16,
                children: _allVibes.map((v) {
                  final isSel = _selected.contains(v);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSel) {
                          _selected.remove(v);
                        } else {
                          _selected.add(v);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSel ? AppColors.primary : AppColors.divider,
                        ),
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
}
