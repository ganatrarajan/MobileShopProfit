import 'package:flutter/material.dart';

class DateRangeResult {
  final String? dateFrom;
  final String? dateTo;
  const DateRangeResult(this.dateFrom, this.dateTo);
}

class DateHelper {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Calculates start and end YYYY-MM-DD date strings for any given preset
  static DateRangeResult getDateRangeForPreset(String preset, {DateTimeRange? customRange}) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    switch (preset) {
      case 'today':
        return DateRangeResult(todayStr, todayStr);
      case 'yesterday':
        final y = now.subtract(const Duration(days: 1));
        final yStr = '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
        return DateRangeResult(yStr, yStr);
      case 'this_week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startStr = '${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}';
        return DateRangeResult(startStr, todayStr);
      case 'this_month':
        final startStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
        return DateRangeResult(startStr, todayStr);
      case 'last_month':
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        final startStr = '${lastMonthStart.year}-${lastMonthStart.month.toString().padLeft(2, '0')}-01';
        final endStr = '${lastMonthEnd.year}-${lastMonthEnd.month.toString().padLeft(2, '0')}-${lastMonthEnd.day.toString().padLeft(2, '0')}';
        return DateRangeResult(startStr, endStr);
      case 'this_year':
        final startStr = '${now.year}-01-01';
        return DateRangeResult(startStr, todayStr);
      case 'custom':
        if (customRange != null) {
          final s = customRange.start;
          final e = customRange.end;
          final startStr = '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
          final endStr = '${e.year}-${e.month.toString().padLeft(2, '0')}-${e.day.toString().padLeft(2, '0')}';
          return DateRangeResult(startStr, endStr);
        }
        return const DateRangeResult(null, null);
      case 'all_time':
      default:
        return const DateRangeResult(null, null);
    }
  }

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

    return '$day $month $year, $hourStr:$minuteStr $ampm';
  }

  /// Formats date only: e.g. "12 - Sep - 2026"
  static String formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final dt = parseToLocal(raw);
    if (dt == null) return raw;

    final day = dt.day.toString().padLeft(2, '0');
    final month = _months[dt.month - 1];
    final year = dt.year;

    return '$day $month $year';
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
