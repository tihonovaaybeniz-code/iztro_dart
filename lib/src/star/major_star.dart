import '../calendar/calendar_adapter.dart';
import '../calendar/day_boundary.dart';
import '../core/config.dart';
import '../core/index_math.dart';
import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import '../data/stars_meta.dart';
import 'functional_star.dart';
import 'location.dart';

/// Places the 14 major stars into the 12 palaces (`0 = 寅 .. 11 = 丑`),
/// matching `iztro/src/star/majorStar.ts#getMajorStar`.
List<List<FunctionalStar>> getMajorStar({
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
  final start = getStartIndex(
    year: boundary.year,
    month: boundary.month,
    day: boundary.day,
    timeIndex: boundary.timeIndex,
    fixLeap: fixLeap,
    config: config,
    calendar: calendar,
    from: from,
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
  final stars = List<List<FunctionalStar>>.generate(12, (_) => []);

  const ziweiGroup = <StarKey?>[
    StarKey.ziweiMaj,
    StarKey.tianjiMaj,
    null,
    StarKey.taiyangMaj,
    StarKey.wuquMaj,
    StarKey.tiantongMaj,
    null,
    null,
    StarKey.lianzhenMaj,
  ];

  const tianfuGroup = <StarKey?>[
    StarKey.tianfuMaj,
    StarKey.taiyinMaj,
    StarKey.tanlangMaj,
    StarKey.jumenMaj,
    StarKey.tianxiangMaj,
    StarKey.tianliangMaj,
    StarKey.qishaMaj,
    null,
    null,
    null,
    StarKey.pojunMaj,
  ];

  for (var i = 0; i < ziweiGroup.length; i++) {
    final key = ziweiGroup[i];
    if (key == null) {
      continue;
    }
    final palaceIdx = fixIndex(start.ziweiIndex - i);
    stars[palaceIdx].add(
      FunctionalStar(
        key: key,
        name: LocaleRegistry.translate(key.key, config.language),
        type: StarType.major,
        scope: Scope.origin,
        brightness: resolveStarBrightness(key, palaceIdx, config),
        mutagen: resolveStarMutagen(key, yearStem, config),
        language: config.language,
        includeBrightnessInJson: true,
        includeMutagenInJson: true,
      ),
    );
  }

  for (var i = 0; i < tianfuGroup.length; i++) {
    final key = tianfuGroup[i];
    if (key == null) {
      continue;
    }
    final palaceIdx = fixIndex(start.tianfuIndex + i);
    stars[palaceIdx].add(
      FunctionalStar(
        key: key,
        name: LocaleRegistry.translate(key.key, config.language),
        type: StarType.major,
        scope: Scope.origin,
        brightness: resolveStarBrightness(key, palaceIdx, config),
        mutagen: resolveStarMutagen(key, yearStem, config),
        language: config.language,
        includeBrightnessInJson: true,
        includeMutagenInJson: true,
      ),
    );
  }

  return stars;
}
