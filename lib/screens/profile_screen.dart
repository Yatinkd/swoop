import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/plan_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/plan_formatters.dart';
import '../widgets/profile/profile_vibe_tags_editor.dart';
import 'hosted_events_screen.dart';
import 'onboarding/onboarding_data.dart';
import 'onboarding/step1_name_photo_screen.dart';
import 'activity_screen.dart';
import 'my_events_screen.dart';
import 'settings_screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  final _repo = PlanRepository();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  int _hosted = 0;
  int _joined = 0;
  List<dynamic> _recentActivity = [];
  List<dynamic> _upcomingPlans = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase.from('profiles').select().eq('id', userId).single();
      final myPlans = await _repo.fetchMyPlans(userId);
      final hosted = myPlans.where((p) => p.hostId == userId).length;
      final joined = myPlans.where((p) => p.participants.contains(userId) && p.hostId != userId).length;
      final upcoming = myPlans.where((p) => !p.isPast).take(3).map((p) => p.toMap()).toList();

      if (!mounted) return;
      setState(() {
        _profile = data;
        _hosted = hosted;
        _joined = joined;
        _recentActivity = myPlans.take(5).map((p) => p.toMap()).toList();
        _upcomingPlans = upcoming;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEdit() async {
    final p = _profile ?? {};
    final data = OnboardingData();
    data.isEditing = true;
    data.name = p['name'] ?? '';
    data.location = p['location'] ?? '';
    data.bioEnjoy = p['bio']?.toString() ?? '';
    data.interestsList = (p['interests'] as List?)?.map((e) => e.toString()).toList() ?? [];
    data.university = p['university'] ?? '';
    data.major = p['major'] ?? '';
    data.gradYear = p['graduation_year'] ?? '';
    if (p['vibe_tags'] != null) data.vibes = List<String>.from(p['vibe_tags']);
    data.existingImageUrl = p['profile_image'];

    final didUpdate = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step1NamePhotoScreen(initialData: data)),
    );
    if (didUpdate == true) {
      setState(() => _isLoading = true);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: Text('Could not load profile.')),
      );
    }

    final name = (_profile!['name'] ?? 'Unknown').toString();
    final bio = (_profile!['bio'] ?? '').toString();
    final imageUrl = _profile!['profile_image'] as String?;
    final location = (_profile!['location'] ?? '').toString();
    final vibeTags = (_profile!['vibe_tags'] as List?)?.cast<String>() ?? [];
    final initials = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    const reliabilityScore = 96;
    const rating = 4.9;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.accent,
          strokeWidth: 2,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Profile', style: AppTextStyles.largeHeading.copyWith(fontSize: 30)),
                    const Spacer(),
                    TextButton(onPressed: _openEdit, child: const Text('Edit')),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppColors.radiusLg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.softShadow(0.04),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.bgSecondary,
                        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                        child: imageUrl == null
                            ? Text(initials, style: AppTextStyles.sectionHeading.copyWith(fontSize: 28))
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: AppTextStyles.sectionHeading),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(location, style: AppTextStyles.bodySmall),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _statTile('Hosted', '$_hosted')),
                          _divider(),
                          Expanded(child: _statTile('Joined', '$_joined')),
                          _divider(),
                          Expanded(child: _statTile('Rating', rating.toStringAsFixed(1))),
                          _divider(),
                          Expanded(child: _statTile('Reliability', '$reliabilityScore%')),
                        ],
                      ),
                    ],
                  ),
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('About', style: AppTextStyles.label),
                  const SizedBox(height: 10),
                  Text(bio, style: AppTextStyles.body),
                ],
                const SizedBox(height: 28),
                ProfileVibeTagsEditor(
                  initialTags: vibeTags,
                  onTagsChanged: (tags) {
                    setState(() {
                      _profile = Map<String, dynamic>.from(_profile!)
                        ..['vibe_tags'] = tags;
                    });
                  },
                ),
                if (_upcomingPlans.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Upcoming plans', style: AppTextStyles.label),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyEventsScreen()),
                        ),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPlanList(_upcomingPlans),
                ],
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent activity', style: AppTextStyles.label),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityScreen()),
                      ),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildActivityList(),
                const SizedBox(height: 28),
                Text('More', style: AppTextStyles.label),
                const SizedBox(height: 10),
                _buildSettings(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: AppColors.border,
      );

  Widget _statTile(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlanList(List<dynamic> plans) {
    final userId = supabase.auth.currentUser?.id;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: plans.asMap().entries.map((entry) {
          final plan = entry.value;
          final isLast = entry.key == plans.length - 1;
          final isHost = plan['host_id'] == userId;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                title: Text(plan['title'] ?? 'Plan', style: AppTextStyles.bodyMedium),
                subtitle: Text(
                  PlanFormatters.formatShortDate(DateTime.parse(plan['datetime'].toString())),
                  style: AppTextStyles.caption,
                ),
                trailing: Text(
                  isHost ? 'Hosting' : 'Going',
                  style: AppTextStyles.caption.copyWith(color: AppColors.accent),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyEventsScreen()),
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 18, endIndent: 18),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityList() {
    if (_recentActivity.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('No activity yet.', style: AppTextStyles.bodySmall),
      );
    }

    final userId = supabase.auth.currentUser?.id;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _recentActivity.asMap().entries.map((entry) {
          final plan = entry.value;
          final isLast = entry.key == _recentActivity.length - 1;
          final isHost = plan['host_id'] == userId;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                title: Text(plan['title'] ?? 'Plan', style: AppTextStyles.bodyMedium),
                subtitle: Text(
                  PlanFormatters.formatShortDate(DateTime.parse(plan['datetime'].toString())),
                  style: AppTextStyles.caption,
                ),
                trailing: Text(
                  isHost ? 'Hosted' : 'Joined',
                  style: AppTextStyles.caption.copyWith(color: AppColors.text),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyEventsScreen()),
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 18, endIndent: 18),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.confirmation_number_outlined,
            label: 'Ticketed events',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HostedEventsScreen()),
            ),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.lock_outline,
            label: 'Privacy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.help_outline,
            label: 'Help',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
            ),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.logout,
            label: 'Log out',
            onTap: () async => supabase.auth.signOut(),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
