class DateHelper {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Parses raw timestamp/date string into local DateTime (Asia/Kolkata IST)
  static DateTime? parseToLocal(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final trimmed = raw.trim();
      final dt = DateTime.parse(trimmed);
      return dt.isUtc ? dt.toLocal() : dt;
    } catch (_) {
      return null;
    }
  }

  /// Formats date & time: e.g. "12 - Sep - 2026, 05:16 PM"
  static String formatDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final dt = parseToLocal(raw);
    if (dt == null) return raw;

    final day = dt.day.toString().padLeft(2, '0');
    final month = _months[dt.month - 1];
    final year = dt.year;

    int hour = dt.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = dt.minute.toString().padLeft(2, '0');

    return '$day - $month - $year, $hourStr:$minuteStr $ampm';
  }

  /// Formats date only: e.g. "12 - Sep - 2026"
  static String formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final dt = parseToLocal(raw);
    if (dt == null) return raw;

    final day = dt.day.toString().padLeft(2, '0');
    final month = _months[dt.month - 1];
    final year = dt.year;

    return '$day - $month - $year';
  }

  /// Formats time only: e.g. "05:16 PM"
  static String formatTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final dt = parseToLocal(raw);
    if (dt == null) return raw;

    int hour = dt.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = dt.minute.toString().padLeft(2, '0');

    return '$hourStr:$minuteStr $ampm';
  }

  /// Smart format: Formats as "dd - Month - yyyy, hh:mm AM/PM" if time is present, else "dd - Month - yyyy"
  static String formatSmart(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final dt = parseToLocal(raw);
    if (dt == null) return raw;

    final hasTime = raw.contains('T') || raw.contains(':') || (dt.hour != 0 || dt.minute != 0);
    return hasTime ? formatDateTime(raw) : formatDate(raw);
  }
}
