import 'dart:math' as math;

import 'package:lunar/lunar.dart';

import '../core/index_math.dart';
import '../core/types.dart';
import 'calendar_adapter.dart';

/// Default pure-Dart [LunarCalendarAdapter] powered by `package:lunar`,
/// mirroring `lunar-lite@0.2.8` and `lunar-typescript@1.8.6` used by `iztro@2.6.5`.
final class DefaultLunarAdapter implements LunarCalendarAdapter {
  const DefaultLunarAdapter();

  @override
  LunarDateInfo solarToLunar(
    int year,
    int month,
    int day, {
    required int timeIndex,
    required DivideType yearDivide,
    required DivideType horoscopeDivide,
  }) {
    final hour = math.max(timeIndex * 2 - 1, 0);
    final solar = Solar.fromYmdHms(year, month, day, hour, 30, 0);
    final lunar = solar.getLunar();

    final rawMonth = lunar.getMonth();
    final absMonth = rawMonth.abs();
    final isLeap = rawMonth < 0;
    final lunarDay = lunar.getDay();

    final yearStemStr = yearDivide == DivideType.normal
        ? lunar.getYearGan()
        : lunar.getYearGanByLiChun();
    final yearBranchStr = yearDivide == DivideType.normal
        ? lunar.getYearZhi()
        : lunar.getYearZhiByLiChun();
    final yearStem = HeavenlyStem.tryParse(yearStemStr)!;
    final yearBranch = EarthlyBranch.tryParse(yearBranchStr)!;

    late final HeavenlyStem monthStem;
    late final EarthlyBranch monthBranch;
    if (horoscopeDivide == DivideType.exact) {
      monthStem = HeavenlyStem.tryParse(lunar.getMonthGanExact())!;
      monthBranch = EarthlyBranch.tryParse(lunar.getMonthZhiExact())!;
    } else {
      final leapOffset = isLeap && lunarDay > 15 ? 1 : 0;
      final tigerStartStemIndex = fixIndex((yearStem.index % 5) * 2 + 2, 10);
      monthStem = HeavenlyStem.values[
          fixIndex(tigerStartStemIndex + absMonth - 1 + leapOffset, 10)];
      monthBranch =
          EarthlyBranch.values[fixIndex(2 + absMonth - 1 + leapOffset, 12)];
    }

    final dayStem = HeavenlyStem.tryParse(lunar.getDayGanExact())!;
    final dayBranch = EarthlyBranch.tryParse(lunar.getDayZhiExact())!;
    final hourStem = HeavenlyStem.tryParse(lunar.getTimeGan())!;
    final hourBranch = EarthlyBranch.tryParse(lunar.getTimeZhi())!;

    return LunarDateInfo(
      lunarYear: lunar.getYear(),
      lunarMonth: absMonth,
      lunarDay: lunarDay,
      isLeapMonth: isLeap,
      lunarDateChinese: lunar.toString(),
      yearStem: yearStem,
      yearBranch: yearBranch,
      monthStem: monthStem,
      monthBranch: monthBranch,
      dayStem: dayStem,
      dayBranch: dayBranch,
      hourStem: hourStem,
      hourBranch: hourBranch,
    );
  }

  @override
  ({int year, int month, int day}) lunarToSolar(
    int lunarYear,
    int lunarMonth,
    int lunarDay, {
    bool isLeapMonth = false,
  }) {
    final leapMonth =
        isLeapMonth ? LunarYear.fromYear(lunarYear).getLeapMonth() : 0;
    final selectedMonth =
        leapMonth > 0 && leapMonth == lunarMonth ? -lunarMonth : lunarMonth;
    final solar = Lunar.fromYmd(lunarYear, selectedMonth, lunarDay).getSolar();
    return (
      year: solar.getYear(),
      month: solar.getMonth(),
      day: solar.getDay(),
    );
  }

  @override
  ({int year, int month, int day}) nextSolarDay(int year, int month, int day) {
    final next = Solar.fromYmd(year, month, day).next(1);
    return (
      year: next.getYear(),
      month: next.getMonth(),
      day: next.getDay(),
    );
  }

  @override
  List<LunarMonthSpec> getLunarMonthsInYear(int lunarYear) {
    final months = LunarYear.fromYear(lunarYear).getMonthsInYear();
    return months
        .map(
          (m) => LunarMonthSpec(
            month: m.getMonth().abs(),
            isLeapMonth: m.isLeap(),
            dayCount: m.getDayCount(),
          ),
        )
        .toList(growable: false);
  }
}
