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

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  final supabase = Supabase.instance.client;
  bool isRequesting = false;

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
        SnackBar(content: const Text('Request sent!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
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
        SnackBar(content: Text('Request $status'), backgroundColor: status == 'accepted' ? AppColors.success : AppColors.accent, behavior: SnackBarBehavior.floating),
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
    final hostName = widget.plan['host_name'] ?? 'Someone';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Plan Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Host card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                    child: Text(hostName[0].toUpperCase(), style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hostName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(isHost ? 'You · Host' : 'Host', style: TextStyle(color: AppColors.subtle, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(widget.plan['title'] ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2)),
            if (widget.plan['description'] != null && widget.plan['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(widget.plan['description'], style: TextStyle(fontSize: 15, color: AppColors.subtle, height: 1.5)),
            ],
            const SizedBox(height: 24),

            // Info rows
            _detailRow(Icons.location_on_outlined, widget.plan['location'] ?? 'No location'),
            if (widget.plan['datetime'] != null) ...[
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final dt = DateTime.parse(widget.plan['datetime']);
                return _detailRow(Icons.access_time_outlined, '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}');
              }),
            ],
            if (widget.plan['vibe'] != null) ...[
              const SizedBox(height: 12),
              _detailRow(Icons.local_fire_department_outlined, widget.plan['vibe']),
            ],
            const SizedBox(height: 12),
            _detailRow(Icons.people_outline, '${participants.length} / ${widget.plan['max_size'] ?? 5} joined'),

            const SizedBox(height: 32),

            // Chat button (host + accepted members)
            if (isHost || isJoined)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(plan: widget.plan))),
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text('Open Group Chat'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                ),
              ),

            // Join button (guests who haven't joined)
            if (!isHost && !isJoined) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isRequesting ? null : requestToJoin,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  child: isRequesting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Request to Join'),
                ),
              ),
            ],

            // Host: pending requests
            if (isHost) ...[
              const SizedBox(height: 32),
              Text('Join Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase.from('join_requests').stream(primaryKey: ['id']).eq('plan_id', widget.plan['id']).order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.accent)));
                  final requests = snapshot.data!.where((r) => r['status'] == 'pending').toList();
                  if (requests.isEmpty) return Padding(padding: const EdgeInsets.all(20), child: Text('No pending requests', style: TextStyle(color: AppColors.subtle)));

                  return Column(
                    children: requests.map((req) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 20, backgroundColor: AppColors.inputFill, child: const Icon(Icons.person_outline, color: AppColors.primary)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(req['user_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600))),
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: AppColors.success),
                              onPressed: () => _updateRequest(req['id'], req['user_id'], 'accepted'),
                            ),
                            IconButton(
                              icon: Icon(Icons.cancel, color: AppColors.accent),
                              onPressed: () => _updateRequest(req['id'], req['user_id'], 'rejected'),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }
}
