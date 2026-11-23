import 'package:iztro_dart/iztro_dart.dart';
import 'package:test/test.dart';

final class _StubCalendarAdapter extends BaseLunarCalendarAdapter {
  const _StubCalendarAdapter();

  @override
  ({int year, int month, int day}) lunarToSolar(
    int lunarYear,
    int lunarMonth,
    int lunarDay, {
    bool isLeapMonth = false,
  }) {
    return (year: lunarYear, month: lunarMonth, day: lunarDay);
  }

  @override
  LunarDateInfo solarToLunar(
    int year,
    int month,
    int day, {
    required int timeIndex,
    required DivideType yearDivide,
    required DivideType horoscopeDivide,
  }) {
    return LunarDateInfo(
      lunarYear: year,
      lunarMonth: month,
      lunarDay: day,
      isLeapMonth: false,
      lunarDateChinese: '$year-$month-$day',
      yearStem: HeavenlyStem.jia,
      yearBranch: EarthlyBranch.chen,
      monthStem: HeavenlyStem.bing,
      monthBranch: EarthlyBranch.yin,
      dayStem: HeavenlyStem.jia,
      dayBranch: EarthlyBranch.zi,
      hourStem: HeavenlyStem.jia,
      hourBranch: EarthlyBranch.zi,
    );
  }
}

void main() {
  group('index math', () {
    test('fixIndex wraps negatives and overflows', () {
      expect(fixIndex(0), 0);
      expect(fixIndex(12), 0);
      expect(fixIndex(-1), 11);
      expect(fixIndex(-13), 11);
      expect(fixIndex(25), 1);
      expect(fixIndex(10, 10), 0);
      expect(fixIndex(-1, 10), 9);
    });

    test('earthlyBranch <-> palaceIndex uses 0 = Yin convention', () {
      expect(earthlyBranchToPalaceIndex(EarthlyBranch.yin), 0);
      expect(earthlyBranchToPalaceIndex(EarthlyBranch.mao), 1);
      expect(earthlyBranchToPalaceIndex(EarthlyBranch.zi), 10);
      expect(earthlyBranchToPalaceIndex(EarthlyBranch.chou), 11);

      expect(palaceIndexToEarthlyBranch(0), EarthlyBranch.yin);
      expect(palaceIndexToEarthlyBranch(10), EarthlyBranch.zi);
      expect(palaceIndexToEarthlyBranch(11), EarthlyBranch.chou);
    });

    test('timeToIndex maps 0..23 hours to 0..12', () {
      expect(timeToIndex(0), 0);
      expect(timeToIndex(1), 1);
      expect(timeToIndex(2), 1);
      expect(timeToIndex(3), 2);
      expect(timeToIndex(21), 11);
      expect(timeToIndex(22), 11);
      expect(timeToIndex(23), 12);
    });
  });

  group('validation', () {
    const adapter = DefaultLunarAdapter();

    test('accepts valid solar dates across formats', () {
      final d1 = validateSolarDateStr('2000-8-16');
      expect(d1.year, 2000);
      expect(d1.month, 8);
      expect(d1.day, 16);

      final d2 = validateSolarDateStr('2000/08/16 23:45:12');
      expect(d2.hour, 23);
      expect(d2.minute, 45);
      expect(d2.second, 12);

      expect(validateSolarDateStr('1582-10-04').day, 4);
      expect(validateSolarDateStr('1582-10-15').day, 15);
      expect(validateSolarDateStr('2000-02-29').day, 29);
    });

    test('rejects invalid solar dates and historical gap', () {
      expect(() => validateSolarDateStr('2000-2-30'), throwsArgumentError);
      expect(() => validateSolarDateStr('1900-2-29'), throwsArgumentError);
      expect(() => validateSolarDateStr('1582-10-10'), throwsArgumentError);
      expect(() => validateSolarDateStr('2000-13-01'), throwsArgumentError);
      expect(
        () => validateSolarDateStr('2000-08-16 24:00'),
        throwsArgumentError,
      );
      expect(() => validateSolarDateStr('2000-08/16'), throwsArgumentError);
    });

    test('validates lunar dates including leap months and fallback', () {
      // 2023 has leap 2nd month (29 days).
      final leapOk = validateLunarDateStr(
        '2023-2-15',
        isLeapMonth: true,
        calendar: adapter,
      );
      expect(leapOk.lunarMonthOrThrow(2), 2);

      // 2023 leap 2nd month has 29 days -> day 30 invalid.
      expect(
        () => validateLunarDateStr(
          '2023-2-30',
          isLeapMonth: true,
          calendar: adapter,
        ),
        throwsArgumentError,
      );

      // Passing isLeapMonth=true on a month without leap month falls back to regular month.
      final nonLeapFallback = validateLunarDateStr(
        '2023-1-15',
        isLeapMonth: true,
        calendar: adapter,
      );
      expect(nonLeapFallback.day, 15);
    });

    test('validateTimeIndex enforces 0..12', () {
      validateTimeIndex(0);
      validateTimeIndex(12);
      expect(() => validateTimeIndex(-1), throwsArgumentError);
      expect(() => validateTimeIndex(13), throwsArgumentError);
    });
  });

  group('DefaultLunarAdapter & day boundary', () {
    const adapter = DefaultLunarAdapter();

    test('solar <-> lunar conversion matches iztro/lunar-lite', () {
      final info = adapter.solarToLunar(
        2000,
        8,
        16,
        timeIndex: 2,
        yearDivide: DivideType.normal,
        horoscopeDivide: DivideType.normal,
      );
      expect(info.lunarYear, 2000);
      expect(info.lunarMonth, 7);
      expect(info.lunarDay, 17);
      expect(info.isLeapMonth, isFalse);
      expect(info.lunarDateChinese, '二〇〇〇年七月十七');
      expect(info.yearGanZhi, '庚辰');

      final back = adapter.lunarToSolar(2000, 7, 17);
      expect(back, (year: 2000, month: 8, day: 16));
    });

    test('handles leap month 2023-03-22 and 1900..2100 bounds', () {
      final leapStart = adapter.solarToLunar(
        2023,
        3,
        22,
        timeIndex: 5,
        yearDivide: DivideType.normal,
        horoscopeDivide: DivideType.normal,
      );
      expect(leapStart.lunarYear, 2023);
      expect(leapStart.lunarMonth, 2);
      expect(leapStart.lunarDay, 1);
      expect(leapStart.isLeapMonth, isTrue);

      final solarBack = adapter.lunarToSolar(2023, 2, 1, isLeapMonth: true);
      expect(solarBack, (year: 2023, month: 3, day: 22));

      // 1900-01-31 is Lunar 1900-1-1.
      final y1900 = adapter.solarToLunar(
        1900,
        1,
        31,
        timeIndex: 0,
        yearDivide: DivideType.normal,
        horoscopeDivide: DivideType.normal,
      );
      expect(y1900.lunarYear, 1900);
      expect(y1900.lunarMonth, 1);
      expect(y1900.lunarDay, 1);

      // 2100 roundtrip.
      final s2100 = adapter.lunarToSolar(2100, 6, 15);
      final l2100 = adapter.solarToLunar(
        s2100.year,
        s2100.month,
        s2100.day,
        timeIndex: 6,
        yearDivide: DivideType.normal,
        horoscopeDivide: DivideType.normal,
      );
      expect(l2100.lunarYear, 2100);
      expect(l2100.lunarMonth, 6);
      expect(l2100.lunarDay, 15);
    });

    test('yearDivide normal vs exact at Lichun (2024-02-05)', () {
      // 2024-02-05 is after Lichun (2024-02-04 16:27) and before Lunar New Year (2024-02-10).
      final normalInfo = adapter.solarToLunar(
        2024,
        2,
        5,
        timeIndex: 6,
        yearDivide: DivideType.normal,
        horoscopeDivide: DivideType.normal,
      );
      final exactInfo = adapter.solarToLunar(
        2024,
        2,
        5,
        timeIndex: 6,
        yearDivide: DivideType.exact,
        horoscopeDivide: DivideType.exact,
      );
      expect(normalInfo.yearGanZhi, '癸卯');
      expect(exactInfo.yearGanZhi, '甲辰');
      expect(exactInfo.monthGanZhi, '丙寅');
    });

    test('horoscopeDivide normal adjusts leap month day > 15', () {
      final before15 = adapter.solarToLunar(
        2023,
        4,
        5, // 2023 leap 2nd month day 15
        timeIndex: 4,
        yearDivide: DivideType.normal,
        horoscopeDivide: DivideType.normal,
      );
      final after15 = adapter.solarToLunar(
        2023,
        4,
        6, // 2023 leap 2nd month day 16
        timeIndex: 4,
        yearDivide: DivideType.normal,
        horoscopeDivide: DivideType.normal,
      );
      expect(before15.isLeapMonth, isTrue);
      expect(before15.lunarDay, 15);
      expect(after15.lunarDay, 16);
      expect(before15.monthGanZhi, '乙卯');
      expect(after15.monthGanZhi, '丙辰');
    });

    test('normalizeDayBoundary respects forward vs current and 1582 gap', () {
      final forward = normalizeDayBoundary(
        2024,
        2,
        29,
        12,
        dayDivide: DayDivideType.forward,
        calendar: adapter,
      );
      expect(forward.ymdString, '2024-3-1');
      expect(forward.timeIndex, 0);

      final current = normalizeDayBoundary(
        2024,
        2,
        29,
        12,
        dayDivide: DayDivideType.current,
        calendar: adapter,
      );
      expect(current.ymdString, '2024-2-29');
      expect(current.timeIndex, 0);

      final gap = normalizeDayBoundary(
        1582,
        10,
        4,
        12,
        dayDivide: DayDivideType.forward,
        calendar: adapter,
      );
      expect(gap.ymdString, '1582-10-15');
      expect(gap.timeIndex, 0);
    });

    test('constellationOfSolar covers all 12 boundaries', () {
      expect(constellationOfSolar(3, 21), Constellation.aries);
      expect(constellationOfSolar(4, 20), Constellation.taurus);
      expect(constellationOfSolar(5, 21), Constellation.gemini);
      expect(constellationOfSolar(6, 22), Constellation.cancer);
      expect(constellationOfSolar(7, 23), Constellation.leo);
      expect(constellationOfSolar(8, 23), Constellation.virgo);
      expect(constellationOfSolar(9, 23), Constellation.libra);
      expect(constellationOfSolar(10, 24), Constellation.scorpio);
      expect(constellationOfSolar(11, 23), Constellation.sagittarius);
      expect(constellationOfSolar(12, 22), Constellation.capricorn);
      expect(constellationOfSolar(1, 20), Constellation.aquarius);
      expect(constellationOfSolar(2, 19), Constellation.pisces);
    });

    test('AstroConfigManager preserves resolved snapshot isolation', () {
      AstroConfigManager.resetConfig();
      final snap = AstroConfigManager.resolveConfig(
        const AstroConfig(
          algorithm: Algorithm.zhongzhou,
          ageDivide: AgeDivideType.birthday,
        ),
      );
      AstroConfigManager.config(
        const AstroConfig(
          language: AstroLanguage.enUS,
          algorithm: Algorithm.defaultAlgorithm,
        ),
      );

      expect(snap.algorithm, Algorithm.zhongzhou);
      expect(snap.ageDivide, AgeDivideType.birthday);
      expect(snap.language, AstroLanguage.zhCN);
      expect(AstroConfigManager.getLanguage(), AstroLanguage.enUS);

      AstroConfigManager.resetConfig();
      expect(AstroConfigManager.getLanguage(), AstroLanguage.zhCN);
    });

    test('custom BaseLunarCalendarAdapter advances 1582 gap correctly', () {
      const custom = _StubCalendarAdapter();
      expect(
          custom.nextSolarDay(1582, 10, 4), (year: 1582, month: 10, day: 15));
      expect(custom.getLunarMonthsInYear(2024).length, 12);
    });
  });
}

extension on ParsedDateInput {
  int lunarMonthOrThrow(int expected) {
    expect(month, expected);
    return month;
  }
}
