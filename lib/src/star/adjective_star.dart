import '../calendar/calendar_adapter.dart';
import '../calendar/day_boundary.dart';
import '../core/config.dart';
import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import 'functional_star.dart';
import 'location.dart';
import 'yearly12_star.dart';

/// Places all adjective / flower / helper stars into the 12 palaces,
/// preserving exact insertion order and `zhongzhou` school variations from
/// `iztro/src/star/adjectiveStar.ts#getAdjectiveStar`.
List<List<FunctionalStar>> getAdjectiveStar({
  required int year,
  required int month,
  required int day,
  required int timeIndex,
  required Gender gender,
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

  final yearlyIndex = getYearlyStarIndex(
    year: boundary.year,
    month: boundary.month,
    day: boundary.day,
    timeIndex: boundary.timeIndex,
    gender: gender,
    fixLeap: fixLeap,
    config: config,
    calendar: calendar,
  );
  final monthlyIndex = getMonthlyStarIndex(
    lunarInfo: lunarInfo,
    fixLeap: fixLeap,
  );
  final dailyIndex = getDailyStarIndex(
    year: boundary.year,
    month: boundary.month,
    day: boundary.day,
    timeIndex: boundary.timeIndex,
    fixLeap: fixLeap,
    config: config,
    calendar: calendar,
  );
  final timelyIndex = getTimelyStarIndex(boundary.timeIndex);
  final luanXi = getLuanXiIndex(lunarInfo.yearBranch);
  final yearly12 = getYearly12(
    year: boundary.year,
    month: boundary.month,
    day: boundary.day,
    config: config,
    calendar: calendar,
  );

  final stars = List<List<FunctionalStar>>.generate(12, (_) => []);

  void addStar(int palaceIdx, StarKey key, StarType type) {
    stars[palaceIdx].add(
      FunctionalStar(
        key: key,
        name: LocaleRegistry.translate(key.key, config.language),
        type: type,
        scope: Scope.origin,
        language: config.language,
      ),
    );
  }

  addStar(luanXi.hongluanIndex, StarKey.hongluan, StarType.flower);
  addStar(luanXi.tianxiIndex, StarKey.tianxi, StarType.flower);
  addStar(monthlyIndex.tianyaoIndex, StarKey.tianyao, StarType.flower);
  addStar(yearlyIndex.xianchiIndex, StarKey.xianchi, StarType.flower);
  addStar(monthlyIndex.yuejieIndex, StarKey.jieshen, StarType.helper);
  addStar(dailyIndex.santaiIndex, StarKey.santai, StarType.adjective);
  addStar(dailyIndex.bazuoIndex, StarKey.bazuo, StarType.adjective);
  addStar(dailyIndex.enguangIndex, StarKey.engguang, StarType.adjective);
  addStar(dailyIndex.tianguiIndex, StarKey.tiangui, StarType.adjective);
  addStar(yearlyIndex.longchiIndex, StarKey.longchi, StarType.adjective);
  addStar(yearlyIndex.fenggeIndex, StarKey.fengge, StarType.adjective);
  addStar(yearlyIndex.tiancaiIndex, StarKey.tiancai, StarType.adjective);
  addStar(yearlyIndex.tianshouIndex, StarKey.tianshou, StarType.adjective);
  addStar(timelyIndex.taifuIndex, StarKey.taifu, StarType.adjective);
  addStar(timelyIndex.fenggaoIndex, StarKey.fenggao, StarType.adjective);
  addStar(monthlyIndex.tianwuIndex, StarKey.tianwu, StarType.adjective);
  addStar(yearlyIndex.huagaiIndex, StarKey.huagai, StarType.adjective);
  addStar(yearlyIndex.tianguanIndex, StarKey.tianguan, StarType.adjective);
  addStar(yearlyIndex.tianfuIndex, StarKey.tianfu, StarType.adjective);
  addStar(yearlyIndex.tianchuIndex, StarKey.tianchu, StarType.adjective);
  addStar(monthlyIndex.tianyueIndex, StarKey.tianyue, StarType.adjective);
  addStar(yearlyIndex.tiandeIndex, StarKey.tiande, StarType.adjective);
  addStar(yearlyIndex.yuedeIndex, StarKey.yuede, StarType.adjective);
  addStar(yearlyIndex.tiankongIndex, StarKey.tiankong, StarType.adjective);
  addStar(yearlyIndex.xunkongIndex, StarKey.xunkong, StarType.adjective);

  if (config.algorithm != Algorithm.zhongzhou) {
    addStar(yearlyIndex.jieluIndex, StarKey.jielu, StarType.adjective);
    addStar(yearlyIndex.kongwangIndex, StarKey.kongwang, StarType.adjective);
  } else {
    final longdeName =
        LocaleRegistry.translate(StarKey.longde.key, config.language);
    final longdeIndex = yearly12.suiqian12.indexOf(longdeName);
    addStar(longdeIndex, StarKey.longde, StarType.adjective);
    addStar(yearlyIndex.jiekongIndex, StarKey.jiekong, StarType.adjective);
    addStar(yearlyIndex.jieshaAdjIndex, StarKey.jieshaAdj, StarType.adjective);
    addStar(yearlyIndex.dahaoAdjIndex, StarKey.dahao, StarType.adjective);
  }

  addStar(yearlyIndex.guchenIndex, StarKey.guchen, StarType.adjective);
  addStar(yearlyIndex.guasuIndex, StarKey.guasu, StarType.adjective);
  addStar(yearlyIndex.feilianIndex, StarKey.feilian, StarType.adjective);
  addStar(yearlyIndex.posuiIndex, StarKey.posui, StarType.adjective);
  addStar(monthlyIndex.tianxingIndex, StarKey.tianxing, StarType.adjective);
  addStar(monthlyIndex.yinshaIndex, StarKey.yinsha, StarType.adjective);
  addStar(yearlyIndex.tiankuIndex, StarKey.tianku, StarType.adjective);
  addStar(yearlyIndex.tianxuIndex, StarKey.tianxu, StarType.adjective);
  addStar(yearlyIndex.tianshiIndex, StarKey.tianshi, StarType.adjective);
  addStar(yearlyIndex.tianshangIndex, StarKey.tianshang, StarType.adjective);

  // Yearly Nianjie helper star.
  addStar(yearlyIndex.nianjieIndex, StarKey.nianjie, StarType.helper);

  return stars;
}
