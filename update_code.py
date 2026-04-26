import os

filepath = "/Users/yatinkd/community app/community_app/lib/screens/explore_screen.dart"

with open(filepath, "r") as f:
    content = f.read()

# Replace variables
content = content.replace("""  // Additional Filters
  final Set<int> _favouritePlanIds = {};
  bool _showOnlyFavourites = false;
  bool _showOnlyWithImage = false;
  String _timeFilter = 'Any time';
  double _maxDistanceKm = 30.0;""", """  // Additional Filters
  final Set<int> _favouritePlanIds = {};
  String _hostRatingFilter = 'All ratings';
  String _eventLocationFilter = 'All';
  String _socialEventFilter = 'All';""")

# Replace functions
start_idx = content.find("  bool _matchesTimeFilter")
end_idx = content.find("  Future<void> _openFilterSheet")

if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + content[end_idx:]

# Replace _openFilterSheet
sheet_start = content.find("  Future<void> _openFilterSheet() async {")
sheet_end = content.find("  @override\n  Widget build(BuildContext context) {")
if sheet_start != -1 and sheet_end != -1:
    new_sheet = """  Future<void> _openFilterSheet() async {
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

"""
    content = content[:sheet_start] + new_sheet + content[sheet_end:]

# Replace filtering logic
filter_start = content.find("                  // Apply advanced filters\n                  plans = plans.where((p) {")
filter_end = content.find("                  }).toList();", filter_start) + len("                  }).toList();")

if filter_start != -1 and filter_end != -1:
    new_filters = """                  // Apply advanced filters
                  plans = plans.where((p) {
                    if (_eventLocationFilter != 'All') {
                      final l = (p['location'] ?? '').toString().toLowerCase();
                      if (_eventLocationFilter == 'Online' && !l.contains('online')) return false;
                    }
                    if (_socialEventFilter != 'All') {
                      final v = (p['vibe'] ?? '').toString().toLowerCase();
                      if (v != _socialEventFilter.toLowerCase()) return false;
                    }
                    return true;
                  }).toList();"""
    content = content[:filter_start] + new_filters + content[filter_end:]

# Replace _ExplorePlanCard
card_start = content.find("class _ExplorePlanCard extends StatelessWidget {")
if card_start != -1:
    content = content[:card_start] + """class _ExplorePlanCard extends StatelessWidget {
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan))),
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
            )
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
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.subtle),
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
                          isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavourite ? AppColors.accent : AppColors.subtle,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (plan['datetime'] != null)
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.subtle),
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
                        const Text("2/4 going", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (location.isNotEmpty) ...[
                        const Icon(Icons.location_on_rounded, size: 14, color: AppColors.subtle),
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
                      if (location.isEmpty)
                        const Spacer(),
                      if (vibe != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      ]
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
  final List<String> _events = ['All', 'Chill', 'Party', 'Study', 'Adventure', 'Food', 'Sports'];

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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.subtle),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 1. Host Rating
                const Text('Host rating', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _ratings.map((r) {
                    final isSelected = _rating == r;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // 2. Event Location
                const Text('Event location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _locations.map((loc) {
                    final isSelected = _location == loc;
                    return GestureDetector(
                      onTap: () => setState(() => _location = isSelected ? 'All' : loc),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                        ),
                        child: Text(
                          loc,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // 3. Select Social Event
                const Text('Select social event', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _event,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.subtle),
                      items: _events.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
"""

with open(filepath, "w") as f:
    f.write(content)

print("done")
