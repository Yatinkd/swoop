class Plan {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime datetime;
  final String hostId;
  final String hostName;
  final String? hostImage;
  final String vibe;
  final String category;
  final int maxSize;
  final List<String> participants;
  final bool isBoosted;
  final bool isSponsored;
  final bool isPrivate;
  final bool isConcertMode;
  final String? coverImage;
  final String? linkedEventName;
  final String? meetTime;
  final String? eventStartTime;
  final String? eventEndTime;
  final double? distanceKm;
  final String status;
  final DateTime? createdAt;
  final bool isSample;

  const Plan({
    required this.id,
    required this.title,
    this.description = '',
    required this.location,
    required this.datetime,
    required this.hostId,
    required this.hostName,
    this.hostImage,
    this.vibe = 'Chill',
    this.category = 'Chill',
    this.maxSize = 10,
    this.participants = const [],
    this.isBoosted = false,
    this.isSponsored = false,
    this.isPrivate = true,
    this.isConcertMode = false,
    this.coverImage,
    this.linkedEventName,
    this.meetTime,
    this.eventStartTime,
    this.eventEndTime,
    this.distanceKm,
    this.status = 'active',
    this.createdAt,
    this.isSample = false,
  });

  int get attendeeCount => participants.length;
  int get spotsLeft => (maxSize - participants.length).clamp(0, maxSize);
  bool get isFull => participants.length >= maxSize;

  Duration get timeUntilStart => datetime.difference(DateTime.now());

  bool get isStartingSoon =>
      !isPast && timeUntilStart.inMinutes <= 60 && timeUntilStart.inMinutes > 0;

  bool get isPast {
    if (status == 'completed') return true;
    return datetime.isBefore(DateTime.now());
  }

  factory Plan.fromMap(Map<String, dynamic> map) {
    final dtRaw = map['datetime'];
    DateTime dt;
    if (dtRaw is DateTime) {
      dt = dtRaw;
    } else if (dtRaw != null) {
      dt = DateTime.parse(dtRaw.toString());
    } else {
      dt = DateTime.now();
    }

    return Plan(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled',
      description: map['description']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      datetime: dt,
      hostId: map['host_id']?.toString() ?? '',
      hostName: map['host_name']?.toString() ?? 'Host',
      hostImage: map['host_image']?.toString(),
      vibe: map['vibe']?.toString() ?? 'Chill',
      category: map['category']?.toString() ?? map['vibe']?.toString() ?? 'Chill',
      maxSize: (map['max_size'] as num?)?.toInt() ?? 10,
      participants: List<String>.from(map['participants'] ?? []),
      isBoosted: map['is_boosted'] == true,
      isSponsored: map['is_sponsored'] == true,
      isPrivate: map['is_private'] != false,
      isConcertMode: map['is_concert_mode'] == true,
      coverImage: map['cover_image']?.toString(),
      linkedEventName: map['linked_event_name']?.toString(),
      meetTime: map['meet_time']?.toString(),
      eventStartTime: map['event_start_time']?.toString(),
      eventEndTime: map['event_end_time']?.toString(),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      status: map['status']?.toString() ?? 'active',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      isSample: map['is_sample'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'datetime': datetime.toIso8601String(),
        'host_id': hostId,
        'host_name': hostName,
        'host_image': hostImage,
        'vibe': vibe,
        'category': category,
        'max_size': maxSize,
        'participants': participants,
        'is_boosted': isBoosted,
        'is_sponsored': isSponsored,
        'is_private': isPrivate,
        'is_concert_mode': isConcertMode,
        'cover_image': coverImage,
        'linked_event_name': linkedEventName,
        'meet_time': meetTime,
        'event_start_time': eventStartTime,
        'event_end_time': eventEndTime,
        'distance_km': distanceKm,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
      };
}
