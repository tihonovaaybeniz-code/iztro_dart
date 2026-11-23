import '../astro/functional_astrolabe.dart';
import '../astro/functional_palace.dart';
import '../core/types.dart';
import '../data/locales/locale_registry.dart';

/// A classical Ziwei Doushu formation detected by deterministic rules.
class DetectedPattern {
  const DetectedPattern({
    required this.name,
    required this.isClean,
    required this.breakFactors,
    required this.evidence,
  });

  final String name;

  /// `true` when no breaking malefic stars or birth `化忌` afflict the
  /// relevant palaces.
  final bool isClean;

  /// Specific afflicting stars/mutagens breaking or weakening the pattern.
  final List<String> breakFactors;

  /// Stars and palace locations supporting this pattern detection.
  final List<String> evidence;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'isClean': isClean,
        'breakFactors': breakFactors,
        'evidence': evidence,
      };
}

/// Deterministic rule-based classical pattern detector for [FunctionalAstrolabe].
abstract final class PatternDetector {
  static const List<StarKey> _maleficStars = [
    StarKey.qingyangMin,
    StarKey.tuoluoMin,
    StarKey.huoxingMin,
    StarKey.lingxingMin,
    StarKey.dikongMin,
    StarKey.dijieMin,
  ];

  static const List<StarKey> _sixLuckyStars = [
    StarKey.zuofuMin,
    StarKey.youbiMin,
    StarKey.wenchangMin,
    StarKey.wenquMin,
    StarKey.tiankuiMin,
    StarKey.tianyueMin,
  ];

  /// Detects classical Ziwei Doushu formations in [astrolabe].
  static List<DetectedPattern> detect(FunctionalAstrolabe astrolabe) {
    final results = <DetectedPattern>[];
    final lang = astrolabe.configSnapshot.language;
    final soul = astrolabe.palace(PalaceName.soul);
    if (soul == null) {
      return results;
    }
    final surrounded = astrolabe.surroundedPalaces(PalaceName.soul);
    final flanking = astrolabe.flankingPalaces(PalaceName.soul);
    final soulSanfang = surrounded.allPalaces.toList(growable: false);

    // 1. 命无正曜格
    if (soul.isEmpty()) {
      final borrowed = surrounded.opposite.majorStars
          .map((s) => '${s.name}(${surrounded.opposite.name}借)')
          .toList(growable: false);
      final breaks = _collectBreakFactors([soul], lang: lang);
      results.add(
        DetectedPattern(
          name: '命无正曜格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: <String>[
            '${soul.name}(${soul.earthlyBranch})无主星',
            ...borrowed,
          ],
        ),
      );
    }

    // 2. 杀破狼格
    if (surrounded.have([
      StarKey.qishaMaj,
      StarKey.pojunMaj,
      StarKey.tanlangMaj,
    ])) {
      final breaks = _collectBreakFactors(soulSanfang, lang: lang);
      results.add(
        DetectedPattern(
          name: '杀破狼格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: _findEvidence(
            soulSanfang,
            [StarKey.qishaMaj, StarKey.pojunMaj, StarKey.tanlangMaj],
          ),
        ),
      );
    }

    // 3. 机月同梁格
    if (surrounded.have([
      StarKey.tianjiMaj,
      StarKey.taiyinMaj,
      StarKey.tiantongMaj,
      StarKey.tianliangMaj,
    ])) {
      final breaks = _collectBreakFactors(soulSanfang, lang: lang);
      results.add(
        DetectedPattern(
          name: '机月同梁格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: _findEvidence(
            soulSanfang,
            [
              StarKey.tianjiMaj,
              StarKey.taiyinMaj,
              StarKey.tiantongMaj,
              StarKey.tianliangMaj,
            ],
          ),
        ),
      );
    }

    // 4. 紫府同宫格 vs 紫府朝垣格
    if (soul.has([StarKey.ziweiMaj, StarKey.tianfuMaj])) {
      final breaks = _collectBreakFactors(soulSanfang, lang: lang);
      results.add(
        DetectedPattern(
          name: '紫府同宫格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: _findEvidence(
            [soul],
            [StarKey.ziweiMaj, StarKey.tianfuMaj],
          ),
        ),
      );
    } else if (surrounded.have([StarKey.ziweiMaj, StarKey.tianfuMaj])) {
      final breaks = _collectBreakFactors(soulSanfang, lang: lang);
      results.add(
        DetectedPattern(
          name: '紫府朝垣格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: _findEvidence(
            soulSanfang,
            [StarKey.ziweiMaj, StarKey.tianfuMaj],
          ),
        ),
      );
    }

    // 5. 府相朝垣格
    if (!soul.has([StarKey.ziweiMaj, StarKey.tianfuMaj]) &&
        surrounded.have([StarKey.tianfuMaj, StarKey.tianxiangMaj])) {
      final breaks = _collectBreakFactors(soulSanfang, lang: lang);
      results.add(
        DetectedPattern(
          name: '府相朝垣格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: _findEvidence(
            soulSanfang,
            [StarKey.tianfuMaj, StarKey.tianxiangMaj],
          ),
        ),
      );
    }

    // 6. 日月并明格 (太阳与太阴同会命宫三方四正且皆得庙/旺亮度)
    if (surrounded.have([StarKey.taiyangMaj, StarKey.taiyinMaj])) {
      final sun = astrolabe.star(StarKey.taiyangMaj);
      final moon = astrolabe.star(StarKey.taiyinMaj);
      if (sun.withBrightness([Brightness.miao, Brightness.wang]) &&
          moon.withBrightness([Brightness.miao, Brightness.wang])) {
        final breaks = _collectBreakFactors(soulSanfang, lang: lang);
        results.add(
          DetectedPattern(
            name: '日月并明格',
            isClean: breaks.isEmpty,
            breakFactors: breaks,
            evidence: _findEvidence(
              soulSanfang,
              [StarKey.taiyangMaj, StarKey.taiyinMaj],
              includeBrightness: true,
              lang: lang,
            ),
          ),
        );
      }
    }

    // 7. 阳梁昌禄格
    if (surrounded.have([
      StarKey.taiyangMaj,
      StarKey.tianliangMaj,
      StarKey.wenchangMin,
      StarKey.lucunMin,
    ])) {
      final breaks = _collectBreakFactors(soulSanfang, lang: lang);
      results.add(
        DetectedPattern(
          name: '阳梁昌禄格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: _findEvidence(
            soulSanfang,
            [
              StarKey.taiyangMaj,
              StarKey.tianliangMaj,
              StarKey.wenchangMin,
              StarKey.lucunMin,
            ],
          ),
        ),
      );
    }

    // 8. 君臣庆会格 (紫微在命宫且三方四正会左辅、右弼，或会三颗以上六吉)
    if (soul.has([StarKey.ziweiMaj]) &&
        surrounded.have([StarKey.zuofuMin, StarKey.youbiMin])) {
      final luckyFound = _findEvidence(soulSanfang, _sixLuckyStars);
      final breaks = _collectBreakFactors(soulSanfang, lang: lang);
      results.add(
        DetectedPattern(
          name: '君臣庆会格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: <String>[
            ..._findEvidence([soul], [StarKey.ziweiMaj]),
            ...luckyFound,
          ],
        ),
      );
    }

    // 9. 禄马交驰格 (命宫三方四正同宫见禄存/化禄 + 天马，或命迁对冲见)
    final luMaPalaces = <FunctionalPalace>[
      for (final p in soulSanfang)
        if (p.has([StarKey.tianmaMin]) &&
            (p.has([StarKey.lucunMin]) || p.hasMutagen(Mutagen.lu)))
          p,
    ];
    final oppositeLuMa = (soul.has([StarKey.tianmaMin]) &&
            (surrounded.opposite.has([StarKey.lucunMin]) ||
                surrounded.opposite.hasMutagen(Mutagen.lu))) ||
        (surrounded.opposite.has([StarKey.tianmaMin]) &&
            (soul.has([StarKey.lucunMin]) || soul.hasMutagen(Mutagen.lu)));
    if (luMaPalaces.isNotEmpty || oppositeLuMa) {
      final watch =
          luMaPalaces.isNotEmpty ? luMaPalaces : [soul, surrounded.opposite];
      final breaks = _collectBreakFactors(watch, lang: lang);
      final ev = <String>[
        ..._findEvidence(watch, [StarKey.tianmaMin, StarKey.lucunMin]),
        for (final p in watch)
          for (final s in [...p.majorStars, ...p.minorStars])
            if (s.mutagen == Mutagen.lu) '${s.name}化禄(${p.name})',
      ];
      results.add(
        DetectedPattern(
          name: '禄马交驰格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: ev,
        ),
      );
    }

    // 10. 双禄夹命格
    final prevHasLu = flanking.previous.has([StarKey.lucunMin]);
    final nextHasLu = flanking.next.has([StarKey.lucunMin]);
    final prevHasHuaLu = flanking.previous.hasMutagen(Mutagen.lu);
    final nextHasHuaLu = flanking.next.hasMutagen(Mutagen.lu);
    if ((prevHasLu && nextHasHuaLu) || (nextHasLu && prevHasHuaLu)) {
      final breaks = _collectBreakFactors(
        [soul, flanking.previous, flanking.next],
        lang: lang,
      );
      results.add(
        DetectedPattern(
          name: '双禄夹命格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: <String>[
            ..._findEvidence(
              [flanking.previous, flanking.next],
              [StarKey.lucunMin],
            ),
            for (final p in [flanking.previous, flanking.next])
              for (final s in [...p.majorStars, ...p.minorStars])
                if (s.mutagen == Mutagen.lu) '${s.name}化禄(${p.name})',
          ],
        ),
      );
    }

    // 11. 左右夹命格
    if ((flanking.previous.has([StarKey.zuofuMin]) &&
            flanking.next.has([StarKey.youbiMin])) ||
        (flanking.previous.has([StarKey.youbiMin]) &&
            flanking.next.has([StarKey.zuofuMin]))) {
      final breaks = _collectBreakFactors(
        [soul, flanking.previous, flanking.next],
        lang: lang,
      );
      results.add(
        DetectedPattern(
          name: '左右夹命格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: _findEvidence(
            [flanking.previous, flanking.next],
            [StarKey.zuofuMin, StarKey.youbiMin],
          ),
        ),
      );
    }

    // 12. 昌曲夹命格
    if ((flanking.previous.has([StarKey.wenchangMin]) &&
            flanking.next.has([StarKey.wenquMin])) ||
        (flanking.previous.has([StarKey.wenquMin]) &&
            flanking.next.has([StarKey.wenchangMin]))) {
      final breaks = _collectBreakFactors(
        [soul, flanking.previous, flanking.next],
        lang: lang,
      );
      results.add(
        DetectedPattern(
          name: '昌曲夹命格',
          isClean: breaks.isEmpty,
          breakFactors: breaks,
          evidence: _findEvidence(
            [flanking.previous, flanking.next],
            [StarKey.wenchangMin, StarKey.wenquMin],
          ),
        ),
      );
    }

    // 13. 火贪格 / 铃贪格
    for (final p in soulSanfang) {
      if (p.has([StarKey.tanlangMaj, StarKey.huoxingMin])) {
        final breaks = _collectBreakFactors(
          [p],
          lang: lang,
          exemptStars: const {StarKey.huoxingMin},
        );
        results.add(
          DetectedPattern(
            name: '火贪格',
            isClean: breaks.isEmpty,
            breakFactors: breaks,
            evidence:
                _findEvidence([p], [StarKey.tanlangMaj, StarKey.huoxingMin]),
          ),
        );
      }
      if (p.has([StarKey.tanlangMaj, StarKey.lingxingMin])) {
        final breaks = _collectBreakFactors(
          [p],
          lang: lang,
          exemptStars: const {StarKey.lingxingMin},
        );
        results.add(
          DetectedPattern(
            name: '铃贪格',
            isClean: breaks.isEmpty,
            breakFactors: breaks,
            evidence:
                _findEvidence([p], [StarKey.tanlangMaj, StarKey.lingxingMin]),
          ),
        );
      }
    }

    return results;
  }

  static List<String> _findEvidence(
    List<FunctionalPalace> palaces,
    List<StarKey> keys, {
    bool includeBrightness = false,
    AstroLanguage lang = AstroLanguage.zhCN,
  }) {
    final out = <String>[];
    final wanted = keys.toSet();
    for (final p in palaces) {
      for (final s in p.allStars) {
        if (wanted.contains(s.key)) {
          final bright = includeBrightness && s.brightness != null
              ? '[${LocaleRegistry.translate(s.brightness!.key, lang)}]'
              : '';
          out.add('${s.name}$bright(${p.name})');
        }
      }
    }
    return out;
  }

  static List<String> _collectBreakFactors(
    List<FunctionalPalace> palaces, {
    required AstroLanguage lang,
    Set<StarKey> exemptStars = const {},
  }) {
    final breaks = <String>[];
    for (final p in palaces) {
      for (final s in p.allStars) {
        if (!exemptStars.contains(s.key) && _maleficStars.contains(s.key)) {
          breaks.add('${s.name}(${p.name})');
        }
        if (s.mutagen == Mutagen.ji) {
          final jiLabel = LocaleRegistry.translate(Mutagen.ji.key, lang);
          breaks.add('${s.name}化$jiLabel(${p.name})');
        }
      }
    }
    return breaks;
  }
}
