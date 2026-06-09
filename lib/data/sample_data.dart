import '../models/activity_feed_item.dart';
import '../models/plan.dart';
import '../models/user_profile.dart';

/// Minimal realistic demo content — only when database is empty.
class SampleData {
  SampleData._();

  static List<Plan> get plans {
    final now = DateTime.now();
    return [
      Plan(
        id: 'sample-1',
        title: 'Cafe Hopping',
        description: 'Three cafes in Koramangala. Good coffee, easy conversation.',
        location: 'Koramangala, Bangalore',
        datetime: now.add(const Duration(hours: 2, minutes: 30)),
        hostId: 'sample-host-1',
        hostName: 'Sarah',
        vibe: 'Food',
        category: 'Food',
        maxSize: 8,
        participants: ['u1', 'u2', 'u3', 'u4', 'u5'],
        distanceKm: 1.2,
        coverImage:
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80',
        isSample: true,
      ),
      Plan(
        id: 'sample-2',
        title: 'Badminton Match',
        description: 'Casual doubles at Indiranagar. All levels welcome.',
        location: 'Indiranagar Sports Club',
        datetime: now.add(const Duration(minutes: 45)),
        hostId: 'sample-host-2',
        hostName: 'Priya',
        vibe: 'Sports',
        category: 'Sports',
        maxSize: 4,
        participants: ['u1', 'u2'],
        distanceKm: 0.8,
        coverImage:
            'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800&q=80',
        isSample: true,
      ),
      Plan(
        id: 'sample-3',
        title: 'Coldplay Meetup',
        description: 'Meet before the show. Dinner nearby, then walk to the stadium together.',
        location: 'M Chinnaswamy Stadium',
        datetime: DateTime(2026, 7, 15, 17, 30),
        hostId: 'sample-host-3',
        hostName: 'Arjun',
        vibe: 'Party',
        category: 'Concert',
        maxSize: 12,
        participants: ['cp1', 'cp2', 'cp3', 'cp4', 'cp5', 'cp6'],
        distanceKm: 5.2,
        isConcertMode: true,
        linkedEventName: 'Coldplay Concert',
        meetTime: '5:30 PM',
        eventStartTime: '7:00 PM',
        coverImage:
            'https://images.unsplash.com/photo-1459745454116-04e785f10670?w=800&q=80',
        isSample: true,
      ),
    ];
  }

  static List<ActivityFeedItem> get activityFeed {
    final now = DateTime.now();
    return [
      ActivityFeedItem(
        id: 'act-1',
        userName: 'Sarah',
        type: ActivityType.joined,
        planTitle: 'Cafe Hopping',
        timestamp: now.subtract(const Duration(minutes: 18)),
      ),
      ActivityFeedItem(
        id: 'act-2',
        userName: 'Arjun',
        type: ActivityType.created,
        planTitle: 'Coldplay Meetup',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  static List<UserProfile> get attendees => [
        const UserProfile(
          id: 'att-1',
          name: 'Sarah',
          interests: ['Coffee', 'Music', 'Travel'],
          vibeTags: ['☕ Cafe Hopper', '🎵 Concert Freak'],
          rating: 4.9,
          plansHosted: 12,
          plansJoined: 28,
          vibeMatchPercent: 92,
          isVerified: true,
        ),
        const UserProfile(
          id: 'att-2',
          name: 'Arjun',
          interests: ['Concerts', 'Food'],
          vibeTags: ['🎵 Concert Freak', '🌙 Night Owl'],
          rating: 4.7,
          plansHosted: 6,
          plansJoined: 19,
          vibeMatchPercent: 87,
        ),
      ];

  static List<UserProfile> get recommendedPeople => [
        const UserProfile(
          id: 'rec-1',
          name: 'Maya',
          vibeTags: ['☕ Cafe Hopper', '📚 Bookworm'],
          rating: 4.9,
          vibeMatchPercent: 94,
        ),
        const UserProfile(
          id: 'rec-2',
          name: 'Rohan',
          vibeTags: ['🏔 Trekker', '🏃 Runner'],
          rating: 4.8,
          vibeMatchPercent: 88,
        ),
        const UserProfile(
          id: 'rec-3',
          name: 'Priya',
          vibeTags: ['🎵 Concert Freak', '⚡ Rave Energy'],
          rating: 4.7,
          vibeMatchPercent: 85,
        ),
      ];

  static const quickActions = [
    ('Coffee', 'Food'),
    ('Study', 'Study'),
    ('Sports', 'Sports'),
    ('Concerts', 'Party'),
  ];

  static const categories = [
    'All',
    'Food',
    'Sports',
    'Study',
    'Concert',
    'Chill',
    'Adventure',
  ];
}
