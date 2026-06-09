import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'group_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Messages', style: AppTextStyles.largeHeading.copyWith(fontSize: 28)),
            ),
            Expanded(child: _buildPlanChats()),
          ],
        ),
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
        if (!snapshot.hasData) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final myPlans = snapshot.data!.where((p) {
          final parts = List<String>.from(p['participants'] ?? []);
          return p['host_id'] == userId || parts.contains(userId);
        }).toList();

        if (myPlans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Join a plan to start chatting.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: myPlans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final plan = myPlans[index];
            final unread = index == 0 ? 2 : 0;
            final isOnline = index == 0;
            final isTyping = index == 0;
            final previews = ['See you at 7', 'On my way', 'Sounds good'];
            final senders = ['Rohan', 'Sarah', 'Arjun'];

            return _ChatTile(
              title: plan['title'] ?? 'Plan chat',
              subtitle: isTyping
                  ? 'typing...'
                  : '${senders[index % senders.length]}: ${previews[index % previews.length]}',
              time: timeago.format(
                DateTime.now().subtract(Duration(minutes: index * 12 + 3)),
                locale: 'en_short',
              ),
              unread: unread,
              isOnline: isOnline,
              isTyping: isTyping,
              initials: (plan['title'] as String? ?? 'P')[0].toUpperCase(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GroupChatScreen(plan: plan)),
              ),
            );
          },
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final int unread;
  final bool isOnline;
  final bool isTyping;
  final String initials;
  final VoidCallback onTap;

  const _ChatTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
    required this.isOnline,
    required this.isTyping,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.chipBg,
                    child: Text(initials, style: AppTextStyles.bodyMedium),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.card, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(time, style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isTyping ? AppColors.text : AppColors.textSecondary,
                        fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
