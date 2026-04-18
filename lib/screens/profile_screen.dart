import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase.from('profiles').select().eq('id', userId).single();
      setState(() { _profile = data; _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          TextButton(
            onPressed: () async {
              await supabase.auth.signOut();
            },
            child: Text('Sign Out', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _profile == null
              ? const Center(child: Text('Could not load profile.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Avatar
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                        child: Text(
                          (_profile!['name'] ?? '?')[0].toUpperCase(),
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_profile!['name'] ?? 'Unknown', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        _profile!['email'] ?? supabase.auth.currentUser?.email ?? '',
                        style: TextStyle(color: AppColors.subtle, fontSize: 14),
                      ),
                      const SizedBox(height: 32),

                      _card('Bio', _profile!['bio'] ?? 'No bio yet', Icons.info_outline),
                      _card('Location', _profile!['location'] ?? 'Not set', Icons.location_on_outlined),
                      _card('Vibe', _profile!['vibe_tag'] ?? 'Not set', Icons.local_fire_department_outlined),
                      _card('Interests', (_profile!['interests'] as List<dynamic>?)?.join(', ') ?? 'None', Icons.interests_outlined),

                      const SizedBox(height: 24),
                      // App info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            Text('antigravity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            const SizedBox(height: 4),
                            Text('Find your crew. Make plans.', style: TextStyle(color: AppColors.subtle, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('v1.0.0', style: TextStyle(color: AppColors.subtle.withValues(alpha: 0.5), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _card(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: AppColors.subtle, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
