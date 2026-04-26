import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_plan_screen.dart';
import 'plan_details_screen.dart';
import '../main.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({Key? key}) : super(key: key);

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
            color: AppColors.accent,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.subtle,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          dividerColor: AppColors.divider,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Pending Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _PlanList(type: 'upcoming'),
          const _PlanList(type: 'past'),
          _RequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
        ),
        backgroundColor: AppColors.accent,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Create Event',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  final String type;
  const _PlanList({required this.type});

  String _formatDt(String? dt) {
    if (dt == null) return '';
    final d = DateTime.parse(dt);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const SizedBox();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('plans')
          .stream(primaryKey: ['id'])
          .order('datetime', ascending: type == 'upcoming'),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        final now = DateTime.now();
        final myPlans = snapshot.data!.where((p) {
          final parts = List<String>.from(p['participants'] ?? []);
          if (!(p['host_id'] == userId || parts.contains(userId))) return false;
          final dt = p['datetime'] != null
              ? DateTime.parse(p['datetime'])
              : null;
          if (dt == null) return false;
          return type == 'upcoming' ? dt.isAfter(now) : dt.isBefore(now);
        }).toList();

        if (myPlans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'upcoming'
                      ? Icons.calendar_month_rounded
                      : Icons.history_rounded,
                  size: 48,
                  color: AppColors.subtle.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${type} events',
                  style: const TextStyle(
                    color: AppColors.subtle,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: myPlans.length,
          itemBuilder: (ctx, i) {
            final plan = myPlans[i];
            final vibe = plan['vibe'] as String?;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlanDetailsScreen(plan: plan),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.vibeBg(vibe),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          vibe != null && vibe.toString().isNotEmpty
                              ? vibe.toString()[0].toUpperCase()
                              : 'E',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.vibeFg(vibe),
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan['title'] ?? 'Untitled Event',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDt(plan['datetime']),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.subtle,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RequestsTab extends StatefulWidget {
  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final supabase = Supabase.instance.client;

  Future<void> _updateStatus(
    int reqId,
    String planId,
    String userId,
    bool accept,
  ) async {
    try {
      await supabase
          .from('join_requests')
          .update({'status': accept ? 'accepted' : 'rejected'})
          .eq('id', reqId);
      if (accept) {
        final plan = await supabase
            .from('plans')
            .select('participants, max_size')
            .eq('id', planId)
            .single();
        final parts = List<String>.from(plan['participants'] ?? []);
        final max = plan['max_size'] ?? 5;
        if (!parts.contains(userId) && parts.length < max) {
          parts.add(userId);
          await supabase
              .from('plans')
              .update({'participants': parts})
              .eq('id', planId);
        }
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'Accepted request! 🎉' : 'Rejected request.',
            ),
          ),
        );
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (supabase.auth.currentUser == null) return const SizedBox();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('plans')
          .stream(primaryKey: ['id'])
          .eq('host_id', supabase.auth.currentUser!.id),
      builder: (context, planSnapshot) {
        if (!planSnapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        final myPlanIds = planSnapshot.data!
            .map((p) => p['id'] as String)
            .toList();
        if (myPlanIds.isEmpty)
          return const Center(
            child: Text(
              'You are not hosting any plans yet',
              style: TextStyle(color: AppColors.subtle),
            ),
          );

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase.from('join_requests').stream(primaryKey: ['id']),
          builder: (context, reqSnapshot) {
            if (!reqSnapshot.hasData)
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            final allReqs = reqSnapshot.data!;
            final reqs = allReqs
                .where(
                  (r) =>
                      myPlanIds.contains(r['plan_id']) &&
                      r['status'] == 'pending',
                )
                .toList();
            if (reqs.isEmpty)
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 48,
                      color: AppColors.success.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You are all caught up!',
                      style: TextStyle(
                        color: AppColors.subtle,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: reqs.length,
              itemBuilder: (context, i) {
                final r = reqs[i];
                return FutureBuilder<Map<String, dynamic>>(
                  future: supabase
                      .from('profiles')
                      .select('name, profile_image')
                      .eq('id', r['user_id'])
                      .single(),
                  builder: (ctx, uSnap) {
                    if (!uSnap.hasData) return const SizedBox();
                    final user = uSnap.data!;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.accent.withOpacity(0.1),
                            backgroundImage: user['profile_image'] != null
                                ? NetworkImage(user['profile_image'])
                                : null,
                            child: user['profile_image'] == null
                                ? Text(
                                    user['name'][0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Wants to join your event',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.subtle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _updateStatus(
                                  r['id'],
                                  r['plan_id'],
                                  r['user_id'],
                                  false,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputFill,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _updateStatus(
                                  r['id'],
                                  r['plan_id'],
                                  r['user_id'],
                                  true,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
