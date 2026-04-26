import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'plan_details_screen.dart';
import '../main.dart';
import '../services/event_status_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;

  // Upcoming Plans: only active/future events (public feed)
  List<Map<String, dynamic>> _upcomingPlans = [];

  // Your Activity: ALL events the user is part of (including past)
  List<Map<String, dynamic>> _myActivity = [];

  bool _isLoading = true;

  // ── Real-time completion timer ──────────────────────────────────
  // Re-fetches plans every minute. Any event whose datetime just passed
  // will be removed from Upcoming and moved to Your Activity automatically.
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();

    // Refresh every 60 seconds so Upcoming Plans disappears the moment
    // an event's time passes without requiring a manual pull-to-refresh.
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) { if (mounted) _loadPlans(); },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadProfile(), _loadPlans()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase
          .from('profiles')
          .select('name, location, profile_image')
          .eq('id', userId)
          .maybeSingle();
      if (mounted) setState(() => _profile = data);
    } catch (_) {}
  }

  Future<void> _loadPlans() async {
    try {
      final userId = supabase.auth.currentUser?.id;

      // ── Fetch ALL plans once ──────────────────────────────────
      // We do one fetch and split client-side — simple and beginner-friendly.
      final allPlans = await supabase
          .from('plans')
          .select()
          .order('datetime', ascending: true); // ascending = soonest first

      final now = DateTime.now();
      final upcoming = <Map<String, dynamic>>[];
      final myActivity = <Map<String, dynamic>>[];

      for (final p in (allPlans as List)) {
        final plan = Map<String, dynamic>.from(p);

        // Determine if event is in the past or marked completed
        final status = (plan['status'] ?? '').toString();
        final dt = EventStatusService.parseLocalTime(plan['datetime']);
        final isPast = dt != null && dt.isBefore(now) ||
            status == 'completed';

        // ── UPCOMING PLANS (public) ────────────────────────────
        // Show ONLY future + active events in the public section
        if (!isPast) {
          upcoming.add(plan);
        }

        // ── YOUR ACTIVITY (private) ────────────────────────────
        // Show ALL events (past + upcoming) where user is host or participant
        if (userId != null) {
          final isHost = plan['host_id'] == userId;
          final isParticipant =
              List<String>.from(plan['participants'] ?? []).contains(userId);
          if (isHost || isParticipant) {
            myActivity.add(plan);
          }
        }
      }

      if (mounted) {
        setState(() {
          _upcomingPlans = upcoming;
          _myActivity = myActivity;
        });
      }

      // ── Auto-mark completed events in Supabase ────────────────────
      // Writes status='completed' for any plan whose time has passed.
      // This fires silently in the background so other devices and the
      // Explore StreamBuilder also pick up the change automatically.
      EventStatusService.autoMarkBatch(
        (allPlans as List).map((p) => Map<String, dynamic>.from(p)).toList(),
      );
    } catch (_) {}
  }

  String _formatDate(String? dt) {
    if (dt == null) return '';
    final d = EventStatusService.parseLocalTime(dt) ?? DateTime.now();
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
    final hour = d.hour;
    final min = d.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${d.day} ${months[d.month - 1]}  ·  $h12:$min $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;
    final userName = (_profile?['name'] as String? ?? '').split(' ').first;
    final userLocation = _profile?['location'] as String? ?? '';
    final userImage = _profile?['profile_image'];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          color: AppColors.accent,
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.isNotEmpty
                                  ? 'Hey, $userName 👋'
                                  : 'Hey there 👋',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (userLocation.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    userLocation,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.subtle,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.accent.withOpacity(0.12),
                        backgroundImage:
                            userImage != null ? NetworkImage(userImage) : null,
                        child: userImage == null
                            ? Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ── UPCOMING PLANS section title ─────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'Upcoming Plans',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      // Shows count so users know how many active plans exist
                      if (_upcomingPlans.isNotEmpty)
                        Text(
                          '${_upcomingPlans.length} active',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Horizontal upcoming plan cards ───────────────
              // ONLY shows events where datetime > now AND status != 'completed'
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                            strokeWidth: 2,
                          ),
                        )
                      : _upcomingPlans.isEmpty
                          ? _emptyNearby()
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              itemCount: _upcomingPlans.length,
                              itemBuilder: (_, i) => _PlanCard(
                                plan: _upcomingPlans[i],
                                formatDate: _formatDate,
                              ),
                            ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 36)),

              // ── YOUR ACTIVITY section title ───────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Text(
                    'Your Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Activity list: host + participant events (ALL, inc. past) ─
              _myActivity.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.travel_explore_rounded,
                                size: 40,
                                color: AppColors.accent.withOpacity(0.4),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No plans yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Join a plan or create your own!',
                                style: TextStyle(
                                  color: AppColors.subtle,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _MyPlanTile(
                            plan: _myActivity[i],
                            userId: userId,
                            formatDate: _formatDate,
                          ),
                        ),
                        childCount: _myActivity.length,
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyNearby() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.explore_outlined,
          size: 40,
          color: AppColors.subtle.withOpacity(0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'No plans around yet',
          style: TextStyle(color: AppColors.subtle, fontSize: 14),
        ),
      ],
    ),
  );
}

// ── Horizontal plan card ─────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String Function(String?) formatDate;

  const _PlanCard({required this.plan, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final title = plan['title'] ?? 'Untitled';
    final vibe = plan['vibe'] as String?;
    final hostName = plan['host_name'] ?? 'Host';
    final location = plan['location'] ?? '';
    final participants = List<String>.from(plan['participants'] ?? []);
    final maxSize = plan['max_size'] ?? 5;
    final isFull = participants.length >= maxSize;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan)),
      ),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.accent.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean gradient top block
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent.withOpacity(0.12),
                      AppColors.inputFill,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (vibe != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              vibe,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (isFull)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Full',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hosted by $hostName',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.subtle.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (plan['datetime'] != null)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formatDate(plan['datetime']),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.subtle,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.subtle,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  // Social Element & CTA
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 24,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent.withOpacity(0.2),
                                  border: Border.all(
                                    color: AppColors.card,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            if (maxSize > 1)
                              Positioned(
                                left: 16,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.subtle.withOpacity(0.2),
                                    border: Border.all(
                                      color: AppColors.card,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: AppColors.subtle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${participants.length}/$maxSize going',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      // Subtle CTA
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Join',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
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
  }
}

// ── My plan list tile ────────────────────────────────────────────
class _MyPlanTile extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String? userId;
  final String Function(String?) formatDate;

  const _MyPlanTile({
    required this.plan,
    required this.userId,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final title = plan['title'] ?? 'Untitled';
    final vibe = plan['vibe'] as String?;
    final isHost = plan['host_id'] == userId;

    // ── Completion detection (same logic as everywhere else) ───────
    final status = (plan['status'] ?? '').toString();
    final dt = EventStatusService.parseLocalTime(plan['datetime']);
    final isCompleted =
        status == 'completed' || (dt != null && dt.isBefore(DateTime.now()));

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.vibeBg(vibe?.toLowerCase()),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  vibe?.isNotEmpty == true ? vibe![0].toUpperCase() : 'P',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.vibeFg(vibe?.toLowerCase()),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // ── Status badge ──────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.subtle.withOpacity(0.08)
                              : isHost
                                  ? AppColors.accent.withOpacity(0.1)
                                  : AppColors.inputFill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCompleted
                              ? 'Completed'
                              : (isHost ? 'Host' : 'Joined'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCompleted
                                ? AppColors.subtle
                                : (isHost
                                    ? AppColors.accent
                                    : AppColors.subtle),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (plan['datetime'] != null)
                    Text(
                      formatDate(plan['datetime']),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.subtle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.subtle.withOpacity(0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
