import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'create_plan_screen.dart';
import 'plan_details_screen.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Explore'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('plans')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final plans = snapshot.data;

          if (plans == null || plans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_outlined, size: 72, color: AppColors.subtle.withValues(alpha: 0.5)),
                    const SizedBox(height: 20),
                    Text('No plans yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text('Be the first to make a plan!', style: TextStyle(color: AppColors.subtle, fontSize: 15)),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePlanScreen())),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Create a Plan'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    ),
                  ],
                ),
              ),
            );
          }

          // Sort boosted plans to top
          final sorted = List<Map<String, dynamic>>.from(plans);
          sorted.sort((a, b) {
            final aB = a['is_boosted'] == true ? 0 : 1;
            final bB = b['is_boosted'] == true ? 0 : 1;
            return aB.compareTo(bB);
          });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final plan = sorted[index];
              final hostName = plan['host_name'] ?? 'Someone';
              final title = plan['title'] ?? 'Untitled';
              final location = plan['location'] ?? '';
              final vibe = plan['vibe'];
              final participants = List<String>.from(plan['participants'] ?? []);
              final maxSize = plan['max_size'] ?? 5;
              final isHost = plan['host_id'] == currentUserId;
              final isBoosted = plan['is_boosted'] == true;

              DateTime? datetime;
              if (plan['datetime'] != null) datetime = DateTime.parse(plan['datetime']);

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: isBoosted ? Border.all(color: Colors.amber.shade300, width: 1.5) : null,
                    boxShadow: [
                      BoxShadow(
                        color: isBoosted ? Colors.amber.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                        blurRadius: isBoosted ? 16 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Boosted badge
                      if (isBoosted)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rocket_launch, size: 14, color: Colors.orange),
                              SizedBox(width: 6),
                              Text('Boosted', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange)),
                            ],
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Host row
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                                  child: Text(
                                    hostName.isNotEmpty ? hostName[0].toUpperCase() : '?',
                                    style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(hostName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      if (plan['created_at'] != null)
                                        Text(timeago.format(DateTime.parse(plan['created_at'])), style: TextStyle(fontSize: 12, color: AppColors.subtle)),
                                    ],
                                  ),
                                ),
                                if (vibe != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(vibe, style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            if (plan['description'] != null && plan['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(plan['description'], style: TextStyle(color: AppColors.subtle, fontSize: 14, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                            const SizedBox(height: 16),

                            // Location & time
                            if (location.isNotEmpty)
                              _infoRow(Icons.location_on_outlined, location),
                            if (datetime != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: _infoRow(Icons.access_time_outlined, '${datetime.day}/${datetime.month}/${datetime.year} at ${datetime.hour}:${datetime.minute.toString().padLeft(2, '0')}'),
                              ),

                            const SizedBox(height: 16),
                            // Bottom row
                            Row(
                              children: [
                                Icon(Icons.people_outline, size: 18, color: AppColors.subtle),
                                const SizedBox(width: 6),
                                Text('${participants.length}/$maxSize', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.subtle, fontSize: 13)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isHost ? AppColors.inputFill : AppColors.primary,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    isHost ? 'Manage' : 'View',
                                    style: TextStyle(color: isHost ? AppColors.primary : Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePlanScreen())),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.subtle),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(color: AppColors.subtle, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
