import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sample_data.dart';
import '../models/activity_feed_item.dart';
import '../models/plan.dart';
import '../utils/plan_formatters.dart';
import '../services/event_status_service.dart';

enum PlanSort { distance, popularity, startingSoon, newest }

class PlanRepository {
  PlanRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Plan>> fetchPlans() async {
    try {
      final raw = await _client
          .from('plans')
          .select()
          .order('datetime', ascending: true);
      final plans = (raw as List)
          .map((p) => PlanFormatters.planFromMap(Map<String, dynamic>.from(p)))
          .where((p) => !p.isPast)
          .toList();
      return _mergeWithSamples(plans);
    } catch (_) {
      return SampleData.plans;
    }
  }

  Future<List<Plan>> fetchMyPlans(String userId) async {
    try {
      final raw = await _client.from('plans').select().order('datetime', ascending: false);
      final mine = <Plan>[];
      for (final p in (raw as List)) {
        final map = Map<String, dynamic>.from(p);
        final isHost = map['host_id'] == userId;
        final parts = List<String>.from(map['participants'] ?? []);
        if (isHost || parts.contains(userId)) {
          mine.add(PlanFormatters.planFromMap(map));
        }
      }
      return mine;
    } catch (_) {
      return [];
    }
  }

  List<Plan> happeningSoon(List<Plan> plans) {
    return plans.where((p) => p.isStartingSoon && !p.isFull).toList()
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
  }

  List<Plan> trending(List<Plan> plans) {
    final sorted = List<Plan>.from(plans)
      ..sort((a, b) {
        final scoreA = a.attendeeCount + (a.isBoosted ? 5 : 0);
        final scoreB = b.attendeeCount + (b.isBoosted ? 5 : 0);
        return scoreB.compareTo(scoreA);
      });
    return sorted.take(6).toList();
  }

  List<Plan> searchPlans(List<Plan> plans, String query) {
    if (query.isEmpty) return plans;
    final q = query.toLowerCase();
    return plans.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q) ||
          p.vibe.toLowerCase().contains(q) ||
          (p.linkedEventName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<Plan> filterByCategory(List<Plan> plans, String? category) {
    if (category == null || category == 'All') return plans;
    return plans
        .where((p) =>
            p.category.toLowerCase() == category.toLowerCase() ||
            p.vibe.toLowerCase() == category.toLowerCase())
        .toList();
  }

  List<Plan> sortPlans(List<Plan> plans, PlanSort sort) {
    final copy = List<Plan>.from(plans);
    switch (sort) {
      case PlanSort.distance:
        copy.sort((a, b) =>
            (a.distanceKm ?? 99).compareTo(b.distanceKm ?? 99));
      case PlanSort.popularity:
        copy.sort((a, b) => b.attendeeCount.compareTo(a.attendeeCount));
      case PlanSort.startingSoon:
        copy.sort((a, b) => a.datetime.compareTo(b.datetime));
      case PlanSort.newest:
        copy.sort((a, b) =>
            (b.createdAt ?? b.datetime).compareTo(a.createdAt ?? a.datetime));
    }
    return copy;
  }

  List<Plan> socialEventResults(String query) {
    final q = query.toLowerCase();
    return SampleData.plans
        .where((p) =>
            p.isConcertMode ||
            (p.linkedEventName?.toLowerCase().contains(q) ?? false) ||
            p.title.toLowerCase().contains(q))
        .toList();
  }

  List<ActivityFeedItem> activityFeed() => SampleData.activityFeed;

  void autoMarkCompleted(List<Map<String, dynamic>> rawPlans) {
    EventStatusService.autoMarkBatch(rawPlans);
  }

  List<Plan> _mergeWithSamples(List<Plan> real) {
    if (real.isNotEmpty) return real;
    return SampleData.plans;
  }
}
