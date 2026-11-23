import '../astro/palace_calc.dart';
import '../calendar/calendar_adapter.dart';
import '../calendar/day_boundary.dart';
import '../core/config.dart';
import '../core/index_math.dart';
import '../core/types.dart';
import '../data/branches_table.dart';
import '../data/locales/locale_registry.dart';
import 'location.dart';

/// Starting palace index (`0 = 寅 .. 11 = 丑`) for 长生12神 by [FiveElementsClass].
int getChangsheng12StartIndex(FiveElementsClass fiveElementsClass) {
  final branch = switch (fiveElementsClass) {
    FiveElementsClass.water2nd => EarthlyBranch.shen,
    FiveElementsClass.wood3rd => EarthlyBranch.hai,
    FiveElementsClass.metal4th => EarthlyBranch.si,
    FiveElementsClass.earth5th => EarthlyBranch.shen,
    FiveElementsClass.fire6th => EarthlyBranch.yin,
  };
  return earthlyBranchToPalaceIndex(branch);
}

/// Calculates 长生12神 ordered by palace index `0..11`.
List<String> getChangsheng12({
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
  final yearLunar = calendar.solarToLunar(
    boundary.year,
    boundary.month,
    boundary.day,
    timeIndex: 0,
    yearDivide: config.yearDivide,
    horoscopeDivide: config.horoscopeDivide,
  );
  final yearBranch = yearLunar.yearBranch;
  final soulAndBody = getSoulAndBody(
    year: year,
    month: month,
    day: day,
    timeIndex: timeIndex,
    fixLeap: fixLeap,
    config: config,
    calendar: calendar,
    from: from,
  );
  final fiveElements = getFiveElementsClass(
    soulAndBody.heavenlyStemOfSoul,
    soulAndBody.earthlyBranchOfSoul,
  );

  const stars = [
    StarKey.changsheng,
    StarKey.muyu,
    StarKey.guandai,
    StarKey.linguan,
    StarKey.diwang,
    StarKey.shuai,
    StarKey.bing,
    StarKey.si,
    StarKey.mu,
    StarKey.jue,
    StarKey.tai,
    StarKey.yang,
  ];
  final startIdx = getChangsheng12StartIndex(fiveElements);
  final isForward = gender.yinYang == earthlyBranchesMeta[yearBranch]!.yinYang;
  final result = List<String>.filled(12, '');

  for (var i = 0; i < stars.length; i++) {
    final idx = isForward ? fixIndex(i + startIdx) : fixIndex(startIdx - i);
    result[idx] = LocaleRegistry.translate(stars[i].key, config.language);
  }
  return result;
}

/// Calculates 博士12神 ordered by palace index `0..11`.
List<String> getBoShi12({
  required int year,
  required int month,
  required int day,
  required Gender gender,
  required ResolvedAstroConfig config,
  required LunarCalendarAdapter calendar,
}) {
  final yearLunar = calendar.solarToLunar(
    year,
    month,
    day,
    timeIndex: 0,
    yearDivide: config.yearDivide,
    horoscopeDivide: config.horoscopeDivide,
  );
  final yearStem = yearLunar.yearStem;
  final yearBranch = yearLunar.yearBranch;

  const stars = [
    StarKey.boshi,
    StarKey.lishi,
    StarKey.qinglong,
    StarKey.xiaohao,
    StarKey.jiangjun,
    StarKey.zhoushu,
    StarKey.faylian,
    StarKey.xishen,
    StarKey.bingfu,
    StarKey.dahao,
    StarKey.fubing,
    StarKey.guanfu,
  ];
  final luIndex = getLuYangTuoMaIndex(yearStem, yearBranch).luIndex;
  final isForward = gender.yinYang == earthlyBranchesMeta[yearBranch]!.yinYang;
  final result = List<String>.filled(12, '');

  for (var i = 0; i < stars.length; i++) {
    final idx = fixIndex(isForward ? luIndex + i : luIndex - i);
    result[idx] = LocaleRegistry.translate(stars[i].key, config.language);
  }
  return result;
}

/// Starting palace index for 将前12神 by year branch.
int getJiangqian12StartIndex(EarthlyBranch branch) {
  final startBranch = switch (branch) {
    EarthlyBranch.yin ||
    EarthlyBranch.wu ||
    EarthlyBranch.xu =>
      EarthlyBranch.wu,
    EarthlyBranch.shen ||
    EarthlyBranch.zi ||
    EarthlyBranch.chen =>
      EarthlyBranch.zi,
    EarthlyBranch.si ||
    EarthlyBranch.you ||
    EarthlyBranch.chou =>
      EarthlyBranch.you,
    EarthlyBranch.hai ||
    EarthlyBranch.mao ||
    EarthlyBranch.wei =>
      EarthlyBranch.mao,
  };
  return earthlyBranchToPalaceIndex(startBranch);
}

/// Calculates 岁前12神 and 将前12神 ordered by palace index `0..11`.
({List<String> suiqian12, List<String> jiangqian12}) getYearly12({
  required int year,
  required int month,
  required int day,
  required ResolvedAstroConfig config,
  required LunarCalendarAdapter calendar,
}) {
  final horoscopeYearLunar = calendar.solarToLunar(
    year,
    month,
    day,
    timeIndex: 0,
    yearDivide: config.horoscopeDivide,
    horoscopeDivide: config.horoscopeDivide,
  );
  final yearBranch = horoscopeYearLunar.yearBranch;

  final suiqianStars = config.algorithm == Algorithm.zhongzhou
      ? const [
          StarKey.suijian,
          StarKey.huiqi,
          StarKey.sangmen,
          StarKey.guansuo,
          StarKey.gwanfu,
          StarKey.xiaohao,
          StarKey.suipo,
          StarKey.longde,
          StarKey.baihu,
          StarKey.tiande,
          StarKey.diaoke,
          StarKey.bingfu,
        ]
      : const [
          StarKey.suijian,
          StarKey.huiqi,
          StarKey.sangmen,
          StarKey.guansuo,
          StarKey.gwanfu,
          StarKey.xiaohao,
          StarKey.dahao,
          StarKey.longde,
          StarKey.baihu,
          StarKey.tiande,
          StarKey.diaoke,
          StarKey.bingfu,
        ];

  final suiqian12 = List<String>.filled(12, '');
  final suiqianStart = earthlyBranchToPalaceIndex(yearBranch);
  for (var i = 0; i < suiqianStars.length; i++) {
    final idx = fixIndex(suiqianStart + i);
    suiqian12[idx] =
        LocaleRegistry.translate(suiqianStars[i].key, config.language);
  }

  const jiangqianStars = [
    StarKey.jiangxing,
    StarKey.panan,
    StarKey.suiyi,
    StarKey.xiishen,
    StarKey.huagai,
    StarKey.jiesha,
    StarKey.zhaisha,
    StarKey.tiansha,
    StarKey.zhibei,
    StarKey.xianchi,
    StarKey.yuesha,
    StarKey.wangshen,
  ];
  final jiangqian12 = List<String>.filled(12, '');
  final jqStart = getJiangqian12StartIndex(yearBranch);
  for (var i = 0; i < jiangqianStars.length; i++) {
    final idx = fixIndex(jqStart + i);
    jiangqian12[idx] =
        LocaleRegistry.translate(jiangqianStars[i].key, config.language);
  }

  return (suiqian12: suiqian12, jiangqian12: jiangqian12);
}
