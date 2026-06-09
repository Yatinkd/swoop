import '../models/plan.dart';
import '../services/event_status_service.dart';

class PlanFormatters {
  PlanFormatters._();

  static String formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${dt.day} ${months[dt.month - 1]}  ·  $h12:$min $amPm';
  }

  static String formatShortDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    final isToday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    final hour = dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final prefix = isToday ? 'Today' : '${dt.day} ${months[dt.month - 1]}';
    return '$prefix $h12:$min $amPm';
  }

  static String formatCountdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return 'Started';
    if (diff.inDays > 0) return 'Starts in ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) {
      return 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    if (diff.inMinutes > 0) return 'Starts in ${diff.inMinutes}m';
    return 'Starting now';
  }

  static String formatDistance(double? km) {
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(1)} km away';
  }

  static String greeting(String? name) {
    final hour = DateTime.now().hour;
    final first = (name ?? '').split(' ').first;
    final prefix = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    if (first.isEmpty) return prefix;
    return '${prefix[0].toUpperCase()}${prefix.substring(1)}, $first';
  }

  static String subGreeting() {
    return 'Never miss an experience because you don\'t have someone to go with.';
  }

  static DateTime? parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return EventStatusService.parseLocalTime(raw.toString());
  }

  static Plan planFromMap(Map<String, dynamic> map) {
    final copy = Map<String, dynamic>.from(map);
    final parsed = parseDateTime(copy['datetime']);
    if (parsed != null) copy['datetime'] = parsed.toIso8601String();
    return Plan.fromMap(copy);
  }
}
