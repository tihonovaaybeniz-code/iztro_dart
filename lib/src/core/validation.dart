import '../calendar/calendar_adapter.dart';

/// Parsed date (and optional wall-clock time) components.
class ParsedDateInput {
  const ParsedDateInput({
    required this.year,
    required this.month,
    required this.day,
    this.hour,
    this.minute,
    this.second,
  });

  final int year;
  final int month;
  final int day;
  final int? hour;
  final int? minute;
  final int? second;

  /// Canonical `YYYY-M-D` representation used by `iztro`.
  String get ymdString => '$year-$month-$day';
}

final RegExp _dateStrPattern = RegExp(
  r'^(\d{1,4})([-/.])(\d{1,2})\2(\d{1,2})(?: (\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?$',
);

/// Leap year rule aligned with `lunar-typescript`'s `SolarUtil.isLeapYear`.
bool isJulianGregorianLeapYear(int year) {
  if (year < 1600) {
    return year % 4 == 0;
  }
  return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

/// Parses and validates a solar date string (`YYYY-M-D`, `YYYY/M/D`, `YYYY.M.D`,
/// with optional ` HH:mm[:ss]` suffix), matching `iztro/src/utils/validation.ts`.
ParsedDateInput validateSolarDateStr(String dateStr) {
  final parsed = _parseDateSyntax(dateStr);
  if (parsed.year < 1 ||
      parsed.year > 9999 ||
      parsed.month < 1 ||
      parsed.month > 12 ||
      parsed.day < 1) {
    throw ArgumentError.value(dateStr, 'dateStr', 'invalid date.');
  }

  // Historical Julian -> Gregorian calendar gap (Oct 5..14, 1582).
  if (parsed.year == 1582 &&
      parsed.month == 10 &&
      parsed.day >= 5 &&
      parsed.day <= 14) {
    throw ArgumentError.value(dateStr, 'dateStr', 'invalid solar date.');
  }

  final leap = isJulianGregorianLeapYear(parsed.year);
  final daysInMonth = <int>[
    31,
    leap ? 29 : 28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ];
  if (parsed.day > daysInMonth[parsed.month - 1]) {
    throw ArgumentError.value(dateStr, 'dateStr', 'invalid solar date.');
  }
  return parsed;
}

/// Validates a lunar date string (`YYYY-M-D` etc.) against [calendar].
///
/// Aligned with `iztro@2.6.5`: if [isLeapMonth] is `true` for a month that does
/// not actually have a leap month in that lunar year, validation silently checks
/// the regular (non-leap) month rather than throwing.
ParsedDateInput validateLunarDateStr(
  String dateStr, {
  required bool isLeapMonth,
  required LunarCalendarAdapter calendar,
}) {
  final parsed = _parseDateSyntax(dateStr);
  if (parsed.year < 1 ||
      parsed.year > 9999 ||
      parsed.month < 1 ||
      parsed.month > 12 ||
      parsed.day < 1) {
    throw ArgumentError.value(dateStr, 'dateStr', 'invalid date.');
  }

  final months = calendar.getLunarMonthsInYear(parsed.year);
  LunarMonthSpec? targetMonth;
  if (isLeapMonth) {
    for (final m in months) {
      if (m.month == parsed.month && m.isLeapMonth) {
        targetMonth = m;
        break;
      }
    }
  }
  if (targetMonth == null) {
    for (final m in months) {
      if (m.month == parsed.month && !m.isLeapMonth) {
        targetMonth = m;
        break;
      }
    }
  }

  if (targetMonth == null || parsed.day > targetMonth.dayCount) {
    throw ArgumentError.value(dateStr, 'dateStr', 'invalid lunar date.');
  }
  return parsed;
}

/// Validates that [timeIndex] is within `0..12`.
void validateTimeIndex(int timeIndex) {
  if (timeIndex < 0 || timeIndex > 12) {
    throw ArgumentError.value(
      timeIndex,
      'timeIndex',
      'invalid timeIndex: expected an integer from 0 to 12.',
    );
  }
}

ParsedDateInput _parseDateSyntax(String dateStr) {
  final match = _dateStrPattern.firstMatch(dateStr);
  if (match == null) {
    throw ArgumentError.value(dateStr, 'dateStr', 'invalid date.');
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(3)!);
  final day = int.parse(match.group(4)!);
  final hourStr = match.group(5);
  final minuteStr = match.group(6);
  final secondStr = match.group(7);

  int? hour;
  int? minute;
  int? second;
  if (hourStr != null && minuteStr != null) {
    hour = int.parse(hourStr);
    minute = int.parse(minuteStr);
    second = secondStr != null ? int.parse(secondStr) : 0;
    if (hour > 23 || minute > 59 || second > 59) {
      throw ArgumentError.value(dateStr, 'dateStr', 'invalid time.');
    }
  }

  return ParsedDateInput(
    year: year,
    month: month,
    day: day,
    hour: hour,
    minute: minute,
    second: second,
  );
}
