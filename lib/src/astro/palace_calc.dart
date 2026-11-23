import '../calendar/calendar_adapter.dart';
import '../calendar/day_boundary.dart';
import '../core/config.dart';
import '../core/index_math.dart';
import '../core/types.dart';
import '../data/branches_table.dart';
import '../data/locales/locale_registry.dart';
import '../data/stems_table.dart';

/// Calculated soul (命宫) and body (身宫) positions and soul palace GanZhi.
class SoulAndBodyResult {
  const SoulAndBodyResult({
    required this.soulIndex,
    required this.bodyIndex,
    required this.heavenlyStemOfSoul,
    required this.earthlyBranchOfSoul,
  });

  final int soulIndex;
  final int bodyIndex;
  final HeavenlyStem heavenlyStemOfSoul;
  final EarthlyBranch earthlyBranchOfSoul;
}

/// Ten-year decadal (大限) age range and GanZhi for a single palace.
class Decadal {
  const Decadal({
    required this.range,
    required this.heavenlyStem,
    required this.earthlyBranch,
    this.language = AstroLanguage.zhCN,
  });

  final (int start, int end) range;
  final HeavenlyStem heavenlyStem;
  final EarthlyBranch earthlyBranch;
  final AstroLanguage language;

  int get startAge => range.$1;
  int get endAge => range.$2;

  String get heavenlyStemName =>
      LocaleRegistry.translate(heavenlyStem.key, language);

  String get earthlyBranchName =>
      LocaleRegistry.translate(earthlyBranch.key, language);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'range': <int>[range.$1, range.$2],
        'heavenlyStem': heavenlyStemName,
        'earthlyBranch': earthlyBranchName,
      };
}

/// Computes soul palace (`命宫`) and body palace (`身宫`) indices (`0 = 寅 .. 11 = 丑`),
/// matching `iztro/src/astro/palace.ts#getSoulAndBody`.
SoulAndBodyResult getSoulAndBody({
  required int year,
  required int month,
  required int day,
  required int timeIndex,
  required bool fixLeap,
  required ResolvedAstroConfig config,
  required LunarCalendarAdapter calendar,
  ({HeavenlyStem heavenlyStem, EarthlyBranch earthlyBranch})? from,
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

  final leapOffset =
      lunarInfo.isLeapMonth && fixLeap && lunarInfo.lunarDay > 15 ? 1 : 0;
  final monthIndex = fixIndex(lunarInfo.lunarMonth - 1 + leapOffset);
  final timeBranchIndex = lunarInfo.hourBranch.index;

  var soulIndex = fixIndex(monthIndex - timeBranchIndex);
  final bodyIndex = fixIndex(monthIndex + timeBranchIndex);

  if (from != null) {
    soulIndex = earthlyBranchToPalaceIndex(from.earthlyBranch);
  }

  final startStem = tigerRule[lunarInfo.yearStem]!;
  final stemOfSoul =
      HeavenlyStem.values[fixIndex(startStem.index + soulIndex, 10)];
  final branchOfSoul = palaceIndexToEarthlyBranch(soulIndex);

  return SoulAndBodyResult(
    soulIndex: soulIndex,
    bodyIndex: bodyIndex,
    heavenlyStemOfSoul: stemOfSoul,
    earthlyBranchOfSoul: branchOfSoul,
  );
}

/// Computes the Five Elements Class (纳音五行局) from stem and branch,
/// matching `iztro/src/astro/palace.ts#getFiveElementsClass`.
FiveElementsClass getFiveElementsClass(
  HeavenlyStem stem,
  EarthlyBranch branch,
) {
  const table = [
    FiveElementsClass.wood3rd,
    FiveElementsClass.metal4th,
    FiveElementsClass.water2nd,
    FiveElementsClass.fire6th,
    FiveElementsClass.earth5th,
  ];
  final stemNumber = (stem.index ~/ 2) + 1;
  final branchNumber = (fixIndex(branch.index, 6) ~/ 2) + 1;
  var index = stemNumber + branchNumber;
  while (index > 5) {
    index -= 5;
  }
  return table[index - 1];
}

/// Returns the 12 [PalaceName]s ordered by palace index `0..11` (`0 = 寅 .. 11 = 丑`)
/// starting from soul palace at [fromIndex].
List<PalaceName> getPalaceNames(int fromIndex) {
  return List<PalaceName>.generate(
    12,
    (i) => PalaceName.values[fixIndex(i - fromIndex)],
    growable: false,
  );
}

/// Starting palace index for small-limit ages (小限) by year branch,
/// matching `iztro/src/utils/index.ts#getAgeIndex`.
int getAgeStartIndex(EarthlyBranch yearBranch) {
  final target = switch (yearBranch) {
    EarthlyBranch.yin ||
    EarthlyBranch.wu ||
    EarthlyBranch.xu =>
      EarthlyBranch.chen,
    EarthlyBranch.shen ||
    EarthlyBranch.zi ||
    EarthlyBranch.chen =>
      EarthlyBranch.xu,
    EarthlyBranch.si ||
    EarthlyBranch.you ||
    EarthlyBranch.chou =>
      EarthlyBranch.wei,
    EarthlyBranch.hai ||
    EarthlyBranch.mao ||
    EarthlyBranch.wei =>
      EarthlyBranch.chou,
  };
  return earthlyBranchToPalaceIndex(target);
}

/// Computes the 12 decadal intervals (大限) and small-limit age lists (小限),
/// matching `iztro/src/astro/palace.ts#getHoroscope`.
({List<Decadal> decadals, List<List<int>> ages}) getDecadalsAndAges({
  required int year,
  required int month,
  required int day,
  required int timeIndex,
  required Gender gender,
  required bool fixLeap,
  required ResolvedAstroConfig config,
  required LunarCalendarAdapter calendar,
  ({HeavenlyStem heavenlyStem, EarthlyBranch earthlyBranch})? from,
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
  final yearStem = lunarInfo.yearStem;
  final yearBranch = lunarInfo.yearBranch;
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

  final fiveElements = getFiveElementsClass(
    from?.heavenlyStem ?? soulAndBody.heavenlyStemOfSoul,
    from?.earthlyBranch ?? soulAndBody.earthlyBranchOfSoul,
  );
  final startStem = tigerRule[yearStem]!;
  final isForward = gender.yinYang == earthlyBranchesMeta[yearBranch]!.yinYang;

  final decadals = List<Decadal?>.filled(12, null);
  for (var i = 0; i < 12; i++) {
    final idx = isForward
        ? fixIndex(soulAndBody.soulIndex + i)
        : fixIndex(soulAndBody.soulIndex - i);
    final start = fiveElements.value + 10 * i;
    final stem = HeavenlyStem.values[fixIndex(startStem.index + idx, 10)];
    final branch = palaceIndexToEarthlyBranch(idx);
    decadals[idx] = Decadal(
      range: (start, start + 9),
      heavenlyStem: stem,
      earthlyBranch: branch,
      language: config.language,
    );
  }

  final ageIdx = getAgeStartIndex(yearBranch);
  final ages = List<List<int>>.generate(12, (_) => const []);
  for (var i = 0; i < 12; i++) {
    final ageList = List<int>.generate(10, (j) => 12 * j + i + 1);
    final idx =
        gender == Gender.male ? fixIndex(ageIdx + i) : fixIndex(ageIdx - i);
    ages[idx] = ageList;
  }

  return (
    decadals: decadals.cast<Decadal>(),
    ages: ages,
  );
}
