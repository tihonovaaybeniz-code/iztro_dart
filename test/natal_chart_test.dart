import 'package:iztro_dart/iztro_dart.dart';
import 'package:test/test.dart';

void main() {
  setUp(Astro.resetConfig);
  tearDown(Astro.resetConfig);

  group('Natal chart generation (M2)', () {
    test('2000-8-16 female yin hour matches iztro@2.6.5 baseline', () {
      final chart = Astro.bySolar('2000-8-16', 2, Gender.female);

      expect(chart.solarDate, '2000-8-16');
      expect(chart.lunarDate, '二〇〇〇年七月十七');
      expect(chart.chineseDate, '庚辰 甲申 丙午 庚寅');
      expect(chart.time, '寅时');
      expect(chart.timeRange, '03:00~05:00');
      expect(chart.sign, '狮子座');
      expect(chart.zodiac, '龙');
      expect(chart.earthlyBranchOfSoulPalace, '午');
      expect(chart.earthlyBranchOfBodyPalace, '戌');
      expect(chart.soul, '破军');
      expect(chart.body, '文昌');
      expect(chart.fiveElementsClass, '木三局');
      expect(chart.palaces, hasLength(12));

      // Empty palace check (Parents palace at Wei has no major stars).
      final parents = chart.palace(PalaceName.parents)!;
      expect(parents.majorStars, isEmpty);

      // palaceAtBranch helper maps 子..亥 cleanly.
      expect(
          chart.palaceAtBranch(EarthlyBranch.wu).palaceName, PalaceName.soul);
      expect(chart.palaceAtBranch(EarthlyBranch.xu).isBodyPalace, isTrue);

      // JSON serialization produces plain Maps without cyclic references.
      final json = chart.toJson();
      expect(json['solarDate'], '2000-8-16');
      expect(json['palaces'], hasLength(12));
    });

    test('byLunar matches bySolar for regular and leap months', () {
      final fromLunar = Astro.byLunar('2000-7-17', 2, Gender.female);
      final fromSolar = Astro.bySolar('2000-8-16', 2, Gender.female);
      expect(fromLunar.toJson()['palaces'], fromSolar.toJson()['palaces']);

      // 2023 leap 2nd month: day 15 vs day 16 with fixLeap=true vs false.
      final leap15 = Astro.byLunar(
        '2023-2-15',
        4,
        Gender.male,
        isLeapMonth: true,
        fixLeap: true,
      );
      final leap16Fix = Astro.byLunar(
        '2023-2-16',
        4,
        Gender.male,
        isLeapMonth: true,
        fixLeap: true,
      );
      final leap16NoFix = Astro.byLunar(
        '2023-2-16',
        4,
        Gender.male,
        isLeapMonth: true,
        fixLeap: false,
      );
      expect(
        leap16Fix.earthlyBranchOfSoulPalace,
        isNot(equals(leap15.earthlyBranchOfSoulPalace)),
      );
      expect(
        leap16NoFix.earthlyBranchOfSoulPalace,
        equals(leap15.earthlyBranchOfSoulPalace),
      );
    });

    test('late Rat hour (timeIndex 12) respects dayDivide forward vs current',
        () {
      final forward = Astro.withOptions(
        const AstroOptions(
          dateStr: '2024-2-29',
          timeIndex: 12,
          gender: Gender.male,
          config: AstroConfig(dayDivide: DayDivideType.forward),
        ),
      );
      final current = Astro.withOptions(
        const AstroOptions(
          dateStr: '2024-2-29',
          timeIndex: 12,
          gender: Gender.male,
          config: AstroConfig(dayDivide: DayDivideType.current),
        ),
      );

      expect(forward.solarDate, '2024-2-29');
      expect(forward.time, '晚子时');
      expect(forward.timeRange, '23:00~00:00');
      expect(forward.rawDates.lunarDate.lunarDay, 21); // Advances to Mar 1 (廿一)

      expect(current.solarDate, '2024-2-29');
      expect(current.time, '晚子时');
      expect(current.rawDates.lunarDate.lunarDay, 20); // Stays on Feb 29 (二十)
    });

    test('zhongzhou school differs in soul star, suipo, and adjective stars',
        () {
      final def = Astro.bySolar('1990-5-15', 6, Gender.male);
      final zz = Astro.withOptions(
        const AstroOptions(
          dateStr: '1990-5-15',
          timeIndex: 6,
          gender: Gender.male,
          config: AstroConfig(algorithm: Algorithm.zhongzhou),
        ),
      );

      // Default uses Soul palace branch for 命主; Zhongzhou uses birth year branch.
      expect(def.soul, isNot(equals(zz.soul)));

      final defAdjNames =
          def.palaces.expand((p) => p.adjectiveStars).map((s) => s.key).toSet();
      final zzAdjNames =
          zz.palaces.expand((p) => p.adjectiveStars).map((s) => s.key).toSet();

      expect(defAdjNames.contains(StarKey.jielu), isTrue);
      expect(defAdjNames.contains(StarKey.kongwang), isTrue);
      expect(zzAdjNames.contains(StarKey.jiekong), isTrue);
      expect(zzAdjNames.contains(StarKey.jieshaAdj), isTrue);
      expect(zzAdjNames.contains(StarKey.longde), isTrue);
      expect(zz.palaces.map((p) => p.suiqian12), contains('岁破'));
    });

    test('earth and human chart rearrangements shift soul palace properly', () {
      final heaven = Astro.withOptions(
        const AstroOptions(
          dateStr: '2000-8-16',
          timeIndex: 2,
          gender: Gender.female,
          astroType: AstroType.heaven,
        ),
      );
      final earth = Astro.withOptions(
        const AstroOptions(
          dateStr: '2000-8-16',
          timeIndex: 2,
          gender: Gender.female,
          astroType: AstroType.earth,
        ),
      );
      final human = Astro.withOptions(
        const AstroOptions(
          dateStr: '2000-8-16',
          timeIndex: 2,
          gender: Gender.female,
          astroType: AstroType.human,
        ),
      );

      // Heaven body palace is 戌 -> Earth soul palace becomes 戌.
      expect(earth.earthlyBranchOfSoulPalace, '戌');
      expect(earth.palace(PalaceName.soul)!.isBodyPalace, isTrue);

      // Heaven spirit palace (福德) is 申 -> Human soul palace becomes 申.
      expect(human.earthlyBranchOfSoulPalace,
          heaven.palace(PalaceName.spirit)!.earthlyBranch);
      expect(human.earthlyBranchOfBodyPalace, heaven.earthlyBranchOfBodyPalace);
    });

    test('supports all 6 languages and per-chart config isolation', () {
      final charts = <AstroLanguage, FunctionalAstrolabe>{
        for (final lang in AstroLanguage.values)
          lang: Astro.bySolar('2000-8-16', 2, Gender.female, language: lang),
      };

      expect(charts[AstroLanguage.zhCN]!.fiveElementsClass, '木三局');
      expect(charts[AstroLanguage.zhTW]!.fiveElementsClass, '木三局');
      expect(charts[AstroLanguage.enUS]!.fiveElementsClass, 'wood 3rd');
      expect(charts[AstroLanguage.jaJP]!.fiveElementsClass, '木の三局');
      expect(charts[AstroLanguage.koKR]!.fiveElementsClass, '목삼국');
      expect(charts[AstroLanguage.viVN]!.fiveElementsClass, 'Mộc Tam Cục');

      // Mutating global config later must NOT affect existing charts.
      Astro.config(const AstroConfig(language: AstroLanguage.enUS));
      expect(charts[AstroLanguage.zhCN]!.fiveElementsClass, '木三局');
      expect(charts[AstroLanguage.zhCN]!.palace(PalaceName.soul)!.name, '命宫');
    });

    test('byTrueSolarTime integrates TST calculation with chart output', () {
      final result = Astro.byTrueSolarTime(
        DateTime(1988, 7, 15, 12, 30),
        longitude: 87.6168,
        utcOffsetMinutes: 480,
        gender: Gender.male,
      );

      expect(result.trueSolarTime.dstCorrectionMinutes, -60.0);
      expect(result.trueSolarTime.effectiveSolarDateStr, '1988-7-15');
      expect(result.astrolabe.timeIndex, result.trueSolarTime.timeIndex);
      expect(result.astrolabe.palaces, hasLength(12));
    });

    test('static helper functions match chart values', () {
      expect(Astro.getSignBySolarDate('2000-8-16'), '狮子座');
      expect(Astro.getSignByLunarDate('2000-7-17'), '狮子座');
      expect(Astro.getZodiacBySolarDate('2000-8-16'), '龙');
      expect(Astro.getMajorStarBySolarDate('2000-8-16', 2), '紫微');
      expect(Astro.getMajorStarByLunarDate('2000-7-17', 2), '紫微');
      expect(Astro.getMajorStarBySolarDate('1987-05-16', 7), '天机,天梁');
      expect(Astro.getMajorStarBySolarDate('2023-4-7', 0), '贪狼');
      expect(
        Astro.getMajorStarBySolarDate('2023-4-7', 0, fixLeap: false),
        '紫微,贪狼',
      );
      expect(
        Astro.getMajorStarBySolarDate(
          '2023-4-7',
          0,
          language: AstroLanguage.koKR,
        ),
        '탐랑',
      );
      expect(
        Astro.getMajorStarByLunarDate('2023-2-17', 0, isLeapMonth: true),
        '贪狼',
      );
      // Empty soul palace borrows opposite palace stars.
      expect(Astro.getMajorStarBySolarDate('2023-1-1', 0), isNotEmpty);
    });
  });
}
