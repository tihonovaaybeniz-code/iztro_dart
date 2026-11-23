import '../core/types.dart';
import '../core/validation.dart';

/// Immutable lunar calendar lookup result consumed by `iztro_dart`.
class LunarDateInfo {
  const LunarDateInfo({
    required this.lunarYear,
    required this.lunarMonth,
    required this.lunarDay,
    required this.isLeapMonth,
    required this.lunarDateChinese,
    required this.yearStem,
    required this.yearBranch,
    required this.monthStem,
    required this.monthBranch,
    required this.dayStem,
    required this.dayBranch,
    required this.hourStem,
    required this.hourBranch,
  });

  final int lunarYear;

  /// 1..12.
  final int lunarMonth;

  /// 1..30.
  final int lunarDay;

  final bool isLeapMonth;

  /// Classical Chinese lunar date string, e.g. `二〇〇〇年七月十七`.
  final String lunarDateChinese;

  final HeavenlyStem yearStem;
  final EarthlyBranch yearBranch;
  final HeavenlyStem monthStem;
  final EarthlyBranch monthBranch;
  final HeavenlyStem dayStem;
  final EarthlyBranch dayBranch;
  final HeavenlyStem hourStem;
  final EarthlyBranch hourBranch;

  /// Numeric `YYYY-M-D` lunar date representation.
  String get ymdString => '$lunarYear-$lunarMonth-$lunarDay';

  /// Two-character Simplified Chinese year pillar, e.g. `庚辰`.
  String get yearGanZhi => '${yearStem.zh}${yearBranch.zh}';

  /// Two-character Simplified Chinese month pillar.
  String get monthGanZhi => '${monthStem.zh}${monthBranch.zh}';

  /// Two-character Simplified Chinese day pillar.
  String get dayGanZhi => '${dayStem.zh}${dayBranch.zh}';

  /// Two-character Simplified Chinese hour pillar.
  String get hourGanZhi => '${hourStem.zh}${hourBranch.zh}';
}

/// Metadata for a single lunar month in a lunar year.
class LunarMonthSpec {
  const LunarMonthSpec({
    required this.month,
    required this.isLeapMonth,
    required this.dayCount,
  });

  /// 1..12.
  final int month;
  final bool isLeapMonth;
  final int dayCount;
}

/// Pluggable calendar interface decoupling `iztro_dart` from any fixed
/// calendar engine.
///
/// Built-in charts default to `DefaultLunarAdapter` (backed by pure-Dart
/// `package:lunar`). Host apps can inject their own implementation (e.g.
/// bridging an existing calendar package).
abstract interface class LunarCalendarAdapter {
  /// Converts a solar date + timeIndex (`0..12`) to [LunarDateInfo] and
  /// four-pillar GanZhi according to [yearDivide] and [horoscopeDivide].
  LunarDateInfo solarToLunar(
    int year,
    int month,
    int day, {
    required int timeIndex,
    required DivideType yearDivide,
    required DivideType horoscopeDivide,
  });

  /// Converts a lunar date (`lunarYear`, `lunarMonth`, `lunarDay`, optional
  /// [isLeapMonth]) back to a solar `(year, month, day)` record.
  ///
  /// Aligned with `iztro` / `lunar-lite`: if [isLeapMonth] is `true` for a
  /// month that is not a leap month in [lunarYear], it resolves the non-leap
  /// month of the same number.
  ({int year, int month, int day}) lunarToSolar(
    int lunarYear,
    int lunarMonth,
    int lunarDay, {
    bool isLeapMonth = false,
  });

  /// Returns the next valid solar calendar date after `(year, month, day)`,
  /// respecting the Julian -> Gregorian 1582-10-04 -> 1582-10-15 transition.
  ({int year, int month, int day}) nextSolarDay(int year, int month, int day);

  /// Lists all lunar months in [lunarYear] in chronological order (including any
  /// leap month).
  List<LunarMonthSpec> getLunarMonthsInYear(int lunarYear);
}

/// Convenience base class for custom [LunarCalendarAdapter] implementations.
///
/// Subclasses only need to implement [solarToLunar] and [lunarToSolar], and
/// may optionally override [leapMonthOfYear] / [daysInLunarMonth] or
/// [getLunarMonthsInYear] for exact leap-month validation and `monthlyList()`.
abstract base class BaseLunarCalendarAdapter implements LunarCalendarAdapter {
  const BaseLunarCalendarAdapter();

  /// Returns the leap month number (`1..12`) in [lunarYear], or `0` if none.
  int leapMonthOfYear(int lunarYear) => 0;

  /// Returns the day count (`29` or `30`) of a lunar month in [lunarYear].
  int daysInLunarMonth(
    int lunarYear,
    int lunarMonth, {
    bool isLeapMonth = false,
  }) =>
      30;

  @override
  ({int year, int month, int day}) nextSolarDay(int year, int month, int day) {
    if (year == 1582 && month == 10 && day == 4) {
      return (year: 1582, month: 10, day: 15);
    }
    final leap = isJulianGregorianLeapYear(year);
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
    ][month - 1];
    if (day < daysInMonth) {
      return (year: year, month: month, day: day + 1);
    }
    if (month < 12) {
      return (year: year, month: month + 1, day: 1);
    }
    return (year: year + 1, month: 1, day: 1);
  }

  @override
  List<LunarMonthSpec> getLunarMonthsInYear(int lunarYear) {
    final leap = leapMonthOfYear(lunarYear);
    final result = <LunarMonthSpec>[];
    for (var m = 1; m <= 12; m++) {
      result.add(
        LunarMonthSpec(
          month: m,
          isLeapMonth: false,
          dayCount: daysInLunarMonth(lunarYear, m),
        ),
      );
      if (leap == m) {
        result.add(
          LunarMonthSpec(
            month: m,
            isLeapMonth: true,
            dayCount: daysInLunarMonth(lunarYear, m, isLeapMonth: true),
          ),
        );
      }
    }
    return result;
  }
}

/// Computes the Western [Constellation] from a solar `(month, day)` pair,
/// matching `lunar-typescript` / `lunar-lite`'s `Solar.getXingZuo()`.
Constellation constellationOfSolar(int month, int day) {
  final md = month * 100 + day;
  if (md >= 321 && md <= 419) {
    return Constellation.aries;
  }
  if (md >= 420 && md <= 520) {
    return Constellation.taurus;
  }
  if (md >= 521 && md <= 621) {
    return Constellation.gemini;
  }
  if (md >= 622 && md <= 722) {
    return Constellation.cancer;
  }
  if (md >= 723 && md <= 822) {
    return Constellation.leo;
  }
  if (md >= 823 && md <= 922) {
    return Constellation.virgo;
  }
  if (md >= 923 && md <= 1023) {
    return Constellation.libra;
  }
  if (md >= 1024 && md <= 1122) {
    return Constellation.scorpio;
  }
  if (md >= 1123 && md <= 1221) {
    return Constellation.sagittarius;
  }
  if (md >= 1222 || md <= 119) {
    return Constellation.capricorn;
  }
  if (md <= 218) {
    return Constellation.aquarius;
  }
  return Constellation.pisces;
}
