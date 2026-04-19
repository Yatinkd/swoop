import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'plan_details_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase.from('profiles').select('name, location, profile_image').eq('id', userId).maybeSingle();
      if (mounted) setState(() => _profile = data);
    } catch (_) {}
  }

  String _formatDate(String? dt) {
    if (dt == null) return '';
    final d = DateTime.parse(dt);
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: supabase.from('plans').select().order('created_at', ascending: false).limit(30),
          builder: (context, snapshot) {
            final allPlans = snapshot.data ?? [];
            final myPlans = allPlans.where((p) {
              final parts = List<String>.from(p['participants'] ?? []);
              return p['host_id'] == userId || parts.contains(userId);
            }).toList();

            return RefreshIndicator(
              onRefresh: () async { setState(() {}); await _loadProfile(); },
              color: AppColors.accent,
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────
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
                                  userName.isNotEmpty ? 'Hey, $userName' : 'Hey there',
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.5),
                                ),
                                if (userLocation.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.accent),
                                    const SizedBox(width: 4),
                                    Text(userLocation, style: const TextStyle(fontSize: 14, color: AppColors.subtle, fontWeight: FontWeight.w500)),
                                  ]),
                                ],
                              ],
                            ),
                          ),
                          GestureDetector(
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.accent.withOpacity(0.12),
                              backgroundImage: userImage != null ? NetworkImage(userImage) : null,
                              child: userImage == null
                                  ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 18))
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // ── Plans nearby section title ─────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('Upcoming Plans', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.3)),
                          const Spacer(),
                          Text('See all', style: TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Horizontal plan cards ────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 260,
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
                          : allPlans.isEmpty
                              ? _emptyNearby()
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  itemCount: allPlans.length,
                                  itemBuilder: (_, i) => _PlanCard(plan: allPlans[i], formatDate: _formatDate),
                                ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 36)),

                  // ── My plans section title ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: const Text('Your Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.3)),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  myPlans.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.travel_explore_rounded, size: 40, color: AppColors.accent.withOpacity(0.4)),
                                  const SizedBox(height: 12),
                                  const Text('No plans yet', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 17)),
                                  const SizedBox(height: 6),
                                  Text('Join a plan or create your own!', style: TextStyle(color: AppColors.subtle, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: _MyPlanTile(plan: myPlans[i], userId: userId, formatDate: _formatDate),
                            ),
                            childCount: myPlans.length,
                          ),
                        ),

                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _emptyNearby() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.explore_outlined, size: 40, color: AppColors.subtle.withOpacity(0.5)),
        const SizedBox(height: 12),
        Text('No plans around yet', style: TextStyle(color: AppColors.subtle, fontSize: 14)),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan))),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean neutral top block
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 110,
                color: AppColors.inputFill,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (vibe != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: Text(vibe, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ),
                        const Spacer(),
                        const Icon(Icons.favorite_border_rounded, size: 18, color: AppColors.subtle),
                      ],
                    ),
                    const Spacer(),
                    if (isFull)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                        child: const Text('Full', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('by $hostName', style: const TextStyle(fontSize: 13, color: AppColors.subtle)),
                  const SizedBox(height: 10),
                  if (plan['datetime'] != null)
                    Row(children: [
                      Icon(Icons.schedule_rounded, size: 13, color: AppColors.accent),
                      const SizedBox(width: 5),
                      Expanded(child: Text(formatDate(plan['datetime']), style: TextStyle(fontSize: 12, color: AppColors.subtle, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    ]),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.location_on_rounded, size: 13, color: AppColors.accent),
                      const SizedBox(width: 5),
                      Expanded(child: Text(location, style: TextStyle(fontSize: 12, color: AppColors.subtle, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
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

  const _MyPlanTile({required this.plan, required this.userId, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final title = plan['title'] ?? 'Untitled';
    final vibe = plan['vibe'] as String?;
    final isHost = plan['host_id'] == userId;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: AppColors.vibeBg(vibe?.toLowerCase()), borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: Text(
                  vibe?.isNotEmpty == true ? vibe![0].toUpperCase() : 'P',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.vibeFg(vibe?.toLowerCase())),
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
                      Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary), overflow: TextOverflow.ellipsis)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: isHost ? AppColors.accent.withOpacity(0.1) : AppColors.inputFill, borderRadius: BorderRadius.circular(8)),
                        child: Text(isHost ? 'Host' : 'Joined', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isHost ? AppColors.accent : AppColors.subtle)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (plan['datetime'] != null)
                    Text(formatDate(plan['datetime']), style: TextStyle(fontSize: 12, color: AppColors.subtle, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.subtle.withOpacity(0.5), size: 22),
          ],
        ),
      ),
    );
  }
}
