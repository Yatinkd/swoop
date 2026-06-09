import 'package:flutter/material.dart';

import '../../constants/vibe_tags.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/vibe_tag_chip.dart';
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
  final _allVibes = VibeTags.all;
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.data.vibes.map((category) {
      final match = VibeTags.all.where((t) => t.category == category);
      return match.isNotEmpty ? match.first.label : category;
    }).toList();
  }

  Future<void> _next() async {
    widget.data.vibes = _selected.map((v) {
      final match = VibeTags.all.where((t) => t.label == v);
      return match.isNotEmpty ? match.first.category : v;
    }).toList();
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const OnboardingProgressBar(currentStep: 4)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('What are your vibes?', style: AppTextStyles.largeHeading.copyWith(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                'Select all that match your energy.',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: _allVibes.map((v) {
                  final isSel = _selected.contains(v.label);
                  return VibeTagChip(
                    label: v.label,
                    selected: isSel,
                    onTap: () {
                      setState(() {
                        if (isSel) {
                          _selected.remove(v.label);
                        } else {
                          _selected.add(v.label);
                        }
                      });
                    },
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
