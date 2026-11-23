import '../calendar/calendar_adapter.dart';
import '../calendar/day_boundary.dart';
import '../core/config.dart';
import '../core/index_math.dart';
import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import '../star/functional_star.dart';
import '../star/location.dart';
import '../star/major_star.dart';
import '../star/yearly12_star.dart';
import 'functional_astrolabe.dart';
import 'palace_calc.dart';

/// Rearranges an existing [FunctionalAstrolabe] around a new anchor palace
/// (`earth` = Body Palace, `human` = Spirit/Fude Palace),
/// matching `iztro/src/astro/astro.ts#rearrangeAstrolable`.
FunctionalAstrolabe rearrangeAstrolabe({
  required ({HeavenlyStem heavenlyStem, EarthlyBranch earthlyBranch}) from,
  required FunctionalAstrolabe astrolabe,
  required int birthYear,
  required int birthMonth,
  required int birthDay,
  required int timeIndex,
  required bool fixLeap,
  required ResolvedAstroConfig config,
  required LunarCalendarAdapter calendar,
}) {
  final boundary = normalizeDayBoundary(
    birthYear,
    birthMonth,
    birthDay,
    timeIndex,
    dayDivide: config.dayDivide,
    calendar: calendar,
  );
  final soulAndBody = getSoulAndBody(
    year: boundary.year,
    month: boundary.month,
    day: boundary.day,
    timeIndex: boundary.timeIndex,
    fixLeap: fixLeap,
    config: config,
    calendar: calendar,
    from: from,
  );
  final fiveElementsClass =
      getFiveElementsClass(from.heavenlyStem, from.earthlyBranch);
  final palaceNames = getPalaceNames(soulAndBody.soulIndex);
  final majorStars = getMajorStar(
    year: boundary.year,
    month: boundary.month,
    day: boundary.day,
    timeIndex: boundary.timeIndex,
    fixLeap: fixLeap,
    config: config,
    calendar: calendar,
    from: from,
  );
  final changsheng12 = getChangsheng12(
    year: boundary.year,
    month: boundary.month,
    day: boundary.day,
    timeIndex: boundary.timeIndex,
    gender: astrolabe.genderValue,
    fixLeap: fixLeap,
    config: config,
    calendar: calendar,
    from: from,
  );
  final horoscope = getDecadalsAndAges(
    year: boundary.year,
    month: boundary.month,
    day: boundary.day,
    timeIndex: boundary.timeIndex,
    gender: astrolabe.genderValue,
    fixLeap: fixLeap,
    config: config,
    calendar: calendar,
    from: from,
  );

  astrolabe.fiveElementsClassEnum = fiveElementsClass;

  final yearBranch = astrolabe.rawDates.chineseDate.yearBranch;
  final tianshiTianshang = getTianshiTianshangIndex(
    gender: astrolabe.genderValue,
    yearBranch: yearBranch,
    soulIndex: soulAndBody.soulIndex,
    algorithm: config.algorithm,
  );
  final tiancaiIndex = fixIndex(soulAndBody.soulIndex + yearBranch.index);

  for (var i = 0; i < 12; i++) {
    final palace = astrolabe.palaces[i];

    _syncRearrangedAdjectiveStar(
      palace.adjectiveStars,
      targetKey: StarKey.tianshang,
      shouldExist: tianshiTianshang.tianshangIndex == i,
      language: config.language,
    );
    _syncRearrangedAdjectiveStar(
      palace.adjectiveStars,
      targetKey: StarKey.tianshi,
      shouldExist: tianshiTianshang.tianshiIndex == i,
      language: config.language,
    );
    _syncRearrangedAdjectiveStar(
      palace.adjectiveStars,
      targetKey: StarKey.tiancai,
      shouldExist: tiancaiIndex == i,
      language: config.language,
    );

    palace.palaceName = palaceNames[i];
    palace.majorStars = majorStars[i];
    palace.changsheng12 = changsheng12[i];
    palace.decadal = horoscope.decadals[i];
    palace.ages = horoscope.ages[i];
    palace.isBodyPalace = soulAndBody.bodyIndex == i;
  }

  astrolabe.soulPalaceBranch = astrolabe.palace(PalaceName.soul)!.branch;
  astrolabe.bodyPalaceBranch =
      astrolabe.palaces.firstWhere((p) => p.isBodyPalace).branch;
  astrolabe.bindContext();

  return astrolabe;
}

void _syncRearrangedAdjectiveStar(
  List<FunctionalStar> stars, {
  required StarKey targetKey,
  required bool shouldExist,
  required AstroLanguage language,
}) {
  final existingIdx = stars.indexWhere((s) => s.key == targetKey);
  if (existingIdx != -1 && !shouldExist) {
    stars.removeAt(existingIdx);
  } else if (existingIdx == -1 && shouldExist) {
    stars.add(
      FunctionalStar(
        key: targetKey,
        name: LocaleRegistry.translate(targetKey.key, language),
        type: StarType.adjective,
        scope: Scope.origin,
        language: language,
      ),
    );
  }
}
