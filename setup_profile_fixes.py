import re
import os

filepath = "/Users/yatinkd/community app/community_app/lib/screens/profile_screen.dart"

with open(filepath, "r") as f:
    content = f.read()

# 1. Add new imports needed
imports = """import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import 'edit_profile_screen.dart';
import 'activity_screen.dart';
import 'hosted_events_screen.dart';
import 'my_events_screen.dart';
import 'settings_screens.dart'; // We will create this"""

content = content.replace("""import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import 'edit_profile_screen.dart';
import 'activity_screen.dart';""", imports)

# 2. Remove top right settings icon
content = content.replace("""                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.subtle,
                    ),
                    onPressed: () => _stub(context, 'Settings'),
                  ),""", "                  const Spacer(),")

# 3. Remove rating from top section but keep events joined
top_rating_old = """                          // Rating & Events Joined
                          Row(
                            children: const [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.orange,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '4.5',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '·',
                                style: TextStyle(
                                  color: AppColors.subtle,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '12 events joined',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.subtle,
                                ),
                              ),
                            ],
                          ),"""
top_rating_new = """                          // Events Joined
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
                          ),"""
content = content.replace(top_rating_old, top_rating_new)

# 4. Clean stats section and make it functional
stats_old = """              // 2. FIXED STATS SECTION
              Row(
                children: const [
                  Expanded(
                    child: _QuickStatCard(
                      label: 'Hosted',
                      value: '4', // mock value
                      icon: Icons.celebration_outlined,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _QuickStatCard(
                      label: 'Joined',
                      value: '12', // mock value
                      icon: Icons.people_outline_rounded,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _QuickStatCard(
                      label: 'Rating',
                      value: '4.5', // mock value
                      icon: Icons.star_border_rounded,
                    ),
                  ),
                ],
              ),"""
stats_new = """              // 2. FIXED STATS SECTION
              Row(
                children: [
                  Expanded(
                    child: _QuickStatCard(
                      label: 'Hosted',
                      value: '4', // mock value
                      icon: Icons.celebration_outlined,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HostedEventsScreen()));
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
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyEventsScreen()));
                      },
                    ),
                  ),
                ],
              ),"""
content = content.replace(stats_old, stats_new)

# 5. Activity Card wrapped in gesture detector
activity_card_old = """                      child: ActivityCard(
                        title: act['title']!,
                        date: act['date']!,
                        status: act['status']!,
                      ),"""
activity_card_new = """                      child: GestureDetector(
                        onTap: () {
                           // Navigate to placeholder Event details screen logic, or to an actual page. Using stub/placeholder for mock since no actual ID is provided.
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity tracking click...')));
                        },
                        child: ActivityCard(
                          title: act['title']!,
                          date: act['date']!,
                          status: act['status']!,
                        ),
                      ),"""
content = content.replace(activity_card_old, activity_card_new)

# 6. Update Settings logic
settings_old = """                    _MenuTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      onTap: () => _stub(context, 'Notifications'),
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
                      onTap: () => _stub(context, 'Privacy'),
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
                      onTap: () => _stub(context, 'Help Center'),
                    ),"""
settings_new = """                    _MenuTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
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
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));
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
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
                      },
                    ),"""
content = content.replace(settings_old, settings_new)

# 7. Modify _QuickStatCard to accept onTap
quickstat_card_old = """class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container("""
quickstat_card_new = """class _QuickStatCard extends StatelessWidget {
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
      child: Container("""
content = content.replace(quickstat_card_old, quickstat_card_new)

# Close Container
content = content.replace("""        ],
      ),
    );
  }
}""", """        ],
      ),
    ),
    );
  }
}""")

with open(filepath, "w") as f:
    f.write(content)

# CREATE settings_screens.dart
settings_file_content = """import 'package:flutter/material.dart';
import '../main.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('No new notifications', style: TextStyle(color: AppColors.subtle))),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Privacy')),
      body: const Center(child: Text('Privacy settings coming soon', style: TextStyle(color: AppColors.subtle))),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Help Center')),
      body: const Center(child: Text('How can we help you?', style: TextStyle(color: AppColors.subtle))),
    );
  }
}
"""
with open("/Users/yatinkd/community app/community_app/lib/screens/settings_screens.dart", "w") as f:
    f.write(settings_file_content)

print("success fixes")
