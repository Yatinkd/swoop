import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/plan.dart';
import '../repositories/plan_repository.dart';
import '../theme/app_colors.dart';
import '../utils/plan_formatters.dart';
import '../widgets/plan/plan_card.dart';
import 'plan_details_screen.dart';

class SocialEventSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SocialEventSearchScreen({super.key, this.initialQuery});

  @override
  State<SocialEventSearchScreen> createState() => _SocialEventSearchScreenState();
}

class _SocialEventSearchScreenState extends State<SocialEventSearchScreen> {
  final _controller = TextEditingController();
  final _repo = PlanRepository();
  List<Plan> _results = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      _search(widget.initialQuery!);
    } else {
      _results = SampleData.plans.where((p) => p.isConcertMode).toList();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() => _results = _repo.socialEventResults(query));
  }

  void _openPlan(Plan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanDetailsScreen(plan: plan.toMap()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Event Discovery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Social Event Discovery'),
                  content: const Text(
                    'Search concerts, festivals, sports matches and find groups already attending.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Coldplay Concert, IPL, Comic Con...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic_rounded),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Find people and groups attending the same events.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 48, color: AppColors.subtle.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No groups found for this event',
                          style: TextStyle(
                            color: AppColors.subtle,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Be the first to create a meetup!',
                          style: TextStyle(color: AppColors.subtle, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final p = _results[i];
                      return PlanCard(
                        title: p.title,
                        hostName: p.hostName,
                        hostImage: p.hostImage,
                        location: p.location,
                        dateTime: p.meetTime ?? PlanFormatters.formatShortDate(p.datetime),
                        attendeeCount: p.attendeeCount,
                        category: p.linkedEventName ?? p.category,
                        coverImage: p.coverImage,
                        showJoinButton: true,
                        onTap: () => _openPlan(p),
                        onJoin: () => _openPlan(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
