class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? location;
  final String? bio;
  final String? profileImage;
  final List<String> interests;
  final List<String> vibeTags;
  final double rating;
  final int plansHosted;
  final int plansJoined;
  final int friendsCount;
  final bool isVerified;
  final int streakWeeks;
  final String level;
  final int vibeMatchPercent;
  final List<String> badges;
  final List<String> mutualFriends;

  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.location,
    this.bio,
    this.profileImage,
    this.interests = const [],
    this.vibeTags = const [],
    this.rating = 4.8,
    this.plansHosted = 0,
    this.plansJoined = 0,
    this.friendsCount = 0,
    this.isVerified = false,
    this.streakWeeks = 0,
    this.level = 'Explorer',
    this.vibeMatchPercent = 0,
    this.badges = const [],
    this.mutualFriends = const [],
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'User',
      email: map['email']?.toString(),
      location: map['location']?.toString(),
      bio: map['bio']?.toString(),
      profileImage: map['profile_image']?.toString(),
      interests: List<String>.from(map['interests'] ?? []),
      vibeTags: List<String>.from(map['vibe_tags'] ?? []),
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      plansHosted: (map['plans_hosted'] as num?)?.toInt() ?? 0,
      plansJoined: (map['plans_joined'] as num?)?.toInt() ?? 0,
      friendsCount: (map['friends_count'] as num?)?.toInt() ?? 0,
      isVerified: map['is_verified'] == true,
      streakWeeks: (map['streak_weeks'] as num?)?.toInt() ?? 0,
      level: map['level']?.toString() ?? 'Explorer',
      vibeMatchPercent: (map['vibe_match_percent'] as num?)?.toInt() ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      mutualFriends: List<String>.from(map['mutual_friends'] ?? []),
    );
  }
}
