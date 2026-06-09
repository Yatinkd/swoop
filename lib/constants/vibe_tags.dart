/// Curated vibe tags with emoji for quick scanning.
class VibeTags {
  VibeTags._();

  static const all = [
  VibeTag('🎵 Concert Freak', 'Party'),
  VibeTag('☕ Cafe Hopper', 'Food'),
  VibeTag('🏔 Trekker', 'Adventure'),
  VibeTag('🎮 Gamer', 'Chill'),
  VibeTag('🎬 Movie Buff', 'Chill'),
  VibeTag('🚗 Road Trip Lover', 'Adventure'),
  VibeTag('🌙 Night Owl', 'Party'),
  VibeTag('📚 Bookworm', 'Study'),
  VibeTag('⚡ Rave Energy', 'Party'),
  VibeTag('🏃 Runner', 'Sports'),
  ];

  static const planCategories = [
    'Chill',
    'Party',
    'Study',
    'Adventure',
    'Food',
    'Sports',
  ];

  static String labelForCategory(String? category) {
    if (category == null) return '';
    final match = all.where((v) => v.category == category);
    return match.isNotEmpty ? match.first.label : category;
  }
}

class VibeTag {
  final String label;
  final String category;

  const VibeTag(this.label, this.category);
}
