import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'plan_details_screen.dart';

// ── ActivityCard (kept for use in profile_screen.dart preview) ──────────────
class ActivityCard extends StatelessWidget {
  final String title;
  final String date;
  final String status;

  const ActivityCard({
    Key? key,
    required this.title,
    required this.date,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isHosted = status == 'Hosted';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHosted
                  ? AppColors.accent.withValues(alpha: 0.1)
                  : AppColors.inputFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHosted ? Icons.celebration_rounded : Icons.people_rounded,
              color: isHosted ? AppColors.accent : AppColors.subtle,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtle,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isHosted ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isHosted ? null : Border.all(color: AppColors.divider),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isHosted ? Colors.white : AppColors.subtle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full Activity Screen with Upcoming / Past tabs ─────────────────────────
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _past = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchActivity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivity() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch ALL plans where user is host or participant.
      // We do client-side filtering because Supabase arrays need
      // the `cs` operator which can be complex. Simple is better here.
      final allPlans = await supabase
          .from('plans')
          .select()
          .order('datetime', ascending: false);

      final upcoming = <Map<String, dynamic>>[];
      final past = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (final p in (allPlans as List)) {
        final isHost = p['host_id'] == userId;
        final isParticipant =
            List<String>.from(p['participants'] ?? []).contains(userId);

        // Only include events the user is part of
        if (!isHost && !isParticipant) continue;

        DateTime? dt;
        if (p['datetime'] != null) dt = DateTime.parse(p['datetime']);

        final isPast = dt != null && dt.isBefore(now);
        final plan = Map<String, dynamic>.from(p);

        if (isPast) {
          past.add(plan);
        } else {
          upcoming.add(plan);
        }
      }

      if (mounted) {
        setState(() {
          _upcoming = upcoming;
          _past = past;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dt) {
    if (dt == null) return '';
    final d = DateTime.parse(dt);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour;
    final min = d.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${d.day} ${months[d.month - 1]}, $h12:$min $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Your Activity',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _isLoading
              ? const SizedBox.shrink()
              : TabBar(
                  controller: _tabController,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.subtle,
                  indicatorColor: AppColors.accent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: 'Upcoming (${_upcoming.length})'),
                    Tab(text: 'Past (${_past.length})'),
                  ],
                ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_upcoming, isPast: false),
                _buildList(_past, isPast: true),
              ],
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> plans, {required bool isPast}) {
    if (plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPast ? Icons.history_rounded : Icons.event_outlined,
                size: 56,
                color: AppColors.subtle.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 16),
              Text(
                isPast ? 'No past events yet' : 'No upcoming events',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isPast
                    ? 'Events you attend will show up here'
                    : 'Join or host a plan to see it here',
                style: const TextStyle(color: AppColors.subtle, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchActivity,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: plans.length,
        itemBuilder: (context, i) {
          final plan = plans[i];
          final userId = supabase.auth.currentUser?.id;
          final isHost = plan['host_id'] == userId;
          final title = plan['title'] ?? 'Untitled';
          final location = plan['location'] ?? '';
          final vibe = plan['vibe'] as String?;
          final participants =
              List<String>.from(plan['participants'] ?? []);

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlanDetailsScreen(plan: plan),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isPast
                    ? Border.all(color: AppColors.divider, width: 1)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isPast
                          ? AppColors.subtle.withValues(alpha: 0.08)
                          : AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPast
                          ? Icons.check_circle_outline_rounded
                          : Icons.event_outlined,
                      color: isPast ? AppColors.subtle : AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isPast
                                      ? AppColors.subtle
                                      : AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Host / Joined badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isHost
                                    ? AppColors.accent.withValues(alpha: 0.1)
                                    : AppColors.inputFill,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isHost ? 'Hosted' : 'Joined',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isHost
                                      ? AppColors.accent
                                      : AppColors.subtle,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Date
                        if (plan['datetime'] != null)
                          Text(
                            _formatDate(plan['datetime']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.subtle,
                            ),
                          ),

                        // Location
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.subtle,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Vibe + going count
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (vibe != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  vibe,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              '${participants.length} ${isPast ? 'went' : 'going'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.subtle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.subtle,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
