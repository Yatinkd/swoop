import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralised event-lifecycle service for Swoop.
///
/// Rules:
///   • An event is COMPLETED when:  current time > event datetime
///                              OR  event.status == 'completed'
///   • All public screens (Home, Explore) must call [isCompleted] before
///     showing a plan card.
///   • Call [autoMarkIfNeeded] / [autoMarkBatch] to write the status back
///     to Supabase so all devices see the updated state immediately.
class EventStatusService {
  static final _supabase = Supabase.instance.client;

  // ── Core check ────────────────────────────────────────────────────────────

  /// Safely parses a datetime string as Local Time by stripping any UTC suffix.
  /// This fixes the bug where Postgres appends '+00:00' to naive ISO strings,
  /// causing isAfter to fail because it converts to UTC for comparison.
  static DateTime? parseLocalTime(String? dtString) {
    if (dtString == null || dtString.isEmpty) return null;
    String cleaned = dtString;
    if (cleaned.contains('+')) {
      cleaned = cleaned.split('+')[0]; // Strip +00:00
    } else if (cleaned.contains('Z')) {
      cleaned = cleaned.replaceAll('Z', ''); // Strip Z
    } else if (cleaned.contains('-') && cleaned.lastIndexOf('-') > 10) {
      cleaned = cleaned.substring(0, cleaned.lastIndexOf('-')); // Strip -05:00
    }
    return DateTime.tryParse(cleaned);
  }

  /// Returns true if the event has ended (datetime passed OR status field
  /// is already 'completed'). Works entirely from local data — no network call.
  static bool isCompleted(Map<String, dynamic> plan) {
    // Check explicit status field first (fastest path)
    final status = (plan['status'] ?? '').toString();
    if (status == 'completed') return true;

    // Fall back to datetime comparison
    final dt = parseLocalTime(plan['datetime']);
    if (dt == null) return false;
    return DateTime.now().isAfter(dt);
  }

  // ── Auto-mark (write back to Supabase) ───────────────────────────────────

  /// If the event has passed its datetime AND is not yet marked completed,
  /// sets status = 'completed' in Supabase. Fire-and-forget (errors are silent
  /// because the UI client-side check still works even without the DB update).
  static Future<void> autoMarkIfNeeded(Map<String, dynamic> plan) async {
    try {
      final dt = plan['datetime'];
      if (dt == null) return;

      // Already marked — nothing to do
      final status = (plan['status'] ?? '').toString();
      if (status == 'completed') return;

      // Not yet past — nothing to do
      final parsedDt = parseLocalTime(dt);
      if (parsedDt == null || !DateTime.now().isAfter(parsedDt)) return;

      // Event has ended → write to Supabase
      await _supabase
          .from('plans')
          .update({'status': 'completed'})
          .eq('id', plan['id']);
    } catch (_) {
      // Silently ignore — UI filtering via isCompleted() still works offline
    }
  }

  /// Convenience wrapper: auto-mark all plans in a list.
  /// Runs each check independently so one failure doesn't block others.
  static void autoMarkBatch(List<Map<String, dynamic>> plans) {
    for (final plan in plans) {
      autoMarkIfNeeded(plan); // fire-and-forget each one
    }
  }
}
