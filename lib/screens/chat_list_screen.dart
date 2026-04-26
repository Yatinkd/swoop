import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'group_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.subtle,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          dividerColor: AppColors.divider,
          tabs: const [
            Tab(text: 'Plans'),
            Tab(text: 'Direct'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPlanChats(), _buildPlaceholder('Direct Messages')],
      ),
    );
  }

  Widget _buildPlanChats() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const SizedBox();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('plans')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );

        final myPlans = snapshot.data!.where((p) {
          final parts = List<String>.from(p['participants'] ?? []);
          return p['host_id'] == userId || parts.contains(userId);
        }).toList();

        if (myPlans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: AppColors.subtle.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Join a plan to start chatting',
                  style: TextStyle(
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: myPlans.length,
          itemBuilder: (context, index) {
            final plan = myPlans[index];
            final vibe = plan['vibe'] as String?;
            return Container(
              margin: const EdgeInsets.only(bottom: 2, left: 16, right: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                leading: Container(
                  width: 54,
                  height: 54,
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
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  plan['title'] ?? 'Untitled Group',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_alt_rounded,
                        size: 12,
                        color: AppColors.subtle,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(plan['participants'] as List).length} members',
                        style: const TextStyle(
                          color: AppColors.subtle,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Container(
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupChatScreen(plan: plan),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
            color: AppColors.subtle.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No $title yet',
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
}
