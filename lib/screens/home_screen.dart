import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sample_data.dart';
import '../models/plan.dart';
import '../models/user_profile.dart';
import '../repositories/plan_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/plan_formatters.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/quick_action_chip.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/swoop_search_bar.dart';
import '../widgets/home/friend_activity_feed.dart';
import '../widgets/home/recommended_person_card.dart';
import '../widgets/plan/plan_card.dart';
import 'create_plan_screen.dart';
import 'explore_screen.dart';
import 'plan_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = PlanRepository();
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _profile;
  List<Plan> _plans = [];
  List<UserProfile> _recommended = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = _supabase.auth.currentUser?.id;
    try {
      if (userId != null) {
        final data = await _supabase
            .from('profiles')
            .select('name, location, profile_image, vibe_tags, interests')
            .eq('id', userId)
            .maybeSingle();
        _profile = data;
      }
    } catch (_) {}

    final plans = await _repo.fetchPlans();
    final recommended = await _loadRecommended(userId);

    if (mounted) {
      setState(() {
        _plans = plans;
        _recommended = recommended;
        _loading = false;
      });
    }
  }

  Future<List<UserProfile>> _loadRecommended(String? userId) async {
    try {
      final builder = _supabase
          .from('profiles')
          .select('id, name, profile_image, vibe_tags, interests, location')
          .eq('onboarding_complete', true);

      final rows = userId != null
          ? await builder.neq('id', userId).limit(8)
          : await builder.limit(8);
      final myVibes = List<String>.from(_profile?['vibe_tags'] ?? []);
      return (rows as List).map((row) {
        final vibes = List<String>.from(row['vibe_tags'] ?? []);
        final match = _vibeMatchPercent(myVibes, vibes);
        return UserProfile(
          id: row['id'].toString(),
          name: row['name']?.toString() ?? 'User',
          profileImage: row['profile_image']?.toString(),
          vibeTags: vibes,
          interests: List<String>.from(row['interests'] ?? []),
          vibeMatchPercent: match,
          rating: 4.7 + (match % 3) * 0.1,
        );
      }).toList()
        ..sort((a, b) => b.vibeMatchPercent.compareTo(a.vibeMatchPercent));
    } catch (_) {
      return SampleData.recommendedPeople;
    }
  }

  int _vibeMatchPercent(List<String> mine, List<String> theirs) {
    if (mine.isEmpty || theirs.isEmpty) return 72;
    final overlap = mine.where(theirs.contains).length;
    final total = mine.length + theirs.length - overlap;
    if (total == 0) return 70;
    return (70 + (overlap / total) * 30).round().clamp(70, 99);
  }

  void _openPlan(Plan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan.toMap())),
    );
  }

  void _openExplore() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExploreScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (_profile?['name'] as String?) ?? '';
    final upcoming = _plans.where((p) => !p.isPast).toList();
    final featured = _plans
        .where((p) => p.coverImage != null && p.coverImage!.isNotEmpty)
        .take(6)
        .toList();
    final activity = _repo.activityFeed();
    final people = _recommended.isNotEmpty ? _recommended : SampleData.recommendedPeople;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.accent,
          strokeWidth: 2,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PlanFormatters.greeting(name),
                        style: AppTextStyles.largeHeading,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        PlanFormatters.subGreeting(),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.navyLight,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SwoopSearchBar(
                        readOnly: true,
                        onTap: _openExplore,
                        hintText: 'Search experiences near you...',
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick start', style: AppTextStyles.label),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ...SampleData.quickActions.map(
                            (a) => QuickActionChip(
                              label: a.$1,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreatePlanScreen(initialVibe: a.$2),
                                ),
                              ),
                            ),
                          ),
                          QuickActionChip(
                            label: 'Create hangout',
                            isPrimary: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (featured.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 36)),
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Featured hangouts',
                    onSeeAll: _openExplore,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(child: _buildFeatured(featured)),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Upcoming',
                  trailing: upcoming.isNotEmpty ? '${upcoming.length}' : null,
                  onSeeAll: upcoming.isNotEmpty ? _openExplore : null,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _buildUpcoming(upcoming)),
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
              SliverToBoxAdapter(
                child: SectionHeader(title: 'People you might click with'),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _buildRecommended(people)),
              if (activity.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 36)),
                SliverToBoxAdapter(child: SectionHeader(title: 'Recent activity')),
                const SliverToBoxAdapter(child: SizedBox(height: 4)),
                SliverToBoxAdapter(child: FriendActivityFeed(items: activity)),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatured(List<Plan> plans) {
    return SizedBox(
      height: kHorizontalPlanCardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: plans.length,
        itemBuilder: (_, i) {
          final p = plans[i];
          return PlanCard(
            horizontal: true,
            title: p.title,
            hostName: p.hostName,
            location: p.location,
            dateTime: PlanFormatters.formatShortDate(p.datetime),
            attendeeCount: p.attendeeCount,
            maxSize: p.maxSize,
            category: p.category,
            coverImage: p.coverImage,
            onTap: () => _openPlan(p),
          );
        },
      ),
    );
  }

  Widget _buildUpcoming(List<Plan> plans) {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (plans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SwoopEmptyState(
          headline: 'No plans nearby yet',
          subheadline: 'Start one or browse Explore to find your crew.',
          primaryLabel: 'Create hangout',
          secondaryLabel: 'Explore',
          onPrimary: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
          ),
          onSecondary: _openExplore,
        ),
      );
    }

    return SizedBox(
      height: kHorizontalPlanCardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: plans.length,
        itemBuilder: (_, i) {
          final p = plans[i];
          return PlanCard(
            horizontal: true,
            title: p.title,
            hostName: p.hostName,
            location: p.location,
            dateTime: PlanFormatters.formatShortDate(p.datetime),
            attendeeCount: p.attendeeCount,
            maxSize: p.maxSize,
            category: p.category,
            coverImage: p.coverImage,
            onTap: () => _openPlan(p),
          );
        },
      ),
    );
  }

  Widget _buildRecommended(List<UserProfile> people) {
    return SizedBox(
      height: kRecommendedPersonCardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: people.length,
        itemBuilder: (_, i) => RecommendedPersonCard(profile: people[i]),
      ),
    );
  }
}
