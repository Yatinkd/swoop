enum ActivityType { joined, created, hosted }

class ActivityFeedItem {
  final String id;
  final String userName;
  final String? userImage;
  final ActivityType type;
  final String planTitle;
  final String? planId;
  final DateTime timestamp;

  const ActivityFeedItem({
    required this.id,
    required this.userName,
    this.userImage,
    required this.type,
    required this.planTitle,
    this.planId,
    required this.timestamp,
  });

  String get actionText {
    switch (type) {
      case ActivityType.joined:
        return 'joined';
      case ActivityType.created:
        return 'created';
      case ActivityType.hosted:
        return 'hosted';
    }
  }
}
