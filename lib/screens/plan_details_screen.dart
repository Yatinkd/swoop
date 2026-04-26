import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'group_chat_screen.dart';
import '../main.dart';
import '../services/event_status_service.dart';

class PlanDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  const PlanDetailsScreen({Key? key, required this.plan}) : super(key: key);

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  final supabase = Supabase.instance.client;
  bool isRequesting = false;

  // ── Real-time completion timer ──────────────────────────────────
  Timer? _completionTimer;

  @override
  void initState() {
    super.initState();
    // Silently write status='completed' if event has ended
    EventStatusService.autoMarkIfNeeded(widget.plan);
    // Rebuild every 30 s — re-evaluates isCompleted() in real time
    _completionTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) { if (mounted) setState(() {}); },
    );
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────

  String _formatDt(String? dt) {
    if (dt == null) return '';
    final d = EventStatusService.parseLocalTime(dt) ?? DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour;
    final min = d.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${d.day} ${months[d.month - 1]}, $h12:$min $amPm';
  }

  // ── Actions ──────────────────────────────────────────────────────

  Future<void> requestToJoin() async {
    setState(() => isRequesting = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final profile = await supabase
          .from('profiles')
          .select('name, profile_image')
          .eq('id', user.id)
          .single();
      await supabase.from('join_requests').insert({
        'plan_id': widget.plan['id'],
        'user_id': user.id,
        'user_name': profile['name'] ?? 'User',
        'user_image': profile['profile_image'],
        'status': 'pending',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent! ✈️'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isRequesting = false);
    }
  }

  Future<void> _updateRequest(
      int requestId, String userId, String status) async {
    try {
      await supabase
          .from('join_requests')
          .update({'status': status}).eq('id', requestId);
      if (status == 'accepted') {
        final current = await supabase
            .from('plans')
            .select('participants')
            .eq('id', widget.plan['id'])
            .single();
        final parts = List<dynamic>.from(current['participants'] ?? []);
        if (!parts.contains(userId)) {
          parts.add(userId);
          await supabase
              .from('plans')
              .update({'participants': parts}).eq('id', widget.plan['id']);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Request ${status == 'accepted' ? 'accepted 🎉' : 'rejected'}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── 3-dot menu ───────────────────────────────────────────────────

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.accent),
              title: const Text(
                'Report Event',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted. Thank you.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: AppColors.subtle),
              title: const Text(
                'Block User',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.subtle,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;
    final isHost = widget.plan['host_id'] == currentUserId;
    final participants =
        List<String>.from(widget.plan['participants'] ?? []);
    final isJoined =
        currentUserId != null && participants.contains(currentUserId);
    final title = (widget.plan['title'] ?? 'Untitled').toString();
    final vibe = widget.plan['vibe'] as String?;
    final hostName = (widget.plan['host_name'] ?? 'Someone').toString();
    final hostImage = widget.plan['host_image'] as String?;
    final maxSize = widget.plan['max_size'] ?? 5;
    final isFull = participants.length >= maxSize;
    final description =
        (widget.plan['description'] ?? '').toString().trim();
    final location = (widget.plan['location'] ?? '').toString().trim();
    final coverImage = widget.plan['cover_image'] as String?;

    // ── Completion detection ─────────────────────────────────────
    final bool isCompleted = () {
      final dtString = widget.plan['datetime'];
      if (dtString == null) return false;
      final status = (widget.plan['status'] ?? '').toString();
      final dt = EventStatusService.parseLocalTime(dtString);
      return status == 'completed' ||
          (dt != null && DateTime.now().isAfter(dt));
    }();

    // ── Access guard: non-participants cannot view completed events ──
    if (isCompleted && !isHost && !isJoined) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primary),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    size: 46,
                    color: AppColors.subtle,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Event Completed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This event has ended.\nOnly participants can view it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.subtle,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Main screen ───────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── Minimal App Bar ───────────────────────────────────
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                      color: AppColors.primary,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    // 3-dot menu ONLY — no heart or share
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 22),
                      color: AppColors.primary,
                      onPressed: () => _showMenu(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable Content ────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Cover Image (≈200px, rounded) ────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: AppColors.inputFill,
                      child: coverImage != null
                          ? Image.network(coverImage, fit: BoxFit.cover)
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.accent
                                        .withValues(alpha: 0.15),
                                    AppColors.primary
                                        .withValues(alpha: 0.07),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  title.isNotEmpty
                                      ? title[0].toUpperCase()
                                      : 'P',
                                  style: TextStyle(
                                    fontSize: 72,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                // ── Completed banner (only for host/participant) ──
                if (isCompleted)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 16, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'This event has ended',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Header: vibe pill + title + date + location ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vibe tag
                      if (vibe != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            vibe,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Date & time
                      if (widget.plan['datetime'] != null)
                        _InfoRow(
                          Icons.calendar_today_rounded,
                          _formatDt(widget.plan['datetime']),
                        ),
                      // Location
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _InfoRow(Icons.location_on_rounded, location),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Going count ───────────────────────────────────
                _Card(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_alt_rounded,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${participants.length} / $maxSize going',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      if (isFull && !isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Full',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── About ─────────────────────────────────────────
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Host ──────────────────────────────────────────
                const SizedBox(height: 12),
                _Card(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppColors.accent.withValues(alpha: 0.1),
                        backgroundImage: hostImage != null
                            ? NetworkImage(hostImage)
                            : null,
                        child: hostImage == null
                            ? Text(
                                hostName.isNotEmpty
                                    ? hostName[0].toUpperCase()
                                    : 'H',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hostName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(
                              'Host',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.subtle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Pending join requests (host only) ─────────────
                if (isHost)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase
                        .from('join_requests')
                        .stream(primaryKey: ['id']).eq(
                            'plan_id', widget.plan['id']),
                    builder: (context, reqSnap) {
                      final pending = (reqSnap.data ?? [])
                          .where((r) => r['status'] == 'pending')
                          .toList();
                      if (pending.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pending.length} pending request${pending.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...pending.map(
                                (req) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            AppColors.inputFill,
                                        child: Text(
                                          req['user_name']?[0]
                                                  ?.toUpperCase() ??
                                              'U',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          req['user_name'] ?? 'User',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      // Reject
                                      GestureDetector(
                                        onTap: () => _updateRequest(
                                            req['id'],
                                            req['user_id'],
                                            'rejected'),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: AppColors.accent,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Accept
                                      GestureDetector(
                                        onTap: () => _updateRequest(
                                            req['id'],
                                            req['user_id'],
                                            'accepted'),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.success,
                                          size: 26,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom CTA ─────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: isCompleted
              // ── State 4: Event over ──────────────────────────────
              ? ElevatedButton(
                  onPressed: (isHost || isJoined)
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GroupChatScreen(plan: widget.plan),
                            ),
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isHost || isJoined)
                        ? AppColors.subtle
                        : AppColors.inputFill,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    (isHost || isJoined) ? 'View Chat' : 'Event Completed',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              // ── Host CTA ─────────────────────────────────────────
              : isHost
                  ? ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GroupChatScreen(plan: widget.plan),
                        ),
                      ),
                      icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18),
                      label: const Text(
                        'Open Group Chat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  // ── Non-host: stream-driven CTA ──────────────────
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase
                          .from('join_requests')
                          .stream(primaryKey: ['id']).eq(
                              'plan_id', widget.plan['id']),
                      builder: (context, reqSnap) {
                        // Determine current request status for this user
                        String myStatus = 'none';
                        if (reqSnap.hasData && currentUserId != null) {
                          final myReqs = reqSnap.data!
                              .where(
                                  (r) => r['user_id'] == currentUserId)
                              .toList();
                          if (myReqs.isNotEmpty) {
                            myStatus = myReqs.first['status'];
                          }
                        }

                        // ── State mapping ────────────────────────
                        // State 1: already a participant → Open Chat
                        // State 2: request pending      → Requested (disabled)
                        // State 3: plan full            → Plan is Full (disabled)
                        // State 0: default              → Request to Join

                        final String label;
                        final Color btnColor;
                        final VoidCallback? onTap;

                        if (isJoined) {
                          label = 'Open Group Chat 💬';
                          btnColor = AppColors.success;
                          onTap = () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GroupChatScreen(plan: widget.plan),
                                ),
                              );
                        } else if (myStatus == 'pending') {
                          label = 'Requested ✈️';
                          btnColor = AppColors.subtle;
                          onTap = null;
                        } else if (isFull) {
                          label = 'Plan is Full';
                          btnColor = AppColors.subtle;
                          onTap = null;
                        } else {
                          label = 'Request to Join';
                          btnColor = AppColors.accent;
                          onTap =
                              isRequesting ? null : requestToJoin;
                        }

                        return ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: btnColor,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isRequesting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

// ── Reusable card wrapper ─────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── Small info row (icon + text) ──────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.subtle),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.subtle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
