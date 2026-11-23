import '../calendar/calendar_adapter.dart';
import '../calendar/day_boundary.dart';
import '../core/config.dart';
import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import '../data/stars_meta.dart';
import 'functional_star.dart';
import 'location.dart';

/// Places the 14 minor stars (六吉、六煞、禄存、天马) into the 12 palaces,
/// matching `iztro/src/star/minorStar.ts#getMinorStar`.
List<List<FunctionalStar>> getMinorStar({
  required int year,
  required int month,
  required int day,
  required int timeIndex,
  required bool fixLeap,
  required ResolvedAstroConfig config,
  required LunarCalendarAdapter calendar,
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
  final monthIndex = fixLunarMonthIndex(lunarInfo: lunarInfo, fixLeap: fixLeap);
  final yearStem = lunarInfo.yearStem;
  final yearBranch = lunarInfo.yearBranch;

  final zuoYou = getZuoYouIndex(monthIndex + 1);
  final changQu = getChangQuIndex(boundary.timeIndex);
  final kuiYue = getKuiYueIndex(yearStem);
  final huoLing = getHuoLingIndex(yearBranch, boundary.timeIndex);
  final kongJie = getKongJieIndex(boundary.timeIndex);
  final luYangTuoMa = getLuYangTuoMaIndex(yearStem, yearBranch);

  final stars = List<List<FunctionalStar>>.generate(12, (_) => []);

  void addStar(
    int palaceIdx,
    StarKey key,
    StarType type, {
    bool withMutagen = false,
  }) {
    stars[palaceIdx].add(
      FunctionalStar(
        key: key,
        name: LocaleRegistry.translate(key.key, config.language),
        type: type,
        scope: Scope.origin,
        brightness: resolveStarBrightness(key, palaceIdx, config),
        mutagen: withMutagen ? resolveStarMutagen(key, yearStem, config) : null,
        language: config.language,
        includeBrightnessInJson: true,
        includeMutagenInJson: withMutagen,
      ),
    );
  }

  addStar(zuoYou.zuoIndex, StarKey.zuofuMin, StarType.soft, withMutagen: true);
  addStar(zuoYou.youIndex, StarKey.youbiMin, StarType.soft, withMutagen: true);
  addStar(
    changQu.changIndex,
    StarKey.wenchangMin,
    StarType.soft,
    withMutagen: true,
  );
  addStar(changQu.quIndex, StarKey.wenquMin, StarType.soft, withMutagen: true);
  addStar(kuiYue.kuiIndex, StarKey.tiankuiMin, StarType.soft);
  addStar(kuiYue.yueIndex, StarKey.tianyueMin, StarType.soft);
  addStar(luYangTuoMa.luIndex, StarKey.lucunMin, StarType.lucun);
  addStar(luYangTuoMa.maIndex, StarKey.tianmaMin, StarType.tianma);
  addStar(kongJie.kongIndex, StarKey.dikongMin, StarType.tough);
  addStar(kongJie.jieIndex, StarKey.dijieMin, StarType.tough);
  addStar(huoLing.huoIndex, StarKey.huoxingMin, StarType.tough);
  addStar(huoLing.lingIndex, StarKey.lingxingMin, StarType.tough);
  addStar(luYangTuoMa.yangIndex, StarKey.qingyangMin, StarType.tough);
  addStar(luYangTuoMa.tuoIndex, StarKey.tuoluoMin, StarType.tough);

  return stars;
}
