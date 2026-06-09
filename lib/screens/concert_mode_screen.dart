import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/plan.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/plan_formatters.dart';
import '../widgets/plan/plan_card.dart';
import 'plan_details_screen.dart';

class ConcertModeScreen extends StatelessWidget {
  const ConcertModeScreen({super.key});

  void _openPlan(BuildContext context, Plan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan.toMap())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final concertPlans = SampleData.plans.where((p) => p.isConcertMode).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Event groups')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Find groups attending the same events.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 20),
          ...concertPlans.map(
            (p) => PlanCard(
              title: p.title,
              hostName: p.hostName,
              location: p.location,
              dateTime: PlanFormatters.formatShortDate(p.datetime),
              attendeeCount: p.attendeeCount,
              category: p.linkedEventName ?? p.category,
              coverImage: p.coverImage,
              showJoinButton: true,
              onTap: () => _openPlan(context, p),
              onJoin: () => _openPlan(context, p),
            ),
          ),
        ],
      ),
    );
  }
}
