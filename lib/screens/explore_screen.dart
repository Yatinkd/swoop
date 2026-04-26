import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'plan_details_screen.dart';
import '../main.dart';
import '../services/event_status_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  // Additional Filters
  final Set<int> _favouritePlanIds = {};
  String _hostRatingFilter = 'All ratings';
  String _eventLocationFilter = 'All';
  String _socialEventFilter = 'All';

  final _categories = [
    'All',
    'Chill',
    'Party',
    'Study',
    'Adventure',
    'Food',
    'Sports',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String? dt) {
    if (dt == null) return '';
    final d = EventStatusService.parseLocalTime(dt) ?? DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = d.hour;
    final min = d.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '${d.day} ${months[d.month - 1]}, $h12:$min $amPm';
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterBottomSheet(
          initialRating: _hostRatingFilter,
          initialLocation: _eventLocationFilter,
          initialEvent: _socialEventFilter,
        );
      },
    );

    if (result != null) {
      setState(() {
        _hostRatingFilter = result['rating']!;
        _eventLocationFilter = result['location']!;
        _socialEventFilter = result['event']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Clean Mobile Header ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) =>
                                setState(() => _searchQuery = v.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search plans...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.subtle,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.subtle,
                                      ),
                                    )
                                  : null,
                              filled: false,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _openFilterSheet,
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Compact Category Chips ──────────────────────
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isSelected = cat == 'All'
                      ? _selectedCategory == null
                      : _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(
                      () => _selectedCategory =
                          (_selectedCategory == cat || cat == 'All')
                          ? null
                          : cat,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Feed (Large Vertical Mobile Cards) ──────────
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('plans')
                    .stream(primaryKey: ['id'])
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    );
                  var plans = snapshot.data!;

                  // Core Lifecycle filtering: Only show active, future events.
                  // 1. Hide anything marked completed in the database.
                  // 2. Also hide by datetime as a safety net.
                  final now = DateTime.now();
                  plans = plans.where((p) {
                    // If status field exists and is 'completed', hide it
                    final status = p['status'] as String?;
                    if (status == 'completed') return false;

                    // Also hide events whose time has already passed
                    if (p['datetime'] == null) return true;
                    final dt = EventStatusService.parseLocalTime(p['datetime']);
                    if (dt == null) return true;
                    return dt.isAfter(now);
                  }).toList();

                  // ── Auto-mark completed events in Supabase (background) ──
                  // For any event that was visible but has now passed, write
                  // status='completed' so the stream re-emits and removes it.
                  EventStatusService.autoMarkBatch(
                    snapshot.data!
                        .map((p) => Map<String, dynamic>.from(p))
                        .toList(),
                  );

                  // Apply search
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    plans = plans.where((p) {
                      final t = (p['title'] ?? '').toString().toLowerCase();
                      final l = (p['location'] ?? '').toString().toLowerCase();
                      return t.contains(q) || l.contains(q);
                    }).toList();
                  }

                  // Apply category
                  if (_selectedCategory != null) {
                    plans = plans
                        .where(
                          (p) =>
                              (p['vibe'] ?? '').toString().toLowerCase() ==
                              _selectedCategory!.toLowerCase(),
                        )
                        .toList();
                  }

                  // Apply advanced filters
                  plans = plans.where((p) {
                    if (_eventLocationFilter != 'All') {
                      final l = (p['location'] ?? '').toString().toLowerCase();
                      if (_eventLocationFilter == 'Online' &&
                          !l.contains('online'))
                        return false;
                    }
                    if (_socialEventFilter != 'All') {
                      final v = (p['vibe'] ?? '').toString().toLowerCase();
                      if (v != _socialEventFilter.toLowerCase()) return false;
                    }
                    return true;
                  }).toList();

                  if (plans.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.subtle,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No plans match your filters',
                            style: TextStyle(
                              color: AppColors.subtle,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: plans.length,
                    itemBuilder: (_, i) {
                      final plan = plans[i];
                      final isFav = _favouritePlanIds.contains(plan['id']);
                      return _ExplorePlanCard(
                        plan: plan,
                        formatDate: _formatDate,
                        isFavourite: isFav,
                        onFavouriteToggle: () {
                          setState(() {
                            if (isFav)
                              _favouritePlanIds.remove(plan['id']);
                            else
                              _favouritePlanIds.add(plan['id']);
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorePlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String Function(String?) formatDate;
  final bool isFavourite;
  final VoidCallback onFavouriteToggle;

  const _ExplorePlanCard({
    Key? key,
    required this.plan,
    required this.formatDate,
    required this.isFavourite,
    required this.onFavouriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = plan['title'] ?? 'Untitled';
    final vibe = plan['vibe'] as String?;
    final location = plan['location'] ?? '';
    final coverImage = plan['cover_image'] as String?;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), // soft shadow
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Side: Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 90,
                height: 90,
                color: AppColors.inputFill,
                child: coverImage != null
                    ? Image.network(coverImage, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          title.isNotEmpty ? title[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.subtle,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Right Side: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Favourite toggle
                      GestureDetector(
                        onTap: onFavouriteToggle,
                        child: Icon(
                          isFavourite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavourite
                              ? AppColors.accent
                              : AppColors.subtle,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (plan['datetime'] != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.subtle,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatDate(plan['datetime']),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.subtle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "2/4 going",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (location.isNotEmpty) ...[
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppColors.subtle,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.subtle,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (location.isEmpty) const Spacer(),
                      if (vibe != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            vibe,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String initialRating;
  final String initialLocation;
  final String initialEvent;

  const _FilterBottomSheet({
    Key? key,
    required this.initialRating,
    required this.initialLocation,
    required this.initialEvent,
  }) : super(key: key);

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _rating;
  late String _location;
  late String _event;

  final List<String> _ratings = ['All ratings', '2+', '3+', '4+', '5'];
  final List<String> _locations = ['Online', 'Offline', 'To be announced'];
  final List<String> _events = [
    'All',
    'Chill',
    'Party',
    'Study',
    'Adventure',
    'Food',
    'Sports',
  ];

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _location = widget.initialLocation;
    _event = widget.initialEvent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Indicator and Header
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.subtle.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = 'All ratings';
                          _location = 'All';
                          _event = 'All';
                        });
                      },
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.subtle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 1. Host Rating
                const Text(
                  'Host rating',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _ratings.map((r) {
                    final isSelected = _rating == r;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // 2. Event Location
                const Text(
                  'Event location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _locations.map((loc) {
                    final isSelected = _location == loc;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _location = isSelected ? 'All' : loc),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          loc,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // 3. Select Social Event
                const Text(
                  'Select social event',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _event,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.subtle,
                      ),
                      items: _events.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _event = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Big Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'rating': _rating,
                        'location': _location,
                        'event': _event,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
