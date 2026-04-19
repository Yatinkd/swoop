import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'group_chat_screen.dart';
import '../main.dart';

class PlanDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  const PlanDetailsScreen({Key? key, required this.plan}) : super(key: key);

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;
  bool isRequesting = false;

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

  String _formatDt(String? dt) {
    if (dt == null) return '';
    final d = DateTime.parse(dt);
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = d.hour;
    final min = d.minute.toString().padLeft(2,'0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${d.day} ${months[d.month-1]}, $h12:$min $amPm';
  }

  Future<void> requestToJoin() async {
    setState(() => isRequesting = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final profile = await supabase.from('profiles').select('name, profile_image').eq('id', user.id).single();
      await supabase.from('join_requests').insert({
        'plan_id': widget.plan['id'],
        'user_id': user.id,
        'user_name': profile['name'] ?? 'User',
        'user_image': profile['profile_image'],
        'status': 'pending',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Request sent! ✈️'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isRequesting = false);
    }
  }

  Future<void> _updateRequest(int requestId, String userId, String status) async {
    try {
      await supabase.from('join_requests').update({'status': status}).eq('id', requestId);
      if (status == 'accepted') {
        final current = await supabase.from('plans').select('participants').eq('id', widget.plan['id']).single();
        List<dynamic> parts = List.from(current['participants'] ?? []);
        if (!parts.contains(userId)) {
          parts.add(userId);
          await supabase.from('plans').update({'participants': parts}).eq('id', widget.plan['id']);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request ${status == 'accepted' ? 'accepted 🎉' : 'rejected'}'),
          backgroundColor: status == 'accepted' ? AppColors.success : AppColors.accent,
          behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;
    final isHost = widget.plan['host_id'] == currentUserId;
    final participants = List<String>.from(widget.plan['participants'] ?? []);
    final isJoined = currentUserId != null && participants.contains(currentUserId);
    final title = widget.plan['title'] ?? 'Untitled';
    final vibe = widget.plan['vibe'] as String?;
    final hostName = widget.plan['host_name'] ?? 'Someone';
    final maxSize = widget.plan['max_size'] ?? 5;
    final isFull = participants.length >= maxSize;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── Clean Dark Header ────────────────────────
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white70),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    if (vibe != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(vibe, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                      ),
                    Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5, height: 1.1)),
                    const SizedBox(height: 16),
                    Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 15, color: Colors.white54),
                      const SizedBox(width: 6),
                      Text(_formatDt(widget.plan['datetime']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70)),
                    ]),
                    if ((widget.plan['location'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on_rounded, size: 15, color: Colors.white54),
                        const SizedBox(width: 6),
                        Expanded(child: Text(widget.plan['location'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Tabs ────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.subtle,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              dividerColor: AppColors.divider,
              tabs: const [Tab(text: 'About'), Tab(text: 'Host'), Tab(text: 'Going')],
            ),
          ),

          // ── Content ─────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // About
                ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if ((widget.plan['description'] ?? '').isNotEmpty) ...[
                      Text('About', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      const SizedBox(height: 10),
                      Text(widget.plan['description'], style: const TextStyle(fontSize: 15, color: AppColors.primary, height: 1.6)),
                      const SizedBox(height: 24),
                    ],
                    _infoCard(Icons.people_alt_rounded, '${participants.length} / $maxSize going'),
                    if (isFull) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          Icon(Icons.block_rounded, color: AppColors.accent, size: 18),
                          const SizedBox(width: 10),
                          Text('This plan is full', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14)),
                        ]),
                      ),
                    ],
                  ],
                ),

                // Host
                ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.accent.withOpacity(0.12),
                            backgroundImage: widget.plan['host_image'] != null ? NetworkImage(widget.plan['host_image']) : null,
                            child: widget.plan['host_image'] == null
                                ? Text(hostName[0].toUpperCase(), style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 22))
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(hostName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Text('Event Host', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Going
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase.from('plans').stream(primaryKey: ['id']).eq('id', widget.plan['id']),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();
                    final currentParticipants = List<String>.from(snapshot.data!.first['participants'] ?? []);
                    if (currentParticipants.isEmpty) {
                      return const Center(child: Text('No one has joined yet!', style: TextStyle(color: AppColors.subtle)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: currentParticipants.length,
                      itemBuilder: (ctx, i) {
                        return FutureBuilder<Map<String, dynamic>>(
                          future: supabase.from('profiles').select('name, profile_image').eq('id', currentParticipants[i]).single(),
                          builder: (ctx, profileSnap) {
                            if (!profileSnap.hasData) return const SizedBox();
                            final pData = profileSnap.data!;
                            final pName = pData['name'] ?? 'User';
                            final pImg = pData['profile_image'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.accent.withOpacity(0.1),
                                  backgroundImage: pImg != null ? NetworkImage(pImg) : null,
                                  child: pImg == null ? Text(pName[0].toUpperCase(), style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)) : null,
                                ),
                                const SizedBox(width: 14),
                                Text(pName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              ]),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom CTA ──────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase.from('join_requests').stream(primaryKey: ['id']).eq('plan_id', widget.plan['id']),
          builder: (context, reqSnapshot) {
            String myStatus = 'none';
            if (reqSnapshot.hasData && currentUserId != null) {
              final myReqs = reqSnapshot.data!.where((r) => r['user_id'] == currentUserId).toList();
              if (myReqs.isNotEmpty) myStatus = myReqs.first['status'];
            }

            Widget btnChild;
            VoidCallback? onPressed;
            Color btnColor = AppColors.accent;

            if (isHost) {
              // Show pending requests summary
              return _buildHostBar(reqSnapshot.data ?? []);
            } else if (isJoined) {
              btnChild = const Text('Open Group Chat 💬');
              onPressed = () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(plan: widget.plan)));
              btnColor = AppColors.success;
            } else if (myStatus == 'pending') {
              btnChild = const Text('Waiting for approval...');
              btnColor = AppColors.subtle;
            } else if (isFull) {
              btnChild = const Text('Plan is Full');
              btnColor = AppColors.subtle;
            } else {
              btnChild = isRequesting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Request to Join');
              onPressed = isRequesting ? null : requestToJoin;
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))]),
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(backgroundColor: btnColor),
                child: btnChild,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHostBar(List<Map<String, dynamic>> allReqs) {
    final pending = allReqs.where((r) => r['status'] == 'pending').toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pending.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: pending.map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 18, backgroundColor: AppColors.inputFill,
                        child: Text(req['user_name']?[0]?.toUpperCase() ?? 'U', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(req['user_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                      GestureDetector(
                        onTap: () => _updateRequest(req['id'], req['user_id'], 'rejected'),
                        child: const Icon(Icons.close_rounded, color: AppColors.accent, size: 22),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _updateRequest(req['id'], req['user_id'], 'accepted'),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(plan: widget.plan))),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Open Group Chat'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.accent, size: 18)),
        const SizedBox(width: 14),
        Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]),
    );
  }
}
