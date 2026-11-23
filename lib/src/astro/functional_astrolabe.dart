import '../calendar/calendar_adapter.dart';
import '../calendar/day_boundary.dart';
import '../core/config.dart';
import '../core/index_math.dart';
import '../core/types.dart';
import '../core/validation.dart';
import '../data/locales/locale_registry.dart';
import '../data/stars_meta.dart';
import '../llm/chart_dsl.dart';
import '../llm/compact_dsl.dart';
import '../llm/prompt_builder.dart';
import '../star/functional_star.dart';
import '../star/horoscope_star.dart';
import '../star/yearly12_star.dart';
import 'analyzer.dart';
import 'functional_flanking_palaces.dart';
import 'functional_horoscope.dart';
import 'functional_palace.dart';
import 'functional_surpalaces.dart';
import 'horoscope_calc.dart';
import 'palace_calc.dart';

/// Raw date snapshot stored inside [FunctionalAstrolabe], aligned with
/// `iztro`'s `astrolabe.rawDates`.
class AstrolabeRawDates {
  const AstrolabeRawDates({
    required this.lunarDate,
    required this.chineseDate,
    required this.boundarySolarYear,
    required this.boundarySolarMonth,
    required this.boundarySolarDay,
    required this.boundaryTimeIndex,
  });

  final LunarDateInfo lunarDate;
  final LunarDateInfo chineseDate;
  final int boundarySolarYear;
  final int boundarySolarMonth;
  final int boundarySolarDay;
  final int boundaryTimeIndex;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lunarDate': <String, dynamic>{
          'lunarYear': lunarDate.lunarYear,
          'lunarMonth': lunarDate.lunarMonth,
          'lunarDay': lunarDate.lunarDay,
          'isLeap': lunarDate.isLeapMonth,
        },
        'chineseDate': <String, dynamic>{
          'yearly': <String>[lunarDate.yearStem.zh, lunarDate.yearBranch.zh],
          'monthly': <String>[lunarDate.monthStem.zh, lunarDate.monthBranch.zh],
          'daily': <String>[lunarDate.dayStem.zh, lunarDate.dayBranch.zh],
          'hourly': <String>[lunarDate.hourStem.zh, lunarDate.hourBranch.zh],
        },
      };
}

/// Complete Ziwei Doushu astrolabe object with immutable configuration and
/// calendar snapshots, aligned with `iztro@2.6.5#FunctionalAstrolabe`.
class FunctionalAstrolabe {
  FunctionalAstrolabe({
    required this.genderValue,
    required this.solarDate,
    required this.lunarDate,
    required this.chineseDate,
    required this.rawDates,
    required this.timeIndex,
    required this.time,
    required this.timeRange,
    required this.sign,
    required this.zodiac,
    required this.soulPalaceBranch,
    required this.bodyPalaceBranch,
    required this.soulStarKey,
    required this.bodyStarKey,
    required this.fiveElementsClassEnum,
    required this.palaces,
    required this.copyright,
    required this.configSnapshot,
    required this.calendarAdapter,
    required this.fixLeap,
    required this.astroType,
  }) {
    bindContext();
  }

  /// Gender enum.
  final Gender genderValue;

  /// Localized gender display text (matches `astrolabe.gender` in `iztro`).
  String get gender =>
      LocaleRegistry.translate(genderValue.key, configSnapshot.language);

  /// Original solar input date string (`YYYY-M-D`).
  final String solarDate;

  /// Formatted lunar date string according to chart language.
  final String lunarDate;

  /// Formatted four-pillar Chinese date string according to chart language.
  final String chineseDate;

  /// Raw calendar & pillar snapshot.
  final AstrolabeRawDates rawDates;

  /// Original birth time index (`0..12`).
  final int timeIndex;

  /// Localized birth hour label (e.g. `寅时`).
  final String time;

  /// Wall-clock range string (e.g. `03:00~05:00`).
  final String timeRange;

  /// Localized constellation sign.
  final String sign;

  /// Localized zodiac animal.
  final String zodiac;

  /// Earthly branch of Soul Palace (updated during earth/human rearrange).
  EarthlyBranch soulPalaceBranch;

  /// Earthly branch of Body Palace.
  EarthlyBranch bodyPalaceBranch;

  /// Localized Soul Palace branch (`命宫地支`).
  String get earthlyBranchOfSoulPalace =>
      LocaleRegistry.translate(soulPalaceBranch.key, configSnapshot.language);

  /// Localized Body Palace branch (`身宫地支`).
  String get earthlyBranchOfBodyPalace =>
      LocaleRegistry.translate(bodyPalaceBranch.key, configSnapshot.language);

  /// Soul star key (`命主`).
  final StarKey soulStarKey;

  /// Body star key (`身主`).
  final StarKey bodyStarKey;

  /// Localized Soul star (`命主`).
  String get soul =>
      LocaleRegistry.translate(soulStarKey.key, configSnapshot.language);

  /// Localized Body star (`身主`).
  String get body =>
      LocaleRegistry.translate(bodyStarKey.key, configSnapshot.language);

  /// Five Elements Class enum (updated during earth/human rearrange).
  FiveElementsClass fiveElementsClassEnum;

  /// Localized Five Elements Class (`水二局` .. `火六局`).
  String get fiveElementsClass => LocaleRegistry.translate(
        fiveElementsClassEnum.key,
        configSnapshot.language,
      );

  /// Twelve palaces ordered `0 = 寅 .. 11 = 丑`.
  final List<FunctionalPalace> palaces;

  /// Upstream attribution copyright string.
  final String copyright;

  /// Immutable configuration snapshot captured when generating this chart.
  final ResolvedAstroConfig configSnapshot;

  /// Calendar adapter snapshot captured when generating this chart.
  final LunarCalendarAdapter calendarAdapter;

  /// Leap-month adjustment option captured at creation.
  final bool fixLeap;

  /// Chart type (`heaven`, `earth`, or `human`).
  final AstroType astroType;

  /// Re-binds palace and star back-references after creation or rearrangement.
  void bindContext() {
    for (final palace in palaces) {
      palace.bindAstrolabe(this);
    }
  }

  /// Looks up a palace by [PalaceName], `int` index (`0..11`), or localized
  /// palace name [String] (including `身宫` / `来因`).
  FunctionalPalace? palace(Object indexOrName) {
    if (indexOrName is int) {
      if (indexOrName < 0 || indexOrName >= palaces.length) {
        return null;
      }
      return palaces[indexOrName];
    }
    if (indexOrName is PalaceName) {
      for (final p in palaces) {
        if (p.palaceName == indexOrName) {
          return p;
        }
      }
      return null;
    }
    if (indexOrName is String) {
      final key = LocaleRegistry.kot(indexOrName, filter: 'Palace');
      if (key == 'originalPalace') {
        for (final p in palaces) {
          if (p.isOriginalPalace) {
            return p;
          }
        }
        return null;
      }
      if (key == 'bodyPalace') {
        for (final p in palaces) {
          if (p.isBodyPalace) {
            return p;
          }
        }
        return null;
      }
      final parsed = PalaceName.tryFromKey(key) ??
          LocaleRegistry.tryParsePalaceName(indexOrName);
      if (parsed == null) {
        return null;
      }
      for (final p in palaces) {
        if (p.palaceName == parsed) {
          return p;
        }
      }
      return null;
    }
    throw ArgumentError.value(
      indexOrName,
      'indexOrName',
      'Expected int, PalaceName, or localized String.',
    );
  }

  /// Convenience UI lookup by [EarthlyBranch] (`子=0 .. 亥=11` widgets can call
  /// `palaceAtBranch(EarthlyBranch.zi)` without manual `-2` index conversion).
  FunctionalPalace palaceAtBranch(EarthlyBranch branch) {
    return palaces[earthlyBranchToPalaceIndex(branch)];
  }

  /// Finds a star in the natal chart by [StarKey] or localized star [String].
  FunctionalStar star(Object starKeyOrName) {
    final StarKey? key;
    if (starKeyOrName is StarKey) {
      key = starKeyOrName;
    } else if (starKeyOrName is String) {
      key = LocaleRegistry.tryParseStarKey(starKeyOrName);
    } else {
      throw ArgumentError.value(
        starKeyOrName,
        'starKeyOrName',
        'Expected StarKey or String.',
      );
    }

    if (key != null) {
      for (final p in palaces) {
        for (final s in p.allStars) {
          if (s.key == key) {
            s.bindPalace(p);
            s.bindAstrolabe(this);
            return s;
          }
        }
      }
    }
    throw ArgumentError.value(
      starKeyOrName,
      'starKeyOrName',
      'invalid star name.',
    );
  }

  /// Returns surrounded palaces (三方四正) for [indexOrName].
  FunctionalSurpalaces surroundedPalaces(Object indexOrName) =>
      getSurroundedPalaces(this, indexOrName);

  /// Returns adjacent flanking palaces (夹宫) for [indexOrName].
  FunctionalFlankingPalaces flankingPalaces(Object indexOrName) =>
      getFlankingPalaces(this, indexOrName);

  /// Returns `true` if ALL [stars] appear across the surrounded palaces of [indexOrName].
  bool isSurrounded(Object indexOrName, List<StarKey> stars) =>
      surroundedPalaces(indexOrName).have(stars);

  /// Computes six-layer dynamic horoscope data for [targetDate] (`DateTime`,
  /// solar date `String`, or `null` for `DateTime.now()`) and optional
  /// [timeIndex] (`0..12`).
  FunctionalHoroscope horoscope([Object? targetDate, int? timeIndex]) {
    if (timeIndex != null) {
      validateTimeIndex(timeIndex);
    }

    late final int rawYear;
    late final int rawMonth;
    late final int rawDay;
    late final int fallbackTimeIndex;
    late final String rawSolarDateStr;

    final effective = targetDate ?? DateTime.now();
    if (effective is DateTime) {
      rawYear = effective.year;
      rawMonth = effective.month;
      rawDay = effective.day;
      fallbackTimeIndex = timeToIndex(effective.hour);
      rawSolarDateStr = '$rawYear-$rawMonth-$rawDay';
    } else if (effective is String) {
      final parsed = validateSolarDateStr(effective);
      rawYear = parsed.year;
      rawMonth = parsed.month;
      rawDay = parsed.day;
      fallbackTimeIndex = timeToIndex(parsed.hour ?? 0);
      rawSolarDateStr = '$rawYear-$rawMonth-$rawDay';
    } else {
      throw ArgumentError.value(
        targetDate,
        'targetDate',
        'Expected DateTime, String, or null.',
      );
    }

    final targetTimeIndex = timeIndex ?? fallbackTimeIndex;
    final boundary = normalizeDayBoundary(
      rawYear,
      rawMonth,
      rawDay,
      targetTimeIndex,
      dayDivide: configSnapshot.dayDivide,
      calendar: calendarAdapter,
    );

    final targetLunar = calendarAdapter.solarToLunar(
      boundary.year,
      boundary.month,
      boundary.day,
      timeIndex: boundary.timeIndex,
      yearDivide: configSnapshot.horoscopeDivide,
      horoscopeDivide: configSnapshot.horoscopeDivide,
    );
    final birthLunar = rawDates.lunarDate;
    final lang = configSnapshot.language;

    var nominalAge = targetLunar.lunarYear - birthLunar.lunarYear;
    if (configSnapshot.ageDivide == AgeDivideType.birthday) {
      if (targetLunar.lunarMonth > birthLunar.lunarMonth ||
          (targetLunar.lunarMonth == birthLunar.lunarMonth &&
              targetLunar.lunarDay > birthLunar.lunarDay)) {
        nominalAge += 1;
      }
    } else {
      nominalAge += 1;
    }

    var decadalIndex = -1;
    var decadalStem = HeavenlyStem.jia;
    var decadalBranch = EarthlyBranch.zi;
    var isChildhood = false;

    for (var i = 0; i < palaces.length; i++) {
      final decadal = palaces[i].decadal;
      if (nominalAge >= decadal.startAge && nominalAge <= decadal.endAge) {
        decadalIndex = i;
        decadalStem = decadal.heavenlyStem;
        decadalBranch = decadal.earthlyBranch;
        break;
      }
    }

    if (decadalIndex < 0 && nominalAge >= 1 && nominalAge <= 6) {
      const childhoodPalaces = [
        PalaceName.soul,
        PalaceName.wealth,
        PalaceName.health,
        PalaceName.spouse,
        PalaceName.spirit,
        PalaceName.career,
      ];
      final targetPalace = palace(childhoodPalaces[nominalAge - 1]);
      if (targetPalace != null) {
        isChildhood = true;
        decadalIndex = targetPalace.index;
        decadalStem = targetPalace.stem;
        decadalBranch = targetPalace.branch;
      }
    }

    var ageIndex = -1;
    var ageStem = HeavenlyStem.jia;
    var ageBranch = EarthlyBranch.zi;
    for (var i = 0; i < palaces.length; i++) {
      if (palaces[i].ages.contains(nominalAge)) {
        ageIndex = i;
        ageStem = palaces[i].stem;
        ageBranch = palaces[i].branch;
        break;
      }
    }

    final yearlyIndex = earthlyBranchToPalaceIndex(targetLunar.yearBranch);
    final birthLeapAddition =
        birthLunar.isLeapMonth && birthLunar.lunarDay > 15 ? 1 : 0;
    final targetLeapAddition =
        targetLunar.isLeapMonth && targetLunar.lunarDay > 15 ? 1 : 0;
    final monthlyIndex = fixIndex(
      yearlyIndex -
          (birthLunar.lunarMonth + birthLeapAddition) +
          rawDates.chineseDate.hourBranch.index +
          (targetLunar.lunarMonth + targetLeapAddition),
    );
    final dailyIndex = fixIndex(monthlyIndex + targetLunar.lunarDay - 1);
    final hourlyIndex = fixIndex(dailyIndex + targetLunar.hourBranch.index);

    final yearly12 = getYearly12(
      year: boundary.year,
      month: boundary.month,
      day: boundary.day,
      config: configSnapshot,
      calendar: calendarAdapter,
    );

    return FunctionalHoroscope(
      solarDate: rawSolarDateStr,
      lunarDate: targetLunar.lunarDateChinese,
      isChildhood: isChildhood,
      decadal: HoroscopeItem(
        index: decadalIndex,
        name: LocaleRegistry.translate(
          isChildhood ? 'childhood' : 'decadal',
          lang,
        ),
        stem: decadalStem,
        branch: decadalBranch,
        palaceNamesEnum: getPalaceNames(decadalIndex),
        mutagenKeys: resolveMutagenStars(decadalStem, configSnapshot),
        stars: getHoroscopeStar(
          decadalStem,
          decadalBranch,
          Scope.decadal,
          language: lang,
        ),
        language: lang,
      ),
      age: AgeHoroscopeItem(
        index: ageIndex,
        nominalAge: nominalAge,
        name: LocaleRegistry.translate('turn', lang),
        stem: ageStem,
        branch: ageBranch,
        palaceNamesEnum: getPalaceNames(ageIndex),
        mutagenKeys: resolveMutagenStars(ageStem, configSnapshot),
        language: lang,
      ),
      yearly: YearlyHoroscopeItem(
        index: yearlyIndex,
        name: LocaleRegistry.translate('yearly', lang),
        stem: targetLunar.yearStem,
        branch: targetLunar.yearBranch,
        palaceNamesEnum: getPalaceNames(yearlyIndex),
        mutagenKeys: resolveMutagenStars(targetLunar.yearStem, configSnapshot),
        stars: getHoroscopeStar(
          targetLunar.yearStem,
          targetLunar.yearBranch,
          Scope.yearly,
          language: lang,
        ),
        jiangqian12: yearly12.jiangqian12,
        suiqian12: yearly12.suiqian12,
        language: lang,
      ),
      monthly: HoroscopeItem(
        index: monthlyIndex,
        name: LocaleRegistry.translate('monthly', lang),
        stem: targetLunar.monthStem,
        branch: targetLunar.monthBranch,
        palaceNamesEnum: getPalaceNames(monthlyIndex),
        mutagenKeys: resolveMutagenStars(targetLunar.monthStem, configSnapshot),
        stars: getHoroscopeStar(
          targetLunar.monthStem,
          targetLunar.monthBranch,
          Scope.monthly,
          language: lang,
        ),
        language: lang,
      ),
      daily: HoroscopeItem(
        index: dailyIndex,
        name: LocaleRegistry.translate('daily', lang),
        stem: targetLunar.dayStem,
        branch: targetLunar.dayBranch,
        palaceNamesEnum: getPalaceNames(dailyIndex),
        mutagenKeys: resolveMutagenStars(targetLunar.dayStem, configSnapshot),
        stars: getHoroscopeStar(
          targetLunar.dayStem,
          targetLunar.dayBranch,
          Scope.daily,
          language: lang,
        ),
        language: lang,
      ),
      hourly: HoroscopeItem(
        index: hourlyIndex,
        name: LocaleRegistry.translate('hourly', lang),
        stem: targetLunar.hourStem,
        branch: targetLunar.hourBranch,
        palaceNamesEnum: getPalaceNames(hourlyIndex),
        mutagenKeys: resolveMutagenStars(targetLunar.hourStem, configSnapshot),
        stars: getHoroscopeStar(
          targetLunar.hourStem,
          targetLunar.hourBranch,
          Scope.hourly,
          language: lang,
        ),
        language: lang,
      ),
      astrolabe: this,
    );
  }

  /// Returns all 12 decadals sorted chronologically by start age.
  List<DecadalHoroscope> decadalList() {
    final birthYear = rawDates.lunarDate.lunarYear;
    final lang = configSnapshot.language;
    final sorted = List<FunctionalPalace>.of(palaces)
      ..sort((a, b) => a.decadal.startAge.compareTo(b.decadal.startAge));

    return sorted.map((p) {
      return DecadalHoroscope(
        index: p.index,
        name: LocaleRegistry.translate('decadal', lang),
        palaceNameEnum: p.palaceName,
        ageRange: p.decadal.range,
        yearRange: (
          birthYear + p.decadal.startAge - 1,
          birthYear + p.decadal.endAge - 1,
        ),
        stem: p.decadal.heavenlyStem,
        branch: p.decadal.earthlyBranch,
        palaceNamesEnum: getPalaceNames(p.index),
        mutagenKeys:
            resolveMutagenStars(p.decadal.heavenlyStem, configSnapshot),
        stars: getHoroscopeStar(
          p.decadal.heavenlyStem,
          p.decadal.earthlyBranch,
          Scope.decadal,
          language: lang,
        ),
        language: lang,
      );
    }).toList(growable: false);
  }

  /// Returns the 10 yearly entries inside the decadal specified by
  /// [indexOrName] (`0..11` sorted decadal index, [PalaceName], or localized name).
  List<YearlyHoroscopeEntry> yearlyList(Object indexOrName) {
    final sorted = List<FunctionalPalace>.of(palaces)
      ..sort((a, b) => a.decadal.startAge.compareTo(b.decadal.startAge));

    final FunctionalPalace? decadalPalace;
    if (indexOrName is int) {
      decadalPalace = (indexOrName >= 0 && indexOrName < sorted.length)
          ? sorted[indexOrName]
          : null;
    } else {
      decadalPalace = palace(indexOrName);
    }

    if (decadalPalace == null) {
      throw ArgumentError.value(
        indexOrName,
        'indexOrName',
        'invalid decadal index or palace name.',
      );
    }

    final birthYear = rawDates.lunarDate.lunarYear;
    final startAge = decadalPalace.decadal.startAge;
    final endAge = decadalPalace.decadal.endAge;
    final birthHourIndex = rawDates.chineseDate.hourBranch.index;
    final lang = configSnapshot.language;

    return List<YearlyHoroscopeEntry>.generate(endAge - startAge + 1, (idx) {
      final age = startAge + idx;
      final year = birthYear + age - 1;
      final solar = calendarAdapter.lunarToSolar(year, 6, 1);
      final targetDateStr = '${solar.year}-${solar.month}-${solar.day}';
      final yearly = horoscope(targetDateStr, birthHourIndex).yearly;
      return YearlyHoroscopeEntry(
        index: yearly.index,
        name: yearly.name,
        age: age,
        year: year,
        stem: yearly.stem,
        branch: yearly.branch,
        palaceNamesEnum: yearly.palaceNamesEnum,
        mutagenKeys: yearly.mutagenKeys,
        stars: yearly.stars,
        language: lang,
      );
    }, growable: false);
  }

  /// Returns all monthly periods in lunar [year] (splitting leap months into
  /// first/second half when [fixLeap] is `true`).
  List<MonthlyHoroscopeEntry> monthlyList(int year, {bool fixLeap = true}) {
    if (year < 1 || year > 9999) {
      throw ArgumentError.value(year, 'year', 'invalid year.');
    }

    final age = year - rawDates.lunarDate.lunarYear + 1;
    final birthHourIndex = rawDates.chineseDate.hourBranch.index;
    final lang = configSnapshot.language;
    final months = calendarAdapter.getLunarMonthsInYear(year);

    final periods = <({
      int month,
      bool isLeapMonth,
      MonthlyPart part,
      (int, int) dayRange,
    })>[];

    for (final m in months) {
      if (m.isLeapMonth && fixLeap) {
        periods.add((
          month: m.month,
          isLeapMonth: true,
          part: MonthlyPart.first,
          dayRange: (1, 15),
        ));
        periods.add((
          month: m.month,
          isLeapMonth: true,
          part: MonthlyPart.second,
          dayRange: (16, m.dayCount),
        ));
      } else {
        periods.add((
          month: m.month,
          isLeapMonth: m.isLeapMonth,
          part: MonthlyPart.normal,
          dayRange: (1, m.dayCount),
        ));
      }
    }

    return periods.map((period) {
      final targetDay = period.part == MonthlyPart.second ? 16 : 1;
      final solar = calendarAdapter.lunarToSolar(
        year,
        period.month,
        targetDay,
        isLeapMonth: period.isLeapMonth,
      );
      final targetDateStr = '${solar.year}-${solar.month}-${solar.day}';
      final monthly = horoscope(targetDateStr, birthHourIndex).monthly;
      return MonthlyHoroscopeEntry(
        index: monthly.index,
        name: monthly.name,
        age: age,
        year: year,
        month: period.month,
        isLeapMonth: period.isLeapMonth,
        part: period.part,
        dayRange: period.dayRange,
        stem: monthly.stem,
        branch: monthly.branch,
        palaceNamesEnum: monthly.palaceNamesEnum,
        mutagenKeys: monthly.mutagenKeys,
        stars: monthly.stars,
        language: lang,
      );
    }).toList(growable: false);
  }

  /// Generates compact, hallucination-resistant Chart DSL JSON for LLM input.
  Map<String, dynamic> toLlmJson({
    DateTime? targetDate,
    int? timeIndex,
    List<PalaceName>? focusPalaces,
  }) =>
      ChartDsl.toLlmJson(
        this,
        targetDate: targetDate,
        timeIndex: timeIndex,
        focusPalaces: focusPalaces,
      );

  /// Generates a token-efficient plain-text Chart DSL for LLM prompts.
  String toCompactDsl({
    DateTime? targetDate,
    int? timeIndex,
    List<PalaceName>? focusPalaces,
  }) =>
      ChartCompactDsl.render(
        this,
        targetDate: targetDate,
        timeIndex: timeIndex,
        focusPalaces: focusPalaces,
      );

  /// Builds a fixed anti-hallucination prompt for an overall hero reading.
  ZiweiLlmPrompt buildHeroPrompt({
    DateTime? targetDate,
    int? timeIndex,
    ZiweiDslFormat format = ZiweiDslFormat.compactText,
    String? extraInstructions,
  }) =>
      ZiweiPromptBuilder.buildHeroPrompt(
        this,
        targetDate: targetDate,
        timeIndex: timeIndex,
        format: format,
        extraInstructions: extraInstructions,
      );

  /// Builds a fixed anti-hallucination prompt for a single [focusPalace].
  ZiweiLlmPrompt buildPalacePrompt(
    PalaceName focusPalace, {
    DateTime? targetDate,
    int? timeIndex,
    ZiweiDslFormat format = ZiweiDslFormat.compactText,
    String? extraInstructions,
  }) =>
      ZiweiPromptBuilder.buildPalacePrompt(
        this,
        focusPalace,
        targetDate: targetDate,
        timeIndex: timeIndex,
        format: format,
        extraInstructions: extraInstructions,
      );

  /// Builds a fixed anti-hallucination prompt for yearly fortune analysis.
  ZiweiLlmPrompt buildYearlyPrompt({
    DateTime? targetDate,
    int? timeIndex,
    ZiweiDslFormat format = ZiweiDslFormat.compactText,
    String? extraInstructions,
  }) =>
      ZiweiPromptBuilder.buildYearlyPrompt(
        this,
        targetDate: targetDate,
        timeIndex: timeIndex,
        format: format,
        extraInstructions: extraInstructions,
      );

  /// Serializes the astrolabe to an `iztro`-compatible plain JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'gender': gender,
        'solarDate': solarDate,
        'lunarDate': lunarDate,
        'chineseDate': chineseDate,
        'rawDates': rawDates.toJson(),
        'time': time,
        'timeRange': timeRange,
        'sign': sign,
        'zodiac': zodiac,
        'earthlyBranchOfSoulPalace': earthlyBranchOfSoulPalace,
        'earthlyBranchOfBodyPalace': earthlyBranchOfBodyPalace,
        'soul': soul,
        'body': body,
        'fiveElementsClass': fiveElementsClass,
        'palaces': palaces.map((p) => p.toJson()).toList(growable: false),
        'copyright': copyright,
      };
}
