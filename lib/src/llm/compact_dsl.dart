import '../astro/functional_astrolabe.dart';
import '../astro/functional_horoscope.dart';
import '../astro/functional_palace.dart';
import '../astro/horoscope_calc.dart';
import '../core/index_math.dart';
import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import '../data/stars_meta.dart';
import '../star/functional_star.dart';
import 'chart_dsl.dart';
import 'pattern_detector.dart';

/// Renders a high-density, token-efficient plain-text DSL representation of a
/// [FunctionalAstrolabe] while preserving all anti-hallucination data (stars,
/// brightness, natal/decadal/yearly mutagens, borrowed stars, flying mutagens,
/// self-mutagens, active horoscope, and detected patterns).
abstract final class ChartCompactDsl {
  /// Renders compact Chinese-first DSL text for LLM consumption.
  static String render(
    FunctionalAstrolabe astrolabe, {
    DateTime? targetDate,
    int? timeIndex,
    List<PalaceName>? focusPalaces,
  }) {
    final effectiveTarget = targetDate ?? DateTime.now();
    final horo = astrolabe.horoscope(effectiveTarget, timeIndex);
    final cfg = astrolabe.configSnapshot;
    final lang = cfg.language;
    final fingerprint = ChartDsl.fingerprintOf(astrolabe);
    final patterns = PatternDetector.detect(astrolabe);
    final focusSet = focusPalaces?.toSet() ?? const <PalaceName>{};

    final buf = StringBuffer()
      ..writeln('# 紫微斗数命盘紧凑DSL (iztro@2.6.5口径)')
      ..writeln(
        '指纹:$fingerprint | 性别:${astrolabe.gender} | 公历:${astrolabe.solarDate} | '
        '农历:${astrolabe.lunarDate} | 四柱:${astrolabe.chineseDate}',
      )
      ..writeln(
        '时辰:${astrolabe.time}(${astrolabe.timeRange}) | 五行局:${astrolabe.fiveElementsClass} | '
        '命主:${astrolabe.soul} | 身主:${astrolabe.body} | '
        '命宫支:${astrolabe.earthlyBranchOfSoulPalace} | 身宫支:${astrolabe.earthlyBranchOfBodyPalace}',
      )
      ..writeln(
        '配置:流派=${cfg.algorithm.key},盘型=${astrolabe.astroType.key},'
        '年界=${cfg.yearDivide.key},运限界=${cfg.horoscopeDivide.key},'
        '虚岁界=${cfg.ageDivide.key},子时界=${cfg.dayDivide.key}',
      )
      ..writeln()
      ..writeln('## 当前运限 (${horo.solarDate} / ${horo.lunarDate})')
      ..writeln(
        '虚岁:${horo.age.nominalAge}${horo.isChildhood ? "(童限)" : ""} | '
        '大限:${horo.decadal.heavenlyStem}${horo.decadal.earthlyBranch}(${horo.decadal.name}) '
        '四化[禄:${horo.decadal.mutagen[0]},权:${horo.decadal.mutagen[1]},'
        '科:${horo.decadal.mutagen[2]},忌:${horo.decadal.mutagen[3]}]',
      )
      ..writeln(
        '流年:${horo.yearly.heavenlyStem}${horo.yearly.earthlyBranch} '
        '四化[禄:${horo.yearly.mutagen[0]},权:${horo.yearly.mutagen[1]},'
        '科:${horo.yearly.mutagen[2]},忌:${horo.yearly.mutagen[3]}] | '
        '流月:${horo.monthly.heavenlyStem}${horo.monthly.earthlyBranch} | '
        '流日:${horo.daily.heavenlyStem}${horo.daily.earthlyBranch} | '
        '流时:${horo.hourly.heavenlyStem}${horo.hourly.earthlyBranch}',
      )
      ..writeln(
        '叠宫(运->命): 大限命宫落[${astrolabe.palace(horo.decadal.index)?.name ?? "-"}] | '
        '流年命宫落[${astrolabe.palace(horo.yearly.index)?.name ?? "-"}] | '
        '小限落[${astrolabe.palace(horo.age.index)?.name ?? "-"}]',
      )
      ..writeln()
      ..writeln('## 格局预检 (${patterns.length}项)');

    if (patterns.isEmpty) {
      buf.writeln('- 未命中预设经典格局，按各宫星曜组合与四化飞星论。');
    } else {
      for (final p in patterns) {
        final status = p.isClean ? '成格' : '有破格(${p.breakFactors.join("、")})';
        buf.writeln('- ${p.name} [$status] 依据:${p.evidence.join("、")}');
      }
    }

    buf
      ..writeln()
      ..writeln('## 十二宫星曜与飞星 (0=寅..11=丑)');

    for (final p in astrolabe.palaces) {
      final isFocus = focusSet.contains(p.palaceName);
      final tags = <String>[
        if (isFocus) '★焦点',
        if (p.isBodyPalace) '身宫',
        if (p.isOriginalPalace) '来因宫',
      ];
      final tagStr = tags.isNotEmpty ? '[${tags.join(",")}]' : '';
      final decadalName = _scopePalaceLabel(horo.decadal, p.index);
      final yearlyName = _scopePalaceLabel(horo.yearly, p.index);

      buf.write(
        '${p.index}.${p.name}(${p.heavenlyStem}${p.earthlyBranch})$tagStr '
        '大限${p.decadal.startAge}-${p.decadal.endAge}岁 '
        '[运:$decadalName/流:$yearlyName] | ',
      );

      if (p.isEmpty()) {
        final opp = astrolabe.palace(fixIndex(p.index + 6))!;
        final borrowedText = opp.majorStars.isEmpty
            ? '无'
            : opp.majorStars.map((s) => _formatStar(s, horo, lang)).join(' ');
        buf.write('主星:空宫(借${opp.name}:$borrowedText)');
      } else {
        final majorText =
            p.majorStars.map((s) => _formatStar(s, horo, lang)).join(' ');
        buf.write('主星:$majorText');
      }

      if (p.minorStars.isNotEmpty) {
        final minorText =
            p.minorStars.map((s) => _formatStar(s, horo, lang)).join(' ');
        buf.write(' | 辅煞:$minorText');
      }

      final flying = _formatFlyingMutagens(astrolabe, p, lang);
      buf.write(' | 飞化:$flying');

      final selfOut = <String>[
        for (final m in Mutagen.values)
          if (p.selfMutaged([m])) LocaleRegistry.translate(m.key, lang),
      ];
      final selfIn = <String>[
        for (final m in Mutagen.values)
          if (p.selfMutagedIn([m])) LocaleRegistry.translate(m.key, lang),
      ];
      if (selfOut.isNotEmpty || selfIn.isNotEmpty) {
        buf.write(
          ' | 自化:[出:${selfOut.isEmpty ? "-" : selfOut.join(",")},'
          '入:${selfIn.isEmpty ? "-" : selfIn.join(",")}]',
        );
      }

      buf.writeln();

      if (isFocus) {
        final sur = astrolabe.surroundedPalaces(p.index);
        final adjNames = p.adjectiveStars.map((s) => s.name).join('、');
        buf
          ..writeln(
            '  └─焦点三方四正: 本[${sur.target.name}] 对[${sur.opposite.name}] '
            '财[${sur.wealth.name}] 官[${sur.career.name}]',
          )
          ..writeln(
            '  └─本宫杂曜: ${adjNames.isEmpty ? "无" : adjNames} | '
            '长生:${p.changsheng12} 博士:${p.boshi12}',
          );
      }
    }

    return buf.toString().trimRight();
  }

  static String _scopePalaceLabel(HoroscopeItem item, int palaceIndex) {
    if (palaceIndex < 0 || palaceIndex >= item.palaceNames.length) {
      return '-';
    }
    return item.palaceNames[palaceIndex];
  }

  static String _formatStar(
    FunctionalStar star,
    FunctionalHoroscope horo,
    AstroLanguage lang,
  ) {
    final bright = star.brightness != null
        ? '(${LocaleRegistry.translate(star.brightness!.key, lang)})'
        : '';

    final tags = <String>[];
    if (star.mutagen != null) {
      tags.add('生${LocaleRegistry.translate(star.mutagen!.key, lang)}');
    }
    final decMut = _mutagenInList(star.key, horo.decadal.mutagenKeys, lang);
    if (decMut != null) {
      tags.add('运$decMut');
    }
    final yrMut = _mutagenInList(star.key, horo.yearly.mutagenKeys, lang);
    if (yrMut != null) {
      tags.add('流$yrMut');
    }
    final tagSuffix = tags.isEmpty ? '' : '[${tags.join("/")}]';
    return '${star.name}$bright$tagSuffix';
  }

  static String? _mutagenInList(
    StarKey key,
    List<StarKey> mutagens,
    AstroLanguage lang,
  ) {
    final idx = mutagens.indexOf(key);
    if (idx < 0 || idx >= Mutagen.values.length) {
      return null;
    }
    return LocaleRegistry.translate(Mutagen.values[idx].key, lang);
  }

  static String _formatFlyingMutagens(
    FunctionalAstrolabe astrolabe,
    FunctionalPalace palace,
    AstroLanguage lang,
  ) {
    final stemStars =
        resolveMutagenStars(palace.stem, astrolabe.configSnapshot);
    final parts = <String>[];
    for (var i = 0; i < Mutagen.values.length; i++) {
      final m = Mutagen.values[i];
      final label = LocaleRegistry.translate(m.key, lang);
      final star = astrolabe.star(stemStars[i]);
      final targetPalace = star.palace();
      final clashPalace = targetPalace != null
          ? astrolabe.palace(fixIndex(targetPalace.index + 6))
          : null;
      parts.add(
        '$label:${star.name}->${targetPalace?.name ?? "-"}(冲${clashPalace?.name ?? "-"})',
      );
    }
    return parts.join(' ');
  }
}
