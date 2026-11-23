import '../core/types.dart';
import '../core/validation.dart';
import 'calendar_adapter.dart';

/// Result of normalizing late Rat hour (`timeIndex == 12`, 23:00–23:59).
class DayBoundaryResult {
  const DayBoundaryResult({
    required this.year,
    required this.month,
    required this.day,
    required this.timeIndex,
  });

  final int year;
  final int month;
  final int day;

  /// Always normalized to `0..11`.
  final int timeIndex;

  String get ymdString => '$year-$month-$day';
}

/// Normalizes late Rat hour (`timeIndex == 12`) before calendar lookup and star
/// placement, matching `iztro/src/utils/date.ts#normalizeDayBoundary`.
///
/// - When `timeIndex != 12`, inputs are returned unchanged.
/// - When `dayDivide == DayDivideType.current`, keeps the date and maps
///   `timeIndex` to `0` (early Rat).
/// - When `dayDivide == DayDivideType.forward`, advances solar date by 1 day via
///   [calendar], validates the resulting date, and maps `timeIndex` to `0`.
DayBoundaryResult normalizeDayBoundary(
  int year,
  int month,
  int day,
  int timeIndex, {
  required DayDivideType dayDivide,
  required LunarCalendarAdapter calendar,
}) {
  if (timeIndex != 12) {
    return DayBoundaryResult(
      year: year,
      month: month,
      day: day,
      timeIndex: timeIndex,
    );
  }

  if (dayDivide == DayDivideType.current) {
    return DayBoundaryResult(
      year: year,
      month: month,
      day: day,
      timeIndex: 0,
    );
  }

  final next = calendar.nextSolarDay(year, month, day);
  validateSolarDateStr('${next.year}-${next.month}-${next.day}');
  return DayBoundaryResult(
    year: next.year,
    month: next.month,
    day: next.day,
    timeIndex: 0,
  );
}
