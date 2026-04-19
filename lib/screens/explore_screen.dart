import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'plan_details_screen.dart';
import '../main.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  final _categories = ['All', 'Chill', 'Party', 'Study', 'Adventure', 'Food', 'Sports'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String? dt) {
    if (dt == null) return '';
    final d = DateTime.parse(dt);
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header + Search ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Explore', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const SizedBox(height: 16),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(14)),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search plans, people...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.subtle, size: 22),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                                child: const Icon(Icons.close_rounded, size: 20, color: AppColors.subtle),
                              )
                            : null,
                        filled: false,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tabs ────────────────────────────────────
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.subtle,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              dividerColor: AppColors.divider,
              tabs: const [Tab(text: 'Events'), Tab(text: 'Users')],
            ),

            // ── Content ─────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PlansTab(
                    searchQuery: _searchQuery,
                    selectedCategory: _selectedCategory,
                    categories: _categories,
                    formatDate: _formatDate,
                    onCategorySelected: (c) => setState(() => _selectedCategory = (_selectedCategory == c || c == 'All') ? null : c),
                  ),
                  _PeopleTab(searchQuery: _searchQuery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plans Tab ────────────────────────────────────────────────────
class _PlansTab extends StatelessWidget {
  final String searchQuery;
  final String? selectedCategory;
  final List<String> categories;
  final String Function(String?) formatDate;
  final ValueChanged<String> onCategorySelected;

  const _PlansTab({
    required this.searchQuery, required this.selectedCategory,
    required this.categories, required this.formatDate,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    return Column(
      children: [
        // Category chips
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final isSelected = cat == 'All' ? selectedCategory == null : selectedCategory == cat;
              return GestureDetector(
                onTap: () => onCategorySelected(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected ? [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                  ),
                  child: Center(child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.primary))),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase.from('plans').stream(primaryKey: ['id']).order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
              var plans = snapshot.data!;

              if (searchQuery.isNotEmpty) {
                final q = searchQuery.toLowerCase();
                plans = plans.where((p) {
                  final t = (p['title'] ?? '').toString().toLowerCase();
                  final l = (p['location'] ?? '').toString().toLowerCase();
                  return t.contains(q) || l.contains(q);
                }).toList();
              }
              if (selectedCategory != null) {
                plans = plans.where((p) => (p['vibe'] ?? '').toString().toLowerCase() == selectedCategory!.toLowerCase()).toList();
              }

              if (plans.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    Icon(Icons.search_off_rounded, size: 48, color: AppColors.subtle),
                    SizedBox(height: 12),
                    Text('No plans found', style: TextStyle(color: AppColors.subtle, fontSize: 16)),
                  ]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                itemCount: plans.length,
                itemBuilder: (_, i) => _ExplorePlanTile(plan: plans[i], formatDate: formatDate),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExplorePlanTile extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String Function(String?) formatDate;

  const _ExplorePlanTile({required this.plan, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final title = plan['title'] ?? 'Untitled';
    final vibe = plan['vibe'] as String?;
    final hostName = plan['host_name'] ?? '';
    final location = plan['location'] ?? '';
    final participants = List<String>.from(plan['participants'] ?? []);
    final maxSize = plan['max_size'] ?? 5;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vibe thumbnail (neutral chip)
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.vibeBg(vibe?.toLowerCase()), borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: Text(
                  vibe?.isNotEmpty == true ? vibe![0].toUpperCase() : 'P',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.vibeFg(vibe?.toLowerCase())),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.favorite_border_rounded, size: 20, color: AppColors.subtle),
                  ]),
                  const SizedBox(height: 4),
                  if (vibe != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.vibeBg(vibe.toLowerCase()), borderRadius: BorderRadius.circular(8)),
                      child: Text(vibe, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.vibeFg(vibe.toLowerCase()))),
                    ),
                  if (hostName.isNotEmpty)
                    Text('Hosted by $hostName', style: const TextStyle(fontSize: 13, color: AppColors.subtle)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.people_alt_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text('${participants.length}/$maxSize going', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    const SizedBox(width: 14),
                    if (plan['datetime'] != null) ...[
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.subtle),
                      const SizedBox(width: 4),
                      Text(formatDate(plan['datetime']), style: const TextStyle(fontSize: 13, color: AppColors.subtle, fontWeight: FontWeight.w500)),
                    ],
                  ]),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.subtle),
                      const SizedBox(width: 4),
                      Expanded(child: Text(location, style: const TextStyle(fontSize: 13, color: AppColors.subtle), overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── People Tab ───────────────────────────────────────────────────
class _PeopleTab extends StatefulWidget {
  final String searchQuery;
  const _PeopleTab({required this.searchQuery});

  @override
  State<_PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<_PeopleTab> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;

  @override
  void didUpdateWidget(_PeopleTab old) {
    super.didUpdateWidget(old);
    if (old.searchQuery != widget.searchQuery) _search();
  }

  Future<void> _search() async {
    if (widget.searchQuery.isEmpty) { setState(() => _users = []); return; }
    setState(() => _loading = true);
    try {
      final results = await supabase.from('profiles').select('id, name, bio, profile_image, vibe_tags').ilike('name', '%${widget.searchQuery}%').limit(20);
      setState(() { _users = List<Map<String, dynamic>>.from(results); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchQuery.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.person_search_rounded, size: 48, color: AppColors.subtle),
        SizedBox(height: 12),
        Text('Search for amazing people', style: TextStyle(color: AppColors.subtle, fontSize: 16)),
      ]));
    }
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
    if (_users.isEmpty) return const Center(child: Text('No users found.', style: TextStyle(color: AppColors.subtle)));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: _users.length,
      itemBuilder: (_, i) {
        final u = _users[i];
        final name = u['name'] ?? 'User';
        final bio = u['bio'] ?? '';
        final vibes = (u['vibe_tags'] as List?)?.cast<String>() ?? [];
        final img = u['profile_image'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.accent.withOpacity(0.1),
              backgroundImage: img != null ? NetworkImage(img) : null,
              child: img == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 20)) : null,
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.primary)),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(bio, style: const TextStyle(fontSize: 13, color: AppColors.subtle), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (vibes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: vibes.take(3).map((v) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.vibeBg(v.toLowerCase()), borderRadius: BorderRadius.circular(8)),
                      child: Text(v, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.vibeFg(v.toLowerCase()))),
                    )
                  ).toList()),
                ],
              ],
            )),
          ]),
        );
      },
    );
  }
}
