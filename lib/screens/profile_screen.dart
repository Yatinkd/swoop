import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import 'onboarding/onboarding_data.dart';
import 'onboarding/step1_name_photo_screen.dart';
import 'activity_screen.dart';
import 'hosted_events_screen.dart';
import 'my_events_screen.dart';
import 'settings_screens.dart'; // We will create this

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  // Real activity: list of plans where user is host or participant
  List<Map<String, dynamic>> _recentActivity = [];
  bool _activityLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadRecentActivity();
  }

  Future<void> _load() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      if (!mounted) return;
      setState(() {
        _profile = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // Fetch the 3 most recent plans the user hosted or joined
  Future<void> _loadRecentActivity() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final allPlans = await supabase
          .from('plans')
          .select()
          .order('datetime', ascending: false);

      final mine = <Map<String, dynamic>>[];
      for (final p in (allPlans as List)) {
        final isHost = p['host_id'] == userId;
        final isParticipant =
            List<String>.from(p['participants'] ?? []).contains(userId);
        if (isHost || isParticipant) {
          mine.add(Map<String, dynamic>.from(p));
        }
        if (mine.length == 3) break; // Only keep 3 for preview
      }

      if (mounted) {
        setState(() {
          _recentActivity = mine;
          _activityLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _activityLoading = false);
    }
  }

  Future<void> _openEdit() async {
    final Map<String, dynamic> p = _profile ?? {};
    final data = OnboardingData();
    data.isEditing = true;
    data.name = p['name'] ?? '';
    data.location = p['location'] ?? '';

    // Attempt parse of legacy separated bio chunks
    final String rawBio = p['bio']?.toString() ?? '';
    if (rawBio.contains('Weekend:')) {
      final parts = rawBio.split(RegExp(r'\n?Weekend: '));
      data.bioEnjoy = parts[0].replaceAll('Enjoy: ', '').trim();
      if (parts.length > 1) {
        data.bioWeekend = parts[1].trim();
      }
    } else {
      data.bioEnjoy = rawBio;
    }

    final interests = p['interests'] as List<dynamic>?;
    data.interestsList = interests?.map((e) => e.toString()).toList() ?? [];
    data.university = p['university'] ?? '';
    data.major = p['major'] ?? '';
    data.gradYear = p['graduation_year'] ?? '';

    if (p['vibe_tags'] != null) {
      data.vibes = List<String>.from(p['vibe_tags']);
    } else if (p['vibe_tag'] != null) {
      data.vibes = [p['vibe_tag']];
    }
    data.existingImageUrl = p['profile_image'];

    final didUpdate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Step1NamePhotoScreen(initialData: data),
      ),
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
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
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
    final vibes = (_profile!['vibe_tags'] as List?)?.cast<String>() ?? [];
    final initials = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final isCompactPhone = MediaQuery.sizeOf(context).width < 380;

    // Helper: format a datetime string for display in the activity preview
    String formatDate(String? dt) {
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),

              // 1. IMPROVED TOP SECTION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: isCompactPhone ? 34 : 38,
                          backgroundColor: AppColors.inputFill,
                          backgroundImage: imageUrl != null
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl == null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: isCompactPhone ? 19 : 21,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Events Joined
                          Row(
                            children: const [
                              Text(
                                '12 events joined',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.subtle,
                                ),
                              ),
                            ],
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.subtle,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(
                                      color: AppColors.subtle,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
              const SizedBox(height: 20),

              // 2. FIXED STATS SECTION
              Row(
                children: [
                  Expanded(
                    child: _QuickStatCard(
                      label: 'Hosted',
                      value: '4', // mock value
                      icon: Icons.celebration_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HostedEventsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickStatCard(
                      label: 'Joined',
                      value: '12', // mock value
                      icon: Icons.people_outline_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyEventsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // 3. ABOUT SECTION
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
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
                  child: Text(
                    bio,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],

              // 4. VIBES SECTION
              if (vibes.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text(
                  'Vibes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: vibes
                      .map(
                        (v) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            v,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              // 5. ACTIVITY SECTION (shows up to 3 real events)
              const SizedBox(height: 32),
              const Text(
                'Your Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              if (_activityLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (_recentActivity.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Center(
                    child: Text(
                      'No activity yet — join or host a plan!',
                      style: TextStyle(
                        color: AppColors.subtle,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ..._recentActivity.map((plan) {
                  final userId = supabase.auth.currentUser?.id;
                  final isHost = plan['host_id'] == userId;
                  final title = plan['title'] ?? 'Untitled';
                  final dateStr = formatDate(plan['datetime']);
                  final status = isHost ? 'Hosted' : 'Joined';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ActivityCard(
                      title: title,
                      date: dateStr,
                      status: status,
                    ),
                  );
                }),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Navigate to real ActivityScreen with Upcoming/Past tabs
                        builder: (_) => const ActivityScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'View all →',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              // 7. SETTINGS SECTION
              const SizedBox(height: 48),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.subtle,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.divider,
                    ),
                    _MenuTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Privacy',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.divider,
                    ),
                    _MenuTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help Center',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpCenterScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.divider,
                    ),
                    _MenuTile(
                      icon: Icons.exit_to_app_rounded,
                      label: 'Log Out',
                      color: AppColors.accent,
                      onTap: () async {
                        await supabase.auth.signOut();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.subtle.withValues(alpha: 0.5),
        size: 22,
      ),
      onTap: onTap,
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
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
        child: Column(
          children: [
            Icon(icon, color: AppColors.subtle, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.subtle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
