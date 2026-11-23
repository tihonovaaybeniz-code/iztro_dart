import '../calendar/calendar_adapter.dart';
import '../calendar/day_boundary.dart';
import '../calendar/default_lunar_adapter.dart';
import '../calendar/true_solar_time.dart';
import '../core/config.dart';
import '../core/index_math.dart';
import '../core/types.dart';
import '../core/validation.dart';
import '../data/branches_table.dart';
import '../data/locales/locale_registry.dart';
import '../star/adjective_star.dart';
import '../star/major_star.dart';
import '../star/minor_star.dart';
import '../star/yearly12_star.dart';
import 'functional_astrolabe.dart';
import 'functional_palace.dart';
import 'palace_calc.dart';
import 'rearrange.dart';

/// Input date kind for [AstroOptions].
enum AstroDateType {
  solar,
  lunar,
}

/// Unified options object for [Astro.withOptions].
class AstroOptions {
  const AstroOptions({
    this.type = AstroDateType.solar,
    required this.dateStr,
    required this.timeIndex,
    required this.gender,
    this.isLeapMonth = false,
    this.fixLeap = true,
    this.language,
    this.config,
    this.astroType = AstroType.heaven,
    this.calendar,
  });

  final AstroDateType type;
  final String dateStr;
  final int timeIndex;
  final Gender gender;
  final bool isLeapMonth;
  final bool fixLeap;
  final AstroLanguage? language;
  final AstroConfig? config;
  final AstroType astroType;
  final LunarCalendarAdapter? calendar;
}

/// Combined result returned by [Astro.byTrueSolarTime].
class TrueSolarTimeAstrolabe {
  const TrueSolarTimeAstrolabe({
    required this.astrolabe,
    required this.trueSolarTime,
  });

  final FunctionalAstrolabe astrolabe;
  final TrueSolarTimeResult trueSolarTime;
}

/// Main Ziwei Doushu calculation entrypoints, aligned with `iztro@2.6.5`.
abstract final class Astro {
  static const DefaultLunarAdapter _defaultCalendar = DefaultLunarAdapter();

  /// Sets global default configuration for subsequent charts without mutating
  /// already generated astrolabes.
  static void config(AstroConfig options) => AstroConfigManager.config(options);

  /// Returns an immutable snapshot of the current global configuration.
  static ResolvedAstroConfig getConfig() => AstroConfigManager.getConfig();

  /// Resets global configuration and language to factory defaults.
  static void resetConfig() => AstroConfigManager.resetConfig();

  /// Sets the global default output language.
  static void setLanguage(AstroLanguage language) =>
      AstroConfigManager.setLanguage(language);

  /// Returns the current global default output language.
  static AstroLanguage getLanguage() => AstroConfigManager.getLanguage();

  /// Generates a chart from a solar date string (`YYYY-M-D`), time index
  /// (`0..12`), and [gender].
  static FunctionalAstrolabe bySolar(
    String solarDateStr,
    int timeIndex,
    Gender gender, {
    bool fixLeap = true,
    AstroLanguage? language,
    AstroConfig? config,
    LunarCalendarAdapter? calendar,
  }) {
    final parsed = validateSolarDateStr(solarDateStr);
    validateTimeIndex(timeIndex);

    final resolvedConfig =
        AstroConfigManager.resolveConfig(config, language: language);
    final activeCalendar = calendar ?? _defaultCalendar;

    return _buildSolarAstrolabe(
      solarDateStr: solarDateStr,
      year: parsed.year,
      month: parsed.month,
      day: parsed.day,
      timeIndex: timeIndex,
      gender: gender,
      fixLeap: fixLeap,
      config: resolvedConfig,
      calendar: activeCalendar,
      astroType: AstroType.heaven,
    );
  }

  /// Generates a chart from a lunar date string (`YYYY-M-D`), time index
  /// (`0..12`), and [gender].
  static FunctionalAstrolabe byLunar(
    String lunarDateStr,
    int timeIndex,
    Gender gender, {
    bool isLeapMonth = false,
    bool fixLeap = true,
    AstroLanguage? language,
    AstroConfig? config,
    LunarCalendarAdapter? calendar,
  }) {
    final activeCalendar = calendar ?? _defaultCalendar;
    final parsed = validateLunarDateStr(
      lunarDateStr,
      isLeapMonth: isLeapMonth,
      calendar: activeCalendar,
    );
    validateTimeIndex(timeIndex);

    final solar = activeCalendar.lunarToSolar(
      parsed.year,
      parsed.month,
      parsed.day,
      isLeapMonth: isLeapMonth,
    );
    final solarDateStr = '${solar.year}-${solar.month}-${solar.day}';
    return bySolar(
      solarDateStr,
      timeIndex,
      gender,
      fixLeap: fixLeap,
      language: language,
      config: config,
      calendar: activeCalendar,
    );
  }

  /// Calculates True Solar Time from [civilTime], [longitude], and
  /// [utcOffsetMinutes], then builds the corresponding chart.
  static TrueSolarTimeAstrolabe byTrueSolarTime(
    DateTime civilTime, {
    required double longitude,
    required int utcOffsetMinutes,
    required Gender gender,
    bool applyChinaDstHistory = true,
    bool fixLeap = true,
    AstroLanguage? language,
    AstroConfig? config,
    LunarCalendarAdapter? calendar,
    AstroType astroType = AstroType.heaven,
    double boundaryWarningMinutes = 15.0,
  }) {
    final tst = TrueSolarTimeCalculator.calculate(
      civilTime,
      longitude: longitude,
      utcOffsetMinutes: utcOffsetMinutes,
      applyChinaDstHistory: applyChinaDstHistory,
      boundaryWarningMinutes: boundaryWarningMinutes,
    );
    final astrolabe = withOptions(
      AstroOptions(
        type: AstroDateType.solar,
        dateStr: tst.effectiveSolarDateStr,
        timeIndex: tst.timeIndex,
        gender: gender,
        fixLeap: fixLeap,
        language: language,
        config: config,
        astroType: astroType,
        calendar: calendar,
      ),
    );
    return TrueSolarTimeAstrolabe(
      astrolabe: astrolabe,
      trueSolarTime: tst,
    );
  }

  /// Unified entrypoint supporting `solar`/`lunar` dates, per-chart [config]
  /// overrides, and `heaven`/`earth`/`human` chart rearrangement.
  static FunctionalAstrolabe withOptions(AstroOptions options) {
    final resolvedConfig = AstroConfigManager.resolveConfig(
      options.config,
      language: options.language,
    );
    final activeCalendar = options.calendar ?? _defaultCalendar;

    late final ParsedDateInput solarParsed;
    late final String solarDateStr;

    if (options.type == AstroDateType.solar) {
      solarParsed = validateSolarDateStr(options.dateStr);
      solarDateStr = options.dateStr;
    } else {
      final lunarParsed = validateLunarDateStr(
        options.dateStr,
        isLeapMonth: options.isLeapMonth,
        calendar: activeCalendar,
      );
      final solar = activeCalendar.lunarToSolar(
        lunarParsed.year,
        lunarParsed.month,
        lunarParsed.day,
        isLeapMonth: options.isLeapMonth,
      );
      solarDateStr = '${solar.year}-${solar.month}-${solar.day}';
      solarParsed = ParsedDateInput(
        year: solar.year,
        month: solar.month,
        day: solar.day,
      );
    }

    validateTimeIndex(options.timeIndex);

    final baseChart = _buildSolarAstrolabe(
      solarDateStr: solarDateStr,
      year: solarParsed.year,
      month: solarParsed.month,
      day: solarParsed.day,
      timeIndex: options.timeIndex,
      gender: options.gender,
      fixLeap: options.fixLeap,
      config: resolvedConfig,
      calendar: activeCalendar,
      astroType: options.astroType,
    );

    switch (options.astroType) {
      case AstroType.heaven:
        return baseChart;
      case AstroType.earth:
        final bodyPalace = baseChart.palaces.firstWhere((p) => p.isBodyPalace);
        return rearrangeAstrolabe(
          from: (
            heavenlyStem: bodyPalace.stem,
            earthlyBranch: bodyPalace.branch,
          ),
          astrolabe: baseChart,
          birthYear: solarParsed.year,
          birthMonth: solarParsed.month,
          birthDay: solarParsed.day,
          timeIndex: options.timeIndex,
          fixLeap: options.fixLeap,
          config: resolvedConfig,
          calendar: activeCalendar,
        );
      case AstroType.human:
        final spiritPalace = baseChart.palace(PalaceName.spirit)!;
        return rearrangeAstrolabe(
          from: (
            heavenlyStem: spiritPalace.stem,
            earthlyBranch: spiritPalace.branch,
          ),
          astrolabe: baseChart,
          birthYear: solarParsed.year,
          birthMonth: solarParsed.month,
          birthDay: solarParsed.day,
          timeIndex: options.timeIndex,
          fixLeap: options.fixLeap,
          config: resolvedConfig,
          calendar: activeCalendar,
        );
    }
  }

  /// Returns the localized zodiac animal for [solarDateStr].
  static String getZodiacBySolarDate(
    String solarDateStr, {
    AstroLanguage? language,
    LunarCalendarAdapter? calendar,
  }) {
    final parsed = validateSolarDateStr(solarDateStr);
    final lang = language ?? AstroConfigManager.getLanguage();
    final cfg = AstroConfigManager.getConfig();
    final activeCalendar = calendar ?? _defaultCalendar;
    final info = activeCalendar.solarToLunar(
      parsed.year,
      parsed.month,
      parsed.day,
      timeIndex: 0,
      yearDivide: cfg.yearDivide,
      horoscopeDivide: cfg.horoscopeDivide,
    );
    final zodiac = ZodiacSign.values[info.yearBranch.index];
    return LocaleRegistry.translate(zodiac.key, lang);
  }

  /// Returns the localized Western constellation sign for [solarDateStr].
  static String getSignBySolarDate(
    String solarDateStr, {
    AstroLanguage? language,
  }) {
    final parsed = validateSolarDateStr(solarDateStr);
    final lang = language ?? AstroConfigManager.getLanguage();
    final sign = constellationOfSolar(parsed.month, parsed.day);
    return LocaleRegistry.translate(sign.key, lang);
  }

  /// Returns the localized Western constellation sign for [lunarDateStr].
  static String getSignByLunarDate(
    String lunarDateStr, {
    bool isLeapMonth = false,
    AstroLanguage? language,
    LunarCalendarAdapter? calendar,
  }) {
    final activeCalendar = calendar ?? _defaultCalendar;
    final parsed = validateLunarDateStr(
      lunarDateStr,
      isLeapMonth: isLeapMonth,
      calendar: activeCalendar,
    );
    final solar = activeCalendar.lunarToSolar(
      parsed.year,
      parsed.month,
      parsed.day,
      isLeapMonth: isLeapMonth,
    );
    return getSignBySolarDate(
      '${solar.year}-${solar.month}-${solar.day}',
      language: language,
    );
  }

  /// Returns comma-joined major star names in the Soul Palace for a solar date
  /// (borrowing from the opposite palace if Soul Palace is empty).
  static String getMajorStarBySolarDate(
    String solarDateStr,
    int timeIndex, {
    bool fixLeap = true,
    AstroLanguage? language,
    LunarCalendarAdapter? calendar,
  }) {
    final parsed = validateSolarDateStr(solarDateStr);
    validateTimeIndex(timeIndex);
    final activeCalendar = calendar ?? _defaultCalendar;
    final resolvedConfig = AstroConfigManager.resolveConfig(
      null,
      language: language,
    );
    final boundary = normalizeDayBoundary(
      parsed.year,
      parsed.month,
      parsed.day,
      timeIndex,
      dayDivide: resolvedConfig.dayDivide,
      calendar: activeCalendar,
    );
    final soulAndBody = getSoulAndBody(
      year: boundary.year,
      month: boundary.month,
      day: boundary.day,
      timeIndex: boundary.timeIndex,
      fixLeap: fixLeap,
      config: resolvedConfig,
      calendar: activeCalendar,
    );
    final majorStars = getMajorStar(
      year: boundary.year,
      month: boundary.month,
      day: boundary.day,
      timeIndex: boundary.timeIndex,
      fixLeap: fixLeap,
      config: resolvedConfig,
      calendar: activeCalendar,
    );
    final soulStars = majorStars[soulAndBody.soulIndex]
        .where((s) => s.type == StarType.major)
        .toList();
    if (soulStars.isNotEmpty) {
      return soulStars.map((s) => s.name).join(',');
    }
    return majorStars[fixIndex(soulAndBody.soulIndex + 6)]
        .where((s) => s.type == StarType.major)
        .map((s) => s.name)
        .join(',');
  }

  /// Returns comma-joined major star names in the Soul Palace for a lunar date
  /// (borrowing from the opposite palace if Soul Palace is empty).
  static String getMajorStarByLunarDate(
    String lunarDateStr,
    int timeIndex, {
    bool isLeapMonth = false,
    bool fixLeap = true,
    AstroLanguage? language,
    LunarCalendarAdapter? calendar,
  }) {
    final activeCalendar = calendar ?? _defaultCalendar;
    final parsed = validateLunarDateStr(
      lunarDateStr,
      isLeapMonth: isLeapMonth,
      calendar: activeCalendar,
    );
    final solar = activeCalendar.lunarToSolar(
      parsed.year,
      parsed.month,
      parsed.day,
      isLeapMonth: isLeapMonth,
    );
    return getMajorStarBySolarDate(
      '${solar.year}-${solar.month}-${solar.day}',
      timeIndex,
      fixLeap: fixLeap,
      language: language,
      calendar: activeCalendar,
    );
  }

  static FunctionalAstrolabe _buildSolarAstrolabe({
    required String solarDateStr,
    required int year,
    required int month,
    required int day,
    required int timeIndex,
    required Gender gender,
    required bool fixLeap,
    required ResolvedAstroConfig config,
    required LunarCalendarAdapter calendar,
    required AstroType astroType,
  }) {
    final boundary = normalizeDayBoundary(
      year,
      month,
      day,
      timeIndex,
      dayDivide: config.dayDivide,
      calendar: calendar,
    );

    final lunarInfo = calendar.solarToLunar(
      boundary.year,
      boundary.month,
      boundary.day,
      timeIndex: boundary.timeIndex,
      yearDivide: config.yearDivide,
      horoscopeDivide: config.horoscopeDivide,
    );

    final yearBranch = lunarInfo.yearBranch;
    final yearStem = lunarInfo.yearStem;

    final soulAndBody = getSoulAndBody(
      year: boundary.year,
      month: boundary.month,
      day: boundary.day,
      timeIndex: boundary.timeIndex,
      fixLeap: fixLeap,
      config: config,
      calendar: calendar,
    );
    final palaceNames = getPalaceNames(soulAndBody.soulIndex);
    final majorStars = getMajorStar(
      year: boundary.year,
      month: boundary.month,
      day: boundary.day,
      timeIndex: boundary.timeIndex,
      fixLeap: fixLeap,
      config: config,
      calendar: calendar,
    );
    final minorStars = getMinorStar(
      year: boundary.year,
      month: boundary.month,
      day: boundary.day,
      timeIndex: boundary.timeIndex,
      fixLeap: fixLeap,
      config: config,
      calendar: calendar,
    );
    final adjectiveStars = getAdjectiveStar(
      year: boundary.year,
      month: boundary.month,
      day: boundary.day,
      timeIndex: boundary.timeIndex,
      gender: gender,
      fixLeap: fixLeap,
      config: config,
      calendar: calendar,
    );
    final changsheng12 = getChangsheng12(
      year: boundary.year,
      month: boundary.month,
      day: boundary.day,
      timeIndex: boundary.timeIndex,
      gender: gender,
      fixLeap: fixLeap,
      config: config,
      calendar: calendar,
    );
    final boshi12 = getBoShi12(
      year: boundary.year,
      month: boundary.month,
      day: boundary.day,
      gender: gender,
      config: config,
      calendar: calendar,
    );
    final yearly12 = getYearly12(
      year: boundary.year,
      month: boundary.month,
      day: boundary.day,
      config: config,
      calendar: calendar,
    );
    final horoscope = getDecadalsAndAges(
      year: boundary.year,
      month: boundary.month,
      day: boundary.day,
      timeIndex: boundary.timeIndex,
      gender: gender,
      fixLeap: fixLeap,
      config: config,
      calendar: calendar,
    );

    final palaces = List<FunctionalPalace>.generate(12, (i) {
      final stemIdx = fixIndex(
        soulAndBody.heavenlyStemOfSoul.index - soulAndBody.soulIndex + i,
        10,
      );
      final palaceStem = HeavenlyStem.values[stemIdx];
      final palaceBranch = palaceIndexToEarthlyBranch(i);

      return FunctionalPalace(
        index: i,
        palaceName: palaceNames[i],
        isBodyPalace: soulAndBody.bodyIndex == i,
        isOriginalPalace: palaceBranch != EarthlyBranch.zi &&
            palaceBranch != EarthlyBranch.chou &&
            palaceStem == yearStem,
        stem: palaceStem,
        branch: palaceBranch,
        majorStars: majorStars[i],
        minorStars: minorStars[i],
        adjectiveStars: adjectiveStars[i],
        changsheng12: changsheng12[i],
        boshi12: boshi12[i],
        jiangqian12: yearly12.jiangqian12[i],
        suiqian12: yearly12.suiqian12[i],
        decadal: horoscope.decadals[i],
        ages: horoscope.ages[i],
        language: config.language,
      );
    }, growable: false);

    final soulBranch = palaceIndexToEarthlyBranch(soulAndBody.soulIndex);
    final bodyBranch = palaceIndexToEarthlyBranch(soulAndBody.bodyIndex);

    final soulStar = earthlyBranchesMeta[
            config.algorithm == Algorithm.zhongzhou ? yearBranch : soulBranch]!
        .soul;
    final bodyStar = earthlyBranchesMeta[yearBranch]!.body;

    final chineseTime = ChineseTime.fromIndex(timeIndex);
    final zodiac = ZodiacSign.values[yearBranch.index];
    final sign = constellationOfSolar(month, day);

    return FunctionalAstrolabe(
      genderValue: gender,
      solarDate: solarDateStr,
      lunarDate: LocaleRegistry.formatLunarDate(lunarInfo, config.language),
      chineseDate:
          LocaleRegistry.translateChineseDate(lunarInfo, config.language),
      rawDates: AstrolabeRawDates(
        lunarDate: lunarInfo,
        chineseDate: lunarInfo,
        boundarySolarYear: boundary.year,
        boundarySolarMonth: boundary.month,
        boundarySolarDay: boundary.day,
        boundaryTimeIndex: boundary.timeIndex,
      ),
      timeIndex: timeIndex,
      time: LocaleRegistry.translate(chineseTime.key, config.language),
      timeRange: chineseTime.timeRange,
      sign: LocaleRegistry.translate(sign.key, config.language),
      zodiac: LocaleRegistry.translate(zodiac.key, config.language),
      soulPalaceBranch: soulBranch,
      bodyPalaceBranch: bodyBranch,
      soulStarKey: soulStar,
      bodyStarKey: bodyStar,
      fiveElementsClassEnum: getFiveElementsClass(
        soulAndBody.heavenlyStemOfSoul,
        soulAndBody.earthlyBranchOfSoul,
      ),
      palaces: palaces,
      copyright:
          'copyright © 2023-${DateTime.now().year} iztro (https://github.com/SylarLong/iztro)',
      configSnapshot: config,
      calendarAdapter: calendar,
      fixLeap: fixLeap,
      astroType: astroType,
    );
  }
}
