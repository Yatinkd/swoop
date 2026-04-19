import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'edit_profile_screen.dart';

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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase.from('profiles').select().eq('id', userId).single();
      setState(() { _profile = data; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(backgroundColor: AppColors.bg, body: const Center(child: CircularProgressIndicator(color: AppColors.accent)));
    if (_profile == null) return Scaffold(backgroundColor: AppColors.bg, body: const Center(child: Text('Could not load profile.')));

    final name = _profile!['name'] ?? 'Unknown';
    final bio = _profile!['bio'] ?? '';
    final imageUrl = _profile!['profile_image'];
    final location = _profile!['location'] ?? '';
    final vibes = (_profile!['vibe_tags'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient Header ──────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF2D2D4E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Account', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final didUpdate = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(currentProfile: _profile!)));
                      if (didUpdate == true) { setState(() => _isLoading = true); _load(); }
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.accent.withOpacity(0.2),
                          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                          child: imageUrl == null
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700))
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text(location, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    ]),
                  ],
                ],
              ),
            ),

            // ── Edit Button ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final didUpdate = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(currentProfile: _profile!)));
                  if (didUpdate == true) { setState(() => _isLoading = true); _load(); }
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

            // ── Bio ───────────────────────────────────────
            if (bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
                  child: Text(bio, style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.primary)),
                ),
              ),

            // ── Vibes ─────────────────────────────────────
            if (vibes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vibes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: vibes.map((v) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.vibeBg(v.toLowerCase()), borderRadius: BorderRadius.circular(24)),
                        child: Text(v, style: TextStyle(color: AppColors.vibeFg(v.toLowerCase()), fontWeight: FontWeight.w700, fontSize: 14)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Divider(indent: 24, endIndent: 24),

            // ── Menu ──────────────────────────────────────
            _MenuTile(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => _stub(context, 'Notifications')),
            _MenuTile(icon: Icons.lock_outline_rounded, label: 'Privacy', onTap: () => _stub(context, 'Privacy')),
            _MenuTile(icon: Icons.help_outline_rounded, label: 'Help Center', onTap: () => _stub(context, 'Help Center')),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.exit_to_app_rounded,
              label: 'Log Out',
              color: AppColors.accent,
              onTap: () async { await supabase.auth.signOut(); },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _stub(BuildContext context, String title) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: const Text('Coming soon!'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)))],
    ),
  );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.subtle.withOpacity(0.5), size: 22),
      onTap: onTap,
    );
  }
}
