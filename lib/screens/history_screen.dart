import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'plan_details_screen.dart';
import '../main.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  List<Map<String, dynamic>> _createdPlans = [];
  List<Map<String, dynamic>> _joinedPlans = [];
  List<Map<String, dynamic>> _myTickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final allPlans = await supabase.from('plans').select().order('datetime', ascending: false);

      final created = <Map<String, dynamic>>[];
      final joined = <Map<String, dynamic>>[];

      for (final p in (allPlans as List)) {
        final isHost = p['host_id'] == userId;
        final isParticipant = List<String>.from(p['participants'] ?? []).contains(userId);

        if (isHost) {
          created.add(Map<String, dynamic>.from(p));
        } else if (isParticipant) {
          joined.add(Map<String, dynamic>.from(p));
        }
      }

      final tickets = await supabase.from('tickets').select('*, hosted_events(*)').eq('user_id', userId).order('created_at', ascending: false);

      setState(() {
        _createdPlans = created;
        _joinedPlans = joined;
        _myTickets = List<Map<String, dynamic>>.from(tickets);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.subtle,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [Tab(text: 'Created'), Tab(text: 'Joined'), Tab(text: 'Tickets')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : TabBarView(controller: _tabController, children: [
              _plansTab(_createdPlans, isCreated: true),
              _plansTab(_joinedPlans, isCreated: false),
              _ticketsTab(),
            ]),
    );
  }

  Widget _plansTab(List<Map<String, dynamic>> plans, {required bool isCreated}) {
    if (plans.isEmpty) {
      return _empty(
        isCreated ? Icons.create_outlined : Icons.group_outlined,
        isCreated ? 'No plans created yet' : 'No plans joined yet',
        isCreated ? 'Create a plan and bring people together!' : 'Join a plan and meet new friends!',
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: plans.length,
        itemBuilder: (context, i) {
          final plan = plans[i];
          final title = plan['title'] ?? 'Untitled';
          final location = plan['location'] ?? '';
          final vibe = plan['vibe'];
          final participants = List<String>.from(plan['participants'] ?? []);
          DateTime? dt;
          if (plan['datetime'] != null) dt = DateTime.parse(plan['datetime']);
          final isPast = dt != null && dt.isBefore(DateTime.now());

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isPast
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPast ? Icons.check_circle_outline : Icons.event_outlined,
                      color: isPast ? AppColors.success : AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis)),
                            if (isPast)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text('Completed', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text('Upcoming', style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(location, style: TextStyle(color: AppColors.subtle, fontSize: 12), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Row(children: [
                          if (dt != null) Text(timeago.format(dt), style: TextStyle(fontSize: 11, color: AppColors.subtle)),
                          if (vibe != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                              child: Text(vibe, style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600)),
                            ),
                          ],
                          const Spacer(),
                          Text('${participants.length} ${isPast ? 'went' : 'going'}', style: TextStyle(fontSize: 11, color: AppColors.subtle)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _ticketsTab() {
    if (_myTickets.isEmpty) return _empty(Icons.confirmation_number_outlined, 'No tickets', 'Browse events and buy tickets!');
    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _myTickets.length,
        itemBuilder: (context, i) {
          final ticket = _myTickets[i];
          final ticketId = ticket['ticket_id'] ?? '???';
          final event = ticket['hosted_events'] as Map<String, dynamic>?;
          final eventTitle = event?['title'] ?? 'Unknown Event';
          final eventLocation = event?['location'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.confirmation_number_outlined, color: AppColors.success, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eventTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      if (eventLocation.isNotEmpty) Text(eventLocation, style: TextStyle(color: AppColors.subtle, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('Ticket: ', style: TextStyle(fontSize: 12, color: AppColors.subtle)),
                        Text(ticketId, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 1)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _empty(IconData icon, String title, String sub) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: AppColors.subtle.withValues(alpha: 0.4)),
      const SizedBox(height: 16),
      Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
      const SizedBox(height: 6),
      Text(sub, style: TextStyle(color: AppColors.subtle)),
    ]),
  );
}
