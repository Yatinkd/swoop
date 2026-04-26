import 'package:flutter/material.dart';
import '../../main.dart';
import 'onboarding_data.dart';
import 'onboarding_progress_bar.dart';
import 'step6_college_screen.dart';

class Step5InterestsScreen extends StatefulWidget {
  final OnboardingData data;
  const Step5InterestsScreen({super.key, required this.data});

  @override
  State<Step5InterestsScreen> createState() => _Step5InterestsScreenState();
}

class _Step5InterestsScreenState extends State<Step5InterestsScreen> {
  final List<String> _suggestedInterests = [
    'Music',
    'Tech',
    'Outdoors',
    'Film',
    'Fitness',
    'Art',
    'Deep Talks',
    'Reading',
    'Gaming',
    'Coffee',
    'Travel',
    'Photography',
  ];
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.data.interestsList);
  }

  Future<void> _next() async {
    widget.data.interestsList = _selected;
    final didComplete = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => Step6CollegeScreen(data: widget.data)),
    );
    if (!mounted) return;
    if (didComplete == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const OnboardingProgressBar(currentStep: 5)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Add your interests',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap tags to add them to your profile.',
                style: TextStyle(fontSize: 16, color: AppColors.subtle),
              ),
              const SizedBox(height: 48),

              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: _suggestedInterests.map((interest) {
                  final isSel = _selected.contains(interest);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSel) {
                          _selected.remove(interest);
                        } else {
                          _selected.add(interest);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel ? AppColors.primary : AppColors.divider,
                        ),
                        boxShadow: isSel
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSel
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            size: 16,
                            color: isSel ? Colors.white : AppColors.subtle,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            interest,
                            style: TextStyle(
                              color: isSel ? Colors.white : AppColors.primary,
                              fontWeight: isSel
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
