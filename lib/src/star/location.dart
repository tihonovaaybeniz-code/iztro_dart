import '../astro/palace_calc.dart';
import '../calendar/calendar_adapter.dart';
import '../calendar/day_boundary.dart';
import '../core/config.dart';
import '../core/index_math.dart';
import '../core/types.dart';

/// Resolves the 0-based lunar month palace offset (`0 = 正月/寅 .. 11 = 腊月/丑`),
/// accounting for [fixLeap] (days 16+ of a leap month advance by 1),
/// matching `iztro/src/utils/index.ts#fixLunarMonthIndex`.
int fixLunarMonthIndex({
  required LunarDateInfo lunarInfo,
  required bool fixLeap,
}) {
  final needToAdd = lunarInfo.isLeapMonth && fixLeap && lunarInfo.lunarDay > 15;
  return fixIndex(lunarInfo.lunarMonth - 1 + (needToAdd ? 1 : 0));
}

/// Resolves lunar day offset (`0`-based unless unnormalized late Rat `>= 12`),
/// matching `iztro/src/utils/index.ts#fixLunarDayIndex`.
int fixLunarDayIndex(int lunarDay, int timeIndex) {
  return timeIndex >= 12 ? lunarDay : lunarDay - 1;
}

/// Calculates Ziwei (紫微) and Tianfu (天府) palace indices (`0 = 寅 .. 11 = 丑`),
/// matching `iztro/src/star/location.ts#getStartIndex`.
({int ziweiIndex, int tianfuIndex}) getStartIndex({
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
  final soulAndBody = getSoulAndBody(
    year: boundary.year,
    month: boundary.month,
    day: boundary.day,
    timeIndex: boundary.timeIndex,
    fixLeap: fixLeap,
    config: config,
    calendar: calendar,
  );

  final baseStem = from?.heavenlyStem ?? soulAndBody.heavenlyStemOfSoul;
  final baseBranch = from?.earthlyBranch ?? soulAndBody.earthlyBranchOfSoul;
  final fiveElements = getFiveElementsClass(baseStem, baseBranch);
  final fiveElementsValue = fiveElements.value;

  var remainder = -1;
  var quotient = 0;
  var offset = -1;

  do {
    offset++;
    final divisor = lunarInfo.lunarDay + offset;
    quotient = divisor ~/ fiveElementsValue;
    remainder = divisor % fiveElementsValue;
  } while (remainder != 0);

  quotient %= 12;
  var ziweiIndex = quotient - 1;
  if (offset % 2 == 0) {
    ziweiIndex += offset;
  } else {
    ziweiIndex -= offset;
  }
  ziweiIndex = fixIndex(ziweiIndex);
  final tianfuIndex = fixIndex(12 - ziweiIndex);

  return (ziweiIndex: ziweiIndex, tianfuIndex: tianfuIndex);
}

/// Calculates 禄存、擎羊、陀罗、天马 indices by stem and branch,
/// matching `iztro/src/star/location.ts#getLuYangTuoMaIndex`.
({int luIndex, int maIndex, int yangIndex, int tuoIndex}) getLuYangTuoMaIndex(
  HeavenlyStem stem,
  EarthlyBranch branch,
) {
  final maBranch = switch (branch) {
    EarthlyBranch.yin ||
    EarthlyBranch.wu ||
    EarthlyBranch.xu =>
      EarthlyBranch.shen,
    EarthlyBranch.shen ||
    EarthlyBranch.zi ||
    EarthlyBranch.chen =>
      EarthlyBranch.yin,
    EarthlyBranch.si ||
    EarthlyBranch.you ||
    EarthlyBranch.chou =>
      EarthlyBranch.hai,
    EarthlyBranch.hai ||
    EarthlyBranch.mao ||
    EarthlyBranch.wei =>
      EarthlyBranch.si,
  };

  final luBranch = switch (stem) {
    HeavenlyStem.jia => EarthlyBranch.yin,
    HeavenlyStem.yi => EarthlyBranch.mao,
    HeavenlyStem.bing || HeavenlyStem.wu => EarthlyBranch.si,
    HeavenlyStem.ding || HeavenlyStem.ji => EarthlyBranch.wu,
    HeavenlyStem.geng => EarthlyBranch.shen,
    HeavenlyStem.xin => EarthlyBranch.you,
    HeavenlyStem.ren => EarthlyBranch.hai,
    HeavenlyStem.gui => EarthlyBranch.zi,
  };

  final luIndex = earthlyBranchToPalaceIndex(luBranch);
  final maIndex = earthlyBranchToPalaceIndex(maBranch);
  return (
    luIndex: luIndex,
    maIndex: maIndex,
    yangIndex: fixIndex(luIndex + 1),
    tuoIndex: fixIndex(luIndex - 1),
  );
}

/// Calculates 天魁 and 天钺 palace indices by year stem.
({int kuiIndex, int yueIndex}) getKuiYueIndex(HeavenlyStem stem) {
  final (kuiBranch, yueBranch) = switch (stem) {
    HeavenlyStem.jia || HeavenlyStem.wu || HeavenlyStem.geng => (
        EarthlyBranch.chou,
        EarthlyBranch.wei
      ),
    HeavenlyStem.yi || HeavenlyStem.ji => (
        EarthlyBranch.zi,
        EarthlyBranch.shen
      ),
    HeavenlyStem.xin => (EarthlyBranch.wu, EarthlyBranch.yin),
    HeavenlyStem.bing || HeavenlyStem.ding => (
        EarthlyBranch.hai,
        EarthlyBranch.you
      ),
    HeavenlyStem.ren || HeavenlyStem.gui => (
        EarthlyBranch.mao,
        EarthlyBranch.si
      ),
  };

  return (
    kuiIndex: earthlyBranchToPalaceIndex(kuiBranch),
    yueIndex: earthlyBranchToPalaceIndex(yueBranch),
  );
}

/// Calculates 左辅 and 右弼 palace indices by 1-based lunar month (`monthIndex + 1`).
({int zuoIndex, int youIndex}) getZuoYouIndex(int lunarMonth) {
  final zuoIndex = fixIndex(
    earthlyBranchToPalaceIndex(EarthlyBranch.chen) + (lunarMonth - 1),
  );
  final youIndex = fixIndex(
    earthlyBranchToPalaceIndex(EarthlyBranch.xu) - (lunarMonth - 1),
  );
  return (zuoIndex: zuoIndex, youIndex: youIndex);
}

/// Calculates 文昌 and 文曲 palace indices by hour [timeIndex].
({int changIndex, int quIndex}) getChangQuIndex(int timeIndex) {
  final fixedTime = fixIndex(timeIndex);
  final changIndex = fixIndex(
    earthlyBranchToPalaceIndex(EarthlyBranch.xu) - fixedTime,
  );
  final quIndex = fixIndex(
    earthlyBranchToPalaceIndex(EarthlyBranch.chen) + fixedTime,
  );
  return (changIndex: changIndex, quIndex: quIndex);
}

/// Calculates daily star indices: 三台, 八座, 恩光, 天贵.
({int santaiIndex, int bazuoIndex, int enguangIndex, int tianguiIndex})
    getDailyStarIndex({
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
  final zuoYou = getZuoYouIndex(monthIndex + 1);
  final changQu = getChangQuIndex(boundary.timeIndex);
  final dayIndex = fixLunarDayIndex(lunarInfo.lunarDay, boundary.timeIndex);

  return (
    santaiIndex: fixIndex((zuoYou.zuoIndex + dayIndex) % 12),
    bazuoIndex: fixIndex((zuoYou.youIndex - dayIndex) % 12),
    enguangIndex: fixIndex(((changQu.changIndex + dayIndex) % 12) - 1),
    tianguiIndex: fixIndex(((changQu.quIndex + dayIndex) % 12) - 1),
  );
}

/// Calculates timely star indices: 台辅, 封诰.
({int taifuIndex, int fenggaoIndex}) getTimelyStarIndex(int timeIndex) {
  final fixed = fixIndex(timeIndex);
  return (
    taifuIndex: fixIndex(earthlyBranchToPalaceIndex(EarthlyBranch.wu) + fixed),
    fenggaoIndex:
        fixIndex(earthlyBranchToPalaceIndex(EarthlyBranch.yin) + fixed),
  );
}

/// Calculates 地空 and 地劫 indices by hour [timeIndex].
({int kongIndex, int jieIndex}) getKongJieIndex(int timeIndex) {
  final fixed = fixIndex(timeIndex);
  final haiIndex = earthlyBranchToPalaceIndex(EarthlyBranch.hai);
  return (
    kongIndex: fixIndex(haiIndex - fixed),
    jieIndex: fixIndex(haiIndex + fixed),
  );
}

/// Calculates 火星 and 铃星 indices by year branch and hour [timeIndex].
({int huoIndex, int lingIndex}) getHuoLingIndex(
  EarthlyBranch branch,
  int timeIndex,
) {
  final fixedTime = fixIndex(timeIndex);
  final (huoBase, lingBase) = switch (branch) {
    EarthlyBranch.yin || EarthlyBranch.wu || EarthlyBranch.xu => (
        EarthlyBranch.chou,
        EarthlyBranch.mao
      ),
    EarthlyBranch.shen || EarthlyBranch.zi || EarthlyBranch.chen => (
        EarthlyBranch.yin,
        EarthlyBranch.xu
      ),
    EarthlyBranch.si || EarthlyBranch.you || EarthlyBranch.chou => (
        EarthlyBranch.mao,
        EarthlyBranch.xu
      ),
    EarthlyBranch.hai || EarthlyBranch.wei || EarthlyBranch.mao => (
        EarthlyBranch.you,
        EarthlyBranch.xu
      ),
  };

  return (
    huoIndex: fixIndex(earthlyBranchToPalaceIndex(huoBase) + fixedTime),
    lingIndex: fixIndex(earthlyBranchToPalaceIndex(lingBase) + fixedTime),
  );
}

/// Calculates 红鸾 and 天喜 palace indices by year branch.
({int hongluanIndex, int tianxiIndex}) getLuanXiIndex(EarthlyBranch branch) {
  final hongluanIndex = fixIndex(
    earthlyBranchToPalaceIndex(EarthlyBranch.mao) - branch.index,
  );
  return (
    hongluanIndex: hongluanIndex,
    tianxiIndex: fixIndex(hongluanIndex + 6),
  );
}

/// Calculates 华盖 and 咸池 palace indices by branch.
({int huagaiIndex, int xianchiIndex}) getHuagaiXianchiIndex(
  EarthlyBranch branch,
) {
  final (hgBranch, xcBranch) = switch (branch) {
    EarthlyBranch.yin || EarthlyBranch.wu || EarthlyBranch.xu => (
        EarthlyBranch.xu,
        EarthlyBranch.mao
      ),
    EarthlyBranch.shen || EarthlyBranch.zi || EarthlyBranch.chen => (
        EarthlyBranch.chen,
        EarthlyBranch.you
      ),
    EarthlyBranch.si || EarthlyBranch.you || EarthlyBranch.chou => (
        EarthlyBranch.chou,
        EarthlyBranch.wu
      ),
    EarthlyBranch.hai || EarthlyBranch.wei || EarthlyBranch.mao => (
        EarthlyBranch.wei,
        EarthlyBranch.zi
      ),
  };
  return (
    huagaiIndex: earthlyBranchToPalaceIndex(hgBranch),
    xianchiIndex: earthlyBranchToPalaceIndex(xcBranch),
  );
}

/// Calculates 孤辰 and 寡宿 palace indices by branch.
({int guchenIndex, int guasuIndex}) getGuGuaIndex(EarthlyBranch branch) {
  final (guBranch, guaBranch) = switch (branch) {
    EarthlyBranch.yin || EarthlyBranch.mao || EarthlyBranch.chen => (
        EarthlyBranch.si,
        EarthlyBranch.chou
      ),
    EarthlyBranch.si || EarthlyBranch.wu || EarthlyBranch.wei => (
        EarthlyBranch.shen,
        EarthlyBranch.chen
      ),
    EarthlyBranch.shen || EarthlyBranch.you || EarthlyBranch.xu => (
        EarthlyBranch.hai,
        EarthlyBranch.wei
      ),
    EarthlyBranch.hai || EarthlyBranch.zi || EarthlyBranch.chou => (
        EarthlyBranch.yin,
        EarthlyBranch.xu
      ),
  };
  return (
    guchenIndex: earthlyBranchToPalaceIndex(guBranch),
    guasuIndex: earthlyBranchToPalaceIndex(guaBranch),
  );
}

/// Calculates Zhongzhou adjective star 劫杀 index by year branch.
int getJieshaAdjIndex(EarthlyBranch branch) {
  return switch (branch) {
    EarthlyBranch.shen || EarthlyBranch.zi || EarthlyBranch.chen => 3,
    EarthlyBranch.hai || EarthlyBranch.mao || EarthlyBranch.wei => 6,
    EarthlyBranch.yin || EarthlyBranch.wu || EarthlyBranch.xu => 9,
    EarthlyBranch.si || EarthlyBranch.you || EarthlyBranch.chou => 0,
  };
}

/// Calculates Zhongzhou adjective star 大耗 index by year branch.
int getDahaoIndex(EarthlyBranch branch) {
  const matched = [
    EarthlyBranch.wei,
    EarthlyBranch.wu,
    EarthlyBranch.you,
    EarthlyBranch.shen,
    EarthlyBranch.hai,
    EarthlyBranch.xu,
    EarthlyBranch.chou,
    EarthlyBranch.zi,
    EarthlyBranch.mao,
    EarthlyBranch.yin,
    EarthlyBranch.si,
    EarthlyBranch.chen,
  ];
  return fixIndex(matched[branch.index].index - 2);
}

/// Calculates 天使 and 天伤 palace indices, accounting for `zhongzhou` rule.
({int tianshangIndex, int tianshiIndex}) getTianshiTianshangIndex({
  required Gender gender,
  required EarthlyBranch yearBranch,
  required int soulIndex,
  required Algorithm algorithm,
}) {
  final branchYinYang = yearBranch.index % 2; // 0 = yang, 1 = yin
  final genderYinYang = gender == Gender.male ? 0 : 1;
  final sameYinYang = branchYinYang == genderYinYang;

  var tianshangIndex = fixIndex(PalaceName.friends.index + soulIndex);
  var tianshiIndex = fixIndex(PalaceName.health.index + soulIndex);

  if (algorithm == Algorithm.zhongzhou && !sameYinYang) {
    final tmp = tianshiIndex;
    tianshiIndex = tianshangIndex;
    tianshangIndex = tmp;
  }

  return (tianshangIndex: tianshangIndex, tianshiIndex: tianshiIndex);
}

/// Calculates 年解 index by year branch.
int getNianjieIndex(EarthlyBranch branch) {
  const branches = [
    EarthlyBranch.xu,
    EarthlyBranch.you,
    EarthlyBranch.shen,
    EarthlyBranch.wei,
    EarthlyBranch.wu,
    EarthlyBranch.si,
    EarthlyBranch.chen,
    EarthlyBranch.mao,
    EarthlyBranch.yin,
    EarthlyBranch.chou,
    EarthlyBranch.zi,
    EarthlyBranch.hai,
  ];
  return earthlyBranchToPalaceIndex(branches[branch.index]);
}

/// Calculates all year-based adjective star indices (using `horoscopeDivide`
/// for the year pillar, matching `iztro@2.6.5#getYearlyStarIndex`).
({
  int xianchiIndex,
  int huagaiIndex,
  int guchenIndex,
  int guasuIndex,
  int tiancaiIndex,
  int tianshouIndex,
  int tianchuIndex,
  int posuiIndex,
  int feilianIndex,
  int longchiIndex,
  int fenggeIndex,
  int tiankuIndex,
  int tianxuIndex,
  int tianguanIndex,
  int tianfuIndex,
  int tiandeIndex,
  int yuedeIndex,
  int tiankongIndex,
  int jieluIndex,
  int kongwangIndex,
  int xunkongIndex,
  int tianshangIndex,
  int tianshiIndex,
  int jiekongIndex,
  int jieshaAdjIndex,
  int nianjieIndex,
  int dahaoAdjIndex,
}) getYearlyStarIndex({
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
  final horoscopeYearLunar = calendar.solarToLunar(
    boundary.year,
    boundary.month,
    boundary.day,
    timeIndex: boundary.timeIndex,
    yearDivide: config.horoscopeDivide,
    horoscopeDivide: config.horoscopeDivide,
  );
  final soulAndBody = getSoulAndBody(
    year: boundary.year,
    month: boundary.month,
    day: boundary.day,
    timeIndex: boundary.timeIndex,
    fixLeap: fixLeap,
    config: config,
    calendar: calendar,
  );

  final stem = horoscopeYearLunar.yearStem;
  final branch = horoscopeYearLunar.yearBranch;

  final huagaiXianchi = getHuagaiXianchiIndex(branch);
  final guGua = getGuGuaIndex(branch);
  final tiancaiIndex = fixIndex(soulAndBody.soulIndex + branch.index);
  final tianshouIndex = fixIndex(soulAndBody.bodyIndex + branch.index);

  const tianchuBranches = [
    EarthlyBranch.si,
    EarthlyBranch.wu,
    EarthlyBranch.zi,
    EarthlyBranch.si,
    EarthlyBranch.wu,
    EarthlyBranch.shen,
    EarthlyBranch.yin,
    EarthlyBranch.wu,
    EarthlyBranch.you,
    EarthlyBranch.hai,
  ];
  final tianchuIndex = earthlyBranchToPalaceIndex(tianchuBranches[stem.index]);

  const posuiBranches = [
    EarthlyBranch.si,
    EarthlyBranch.chou,
    EarthlyBranch.you,
  ];
  final posuiIndex =
      earthlyBranchToPalaceIndex(posuiBranches[branch.index % 3]);

  const feilianBranches = [
    EarthlyBranch.shen,
    EarthlyBranch.you,
    EarthlyBranch.xu,
    EarthlyBranch.si,
    EarthlyBranch.wu,
    EarthlyBranch.wei,
    EarthlyBranch.yin,
    EarthlyBranch.mao,
    EarthlyBranch.chen,
    EarthlyBranch.hai,
    EarthlyBranch.zi,
    EarthlyBranch.chou,
  ];
  final feilianIndex =
      earthlyBranchToPalaceIndex(feilianBranches[branch.index]);

  final longchiIndex =
      fixIndex(earthlyBranchToPalaceIndex(EarthlyBranch.chen) + branch.index);
  final fenggeIndex =
      fixIndex(earthlyBranchToPalaceIndex(EarthlyBranch.xu) - branch.index);
  final tiankuIndex =
      fixIndex(earthlyBranchToPalaceIndex(EarthlyBranch.wu) - branch.index);
  final tianxuIndex =
      fixIndex(earthlyBranchToPalaceIndex(EarthlyBranch.wu) + branch.index);

  const tianguanBranches = [
    EarthlyBranch.wei,
    EarthlyBranch.chen,
    EarthlyBranch.si,
    EarthlyBranch.yin,
    EarthlyBranch.mao,
    EarthlyBranch.you,
    EarthlyBranch.hai,
    EarthlyBranch.you,
    EarthlyBranch.xu,
    EarthlyBranch.wu,
  ];
  final tianguanIndex =
      earthlyBranchToPalaceIndex(tianguanBranches[stem.index]);

  const tianfuBranches = [
    EarthlyBranch.you,
    EarthlyBranch.shen,
    EarthlyBranch.zi,
    EarthlyBranch.hai,
    EarthlyBranch.mao,
    EarthlyBranch.yin,
    EarthlyBranch.wu,
    EarthlyBranch.si,
    EarthlyBranch.wu,
    EarthlyBranch.si,
  ];
  final tianfuIndex = earthlyBranchToPalaceIndex(tianfuBranches[stem.index]);

  final tiandeIndex =
      fixIndex(earthlyBranchToPalaceIndex(EarthlyBranch.you) + branch.index);
  final yuedeIndex =
      fixIndex(earthlyBranchToPalaceIndex(EarthlyBranch.si) + branch.index);
  final tiankongIndex = fixIndex(earthlyBranchToPalaceIndex(branch) + 1);

  const jieluBranches = [
    EarthlyBranch.shen,
    EarthlyBranch.wu,
    EarthlyBranch.chen,
    EarthlyBranch.yin,
    EarthlyBranch.zi,
  ];
  final jieluIndex = earthlyBranchToPalaceIndex(jieluBranches[stem.index % 5]);

  const kongwangBranches = [
    EarthlyBranch.you,
    EarthlyBranch.wei,
    EarthlyBranch.si,
    EarthlyBranch.mao,
    EarthlyBranch.chou,
  ];
  final kongwangIndex =
      earthlyBranchToPalaceIndex(kongwangBranches[stem.index % 5]);

  var xunkongIndex = fixIndex(
    earthlyBranchToPalaceIndex(branch) +
        HeavenlyStem.gui.index -
        stem.index +
        1,
  );
  final yinyang = branch.index % 2;
  if (yinyang != xunkongIndex % 2) {
    xunkongIndex = fixIndex(xunkongIndex + 1);
  }

  final jiekongIndex = yinyang == 0 ? jieluIndex : kongwangIndex;
  final jieshaAdjIndex = getJieshaAdjIndex(branch);
  final nianjieIndex = getNianjieIndex(branch);
  final dahaoAdjIndex = getDahaoIndex(branch);
  final tianshiTianshang = getTianshiTianshangIndex(
    gender: gender,
    yearBranch: branch,
    soulIndex: soulAndBody.soulIndex,
    algorithm: config.algorithm,
  );

  return (
    xianchiIndex: huagaiXianchi.xianchiIndex,
    huagaiIndex: huagaiXianchi.huagaiIndex,
    guchenIndex: guGua.guchenIndex,
    guasuIndex: guGua.guasuIndex,
    tiancaiIndex: tiancaiIndex,
    tianshouIndex: tianshouIndex,
    tianchuIndex: tianchuIndex,
    posuiIndex: posuiIndex,
    feilianIndex: feilianIndex,
    longchiIndex: longchiIndex,
    fenggeIndex: fenggeIndex,
    tiankuIndex: tiankuIndex,
    tianxuIndex: tianxuIndex,
    tianguanIndex: tianguanIndex,
    tianfuIndex: tianfuIndex,
    tiandeIndex: tiandeIndex,
    yuedeIndex: yuedeIndex,
    tiankongIndex: tiankongIndex,
    jieluIndex: jieluIndex,
    kongwangIndex: kongwangIndex,
    xunkongIndex: xunkongIndex,
    tianshangIndex: tianshiTianshang.tianshangIndex,
    tianshiIndex: tianshiTianshang.tianshiIndex,
    jiekongIndex: jiekongIndex,
    jieshaAdjIndex: jieshaAdjIndex,
    nianjieIndex: nianjieIndex,
    dahaoAdjIndex: dahaoAdjIndex,
  );
}

/// Calculates monthly star indices: 解神 (月解), 天姚, 天刑, 阴煞, 天月, 天巫.
({
  int yuejieIndex,
  int tianyaoIndex,
  int tianxingIndex,
  int yinshaIndex,
  int tianyueIndex,
  int tianwuIndex,
}) getMonthlyStarIndex({
  required LunarDateInfo lunarInfo,
  required bool fixLeap,
}) {
  final monthIndex = fixLunarMonthIndex(lunarInfo: lunarInfo, fixLeap: fixLeap);

  const jieshenBranches = [
    EarthlyBranch.shen,
    EarthlyBranch.xu,
    EarthlyBranch.zi,
    EarthlyBranch.yin,
    EarthlyBranch.chen,
    EarthlyBranch.wu,
  ];
  final jieshenIndex =
      earthlyBranchToPalaceIndex(jieshenBranches[monthIndex ~/ 2]);

  final tianyaoIndex =
      fixIndex(earthlyBranchToPalaceIndex(EarthlyBranch.chou) + monthIndex);
  final tianxingIndex =
      fixIndex(earthlyBranchToPalaceIndex(EarthlyBranch.you) + monthIndex);

  const yinshaBranches = [
    EarthlyBranch.yin,
    EarthlyBranch.zi,
    EarthlyBranch.xu,
    EarthlyBranch.shen,
    EarthlyBranch.wu,
    EarthlyBranch.chen,
  ];
  final yinshaIndex =
      earthlyBranchToPalaceIndex(yinshaBranches[monthIndex % 6]);

  const tianyueBranches = [
    EarthlyBranch.xu,
    EarthlyBranch.si,
    EarthlyBranch.chen,
    EarthlyBranch.yin,
    EarthlyBranch.wei,
    EarthlyBranch.mao,
    EarthlyBranch.hai,
    EarthlyBranch.wei,
    EarthlyBranch.yin,
    EarthlyBranch.wu,
    EarthlyBranch.xu,
    EarthlyBranch.yin,
  ];
  final tianyueIndex = earthlyBranchToPalaceIndex(tianyueBranches[monthIndex]);

  const tianwuBranches = [
    EarthlyBranch.si,
    EarthlyBranch.shen,
    EarthlyBranch.yin,
    EarthlyBranch.hai,
  ];
  final tianwuIndex =
      earthlyBranchToPalaceIndex(tianwuBranches[monthIndex % 4]);

  return (
    yuejieIndex: jieshenIndex,
    tianyaoIndex: tianyaoIndex,
    tianxingIndex: tianxingIndex,
    yinshaIndex: yinshaIndex,
    tianyueIndex: tianyueIndex,
    tianwuIndex: tianwuIndex,
  );
}

/// Calculates horoscope 流昌 / 流曲 indices by Heavenly Stem.
({int changIndex, int quIndex}) getChangQuIndexByHeavenlyStem(
  HeavenlyStem stem,
) {
  final (changBranch, quBranch) = switch (stem) {
    HeavenlyStem.jia => (EarthlyBranch.si, EarthlyBranch.you),
    HeavenlyStem.yi => (EarthlyBranch.wu, EarthlyBranch.shen),
    HeavenlyStem.bing || HeavenlyStem.wu => (
        EarthlyBranch.shen,
        EarthlyBranch.wu
      ),
    HeavenlyStem.ding || HeavenlyStem.ji => (
        EarthlyBranch.you,
        EarthlyBranch.si
      ),
    HeavenlyStem.geng => (EarthlyBranch.hai, EarthlyBranch.mao),
    HeavenlyStem.xin => (EarthlyBranch.zi, EarthlyBranch.yin),
    HeavenlyStem.ren => (EarthlyBranch.yin, EarthlyBranch.zi),
    HeavenlyStem.gui => (EarthlyBranch.mao, EarthlyBranch.hai),
  };

  return (
    changIndex: earthlyBranchToPalaceIndex(changBranch),
    quIndex: earthlyBranchToPalaceIndex(quBranch),
  );
}
