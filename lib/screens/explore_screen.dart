import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/plan.dart';
import '../repositories/plan_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/plan_formatters.dart';
import '../widgets/common/category_chip.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/swoop_search_bar.dart';
import '../widgets/plan/happening_soon_card.dart';
import '../widgets/plan/plan_card.dart';
import 'plan_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final _repo = PlanRepository();

  String _query = '';
  String? _category;
  PlanSort _sort = PlanSort.startingSoon;
  List<Plan> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() => _loading = true);
    final plans = await _repo.fetchPlans();
    if (mounted) {
      setState(() {
        _plans = plans;
        _loading = false;
      });
    }
  }

  List<Plan> get _filtered {
    var result = _repo.searchPlans(_plans, _query);
    result = _repo.filterByCategory(result, _category);
    return _repo.sortPlans(result, _sort);
  }

  List<Plan> get _happeningSoon => _repo.happeningSoon(_plans);

  void _openPlan(Plan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan.toMap())),
    );
  }

  Future<void> _showSortSheet() async {
    final choice = await showModalBottomSheet<PlanSort>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Sort by', style: AppTextStyles.sectionHeading.copyWith(fontSize: 18)),
            ),
            ...PlanSort.values.map((s) {
              final label = switch (s) {
                PlanSort.distance => 'Distance',
                PlanSort.popularity => 'Popularity',
                PlanSort.startingSoon => 'Starting soon',
                PlanSort.newest => 'Newest',
              };
              return ListTile(
                title: Text(label, style: AppTextStyles.bodyMedium),
                trailing: _sort == s
                    ? const Icon(Icons.check, size: 18, color: AppColors.text)
                    : null,
                onTap: () => Navigator.pop(ctx, s),
              );
            }),
          ],
        ),
      ),
    );
    if (choice != null) setState(() => _sort = choice);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final happeningSoon = _happeningSoon;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPlans,
          color: AppColors.accent,
          strokeWidth: 2,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Explore', style: AppTextStyles.largeHeading.copyWith(fontSize: 28)),
                      const SizedBox(height: 16),
                      SwoopSearchBar(
                        controller: _searchController,
                        hintText: 'Search experiences, locations...',
                        onChanged: (v) => setState(() => _query = v.trim()),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: SampleData.categories.length,
                    itemBuilder: (_, i) {
                      final cat = SampleData.categories[i];
                      final selected = cat == 'All' ? _category == null : _category == cat;
                      return CategoryChip(
                        label: cat,
                        selected: selected,
                        onTap: () => setState(() {
                          _category = (cat == 'All' || _category == cat) ? null : cat;
                        }),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GestureDetector(
                    onTap: _showSortSheet,
                    child: Row(
                      children: [
                        Text(
                          _sortLabel,
                          style: AppTextStyles.caption.copyWith(color: AppColors.text),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more, size: 16, color: AppColors.textSecondary),
                        const Spacer(),
                        Text('${filtered.length} plans', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              ),
              if (happeningSoon.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text('Starting soon', style: AppTextStyles.sectionHeading.copyWith(fontSize: 18)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: happeningSoon.length,
                      itemBuilder: (_, i) => HappeningSoonCard(
                        plan: happeningSoon[i],
                        onTap: () => _openPlan(happeningSoon[i]),
                        onJoin: () => _openPlan(happeningSoon[i]),
                      ),
                    ),
                  ),
                ),
              ],
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SwoopEmptyState(
                      headline: 'No matching plans',
                      subheadline: 'Try a different search or filter.',
                      primaryLabel: 'Clear filters',
                      onPrimary: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _category = null;
                        });
                      },
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: PlanCard(
                        title: filtered[i].title,
                        hostName: filtered[i].hostName,
                        location: filtered[i].location,
                        dateTime: PlanFormatters.formatShortDate(filtered[i].datetime),
                        attendeeCount: filtered[i].attendeeCount,
                        maxSize: filtered[i].maxSize,
                        category: filtered[i].category,
                        coverImage: filtered[i].coverImage,
                        distanceKm: filtered[i].distanceKm,
                        showJoinButton: true,
                        onTap: () => _openPlan(filtered[i]),
                        onJoin: () => _openPlan(filtered[i]),
                      ),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }

  String get _sortLabel => switch (_sort) {
        PlanSort.distance => 'Sort: Distance',
        PlanSort.popularity => 'Sort: Popularity',
        PlanSort.startingSoon => 'Sort: Starting soon',
        PlanSort.newest => 'Sort: Newest',
      };
}
