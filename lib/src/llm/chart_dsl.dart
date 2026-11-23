import '../astro/functional_astrolabe.dart';
import '../astro/functional_horoscope.dart';
import '../astro/functional_palace.dart';
import '../astro/horoscope_calc.dart';
import '../core/index_math.dart';
import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import '../data/stars_meta.dart';
import '../star/functional_star.dart';
import 'pattern_detector.dart';

/// Compact, hallucination-resistant JSON Chart DSL designed for LLM reasoning.
abstract final class ChartDsl {
  static final BigInt _fnvOffsetBasis = BigInt.parse(
    'cbf29ce484222325',
    radix: 16,
  );
  static final BigInt _fnvPrime = BigInt.parse('100000001b3', radix: 16);
  static final BigInt _mask64 = (BigInt.one << 64) - BigInt.one;

  /// Computes a deterministic 64-bit FNV-1a hex fingerprint for [astrolabe]
  /// inputs and configuration (portable across Dart VM and Web/JS).
  static String fingerprintOf(FunctionalAstrolabe astrolabe) {
    final cfg = astrolabe.configSnapshot;
    final mutagensSig = cfg.mutagens.entries
        .map((e) => '${e.key.key}:${e.value.map((s) => s.key).join(",")}')
        .toList()
      ..sort();
    final brightnessSig = cfg.brightness.entries
        .map(
          (e) => '${e.key.key}:${e.value.map((b) => b?.key ?? "").join(",")}',
        )
        .toList()
      ..sort();

    final canonical = <String>[
      astrolabe.solarDate,
      '${astrolabe.timeIndex}',
      astrolabe.genderValue.key,
      astrolabe.astroType.key,
      'fixLeap=${astrolabe.fixLeap}',
      'lang=${cfg.language.code}',
      'algo=${cfg.algorithm.key}',
      'yearDiv=${cfg.yearDivide.key}',
      'horoDiv=${cfg.horoscopeDivide.key}',
      'ageDiv=${cfg.ageDivide.key}',
      'dayDiv=${cfg.dayDivide.key}',
      'mut=${mutagensSig.join(";")}',
      'bri=${brightnessSig.join(";")}',
    ].join('|');

    var hash = _fnvOffsetBasis;
    for (final unit in canonical.codeUnits) {
      hash = ((hash ^ BigInt.from(unit)) * _fnvPrime) & _mask64;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// Generates a structured LLM Chart DSL JSON map from [astrolabe].
  ///
  /// - [targetDate]: dynamic date for `activeHoroscope` (defaults to
  ///   `DateTime.now()`, never hardcoded).
  /// - [timeIndex]: optional target hour index (`0..12`).
  /// - [focusPalaces]: optional list of focus palaces marked with
  ///   `focused: true` and surfaced in `meta.focusPalaces`.
  static Map<String, dynamic> toLlmJson(
    FunctionalAstrolabe astrolabe, {
    DateTime? targetDate,
    int? timeIndex,
    List<PalaceName>? focusPalaces,
  }) {
    final effectiveTarget = targetDate ?? DateTime.now();
    final horo = astrolabe.horoscope(effectiveTarget, timeIndex);
    final cfg = astrolabe.configSnapshot;
    final lang = cfg.language;
    final patterns = PatternDetector.detect(astrolabe);
    final focusSet = focusPalaces?.toSet();

    final meta = <String, dynamic>{
      'fingerprint': fingerprintOf(astrolabe),
      'iztroBaseline': '2.6.5',
      'gender': astrolabe.gender,
      'solarDate': astrolabe.solarDate,
      'lunarDate': astrolabe.lunarDate,
      'chineseDate': astrolabe.chineseDate,
      'time': astrolabe.time,
      'timeRange': astrolabe.timeRange,
      'sign': astrolabe.sign,
      'zodiac': astrolabe.zodiac,
      'fiveElementsClass': astrolabe.fiveElementsClass,
      'soul': astrolabe.soul,
      'body': astrolabe.body,
      'earthlyBranchOfSoulPalace': astrolabe.earthlyBranchOfSoulPalace,
      'earthlyBranchOfBodyPalace': astrolabe.earthlyBranchOfBodyPalace,
      'config': <String, dynamic>{
        'language': cfg.language.code,
        'algorithm': cfg.algorithm.key,
        'astroType': astrolabe.astroType.key,
        'yearDivide': cfg.yearDivide.key,
        'horoscopeDivide': cfg.horoscopeDivide.key,
        'ageDivide': cfg.ageDivide.key,
        'dayDivide': cfg.dayDivide.key,
        'fixLeap': astrolabe.fixLeap,
      },
    };
    if (focusSet != null && focusSet.isNotEmpty) {
      meta['focusPalaces'] = focusSet
          .map((p) => LocaleRegistry.translate(p.key, lang))
          .toList(growable: false);
    }

    final palacesJson = astrolabe.palaces
        .map(
          (p) => _serializePalace(
            astrolabe,
            p,
            horo,
            lang,
            focused: focusSet?.contains(p.palaceName),
          ),
        )
        .toList(growable: false);

    return <String, dynamic>{
      'meta': meta,
      'palaces': palacesJson,
      'activeHoroscope': _serializeHoroscope(astrolabe, horo),
      'detectedPatterns':
          patterns.map((p) => p.toJson()).toList(growable: false),
    };
  }

  static Map<String, dynamic> _serializePalace(
    FunctionalAstrolabe astrolabe,
    FunctionalPalace palace,
    FunctionalHoroscope horo,
    AstroLanguage lang, {
    bool? focused,
  }) {
    final surrounded = astrolabe.surroundedPalaces(palace.index);
    final empty = palace.isEmpty();
    final borrowed = empty
        ? surrounded.opposite.majorStars
            .map((s) => _serializeStar(s, horo, lang))
            .toList(growable: false)
        : const <Map<String, dynamic>>[];

    final cfg = astrolabe.configSnapshot;
    final stemMutagenStars = resolveMutagenStars(palace.stem, cfg);
    final flying = <String, dynamic>{};
    for (var mIdx = 0; mIdx < Mutagen.values.length; mIdx++) {
      final mutagen = Mutagen.values[mIdx];
      final targetStarKey = stemMutagenStars[mIdx];
      final targetStar = astrolabe.star(targetStarKey);
      final targetPalace = targetStar.palace();
      final clashPalace = targetPalace != null
          ? astrolabe.palace(fixIndex(targetPalace.index + 6))
          : null;
      flying[mutagen.name] = <String, dynamic>{
        'mutagen': LocaleRegistry.translate(mutagen.key, lang),
        'star': targetStar.name,
        'targetPalace': targetPalace?.name,
        'targetIndex': targetPalace?.index,
        'clashPalace': clashPalace?.name,
        'clashIndex': clashPalace?.index,
      };
    }

    final selfOut = <String>[
      for (final m in Mutagen.values)
        if (palace.selfMutaged([m])) LocaleRegistry.translate(m.key, lang),
    ];
    final selfIn = <String>[
      for (final m in Mutagen.values)
        if (palace.selfMutagedIn([m])) LocaleRegistry.translate(m.key, lang),
    ];

    final surroundedMajor = <String>[
      for (final p in surrounded.allPalaces)
        for (final s in p.majorStars) '${s.name}(${p.name})',
    ];

    final map = <String, dynamic>{
      'index': palace.index,
      'name': palace.name,
      'ganZhi': '${palace.heavenlyStem}${palace.earthlyBranch}',
      'heavenlyStem': palace.heavenlyStem,
      'earthlyBranch': palace.earthlyBranch,
      'isBodyPalace': palace.isBodyPalace,
      'isOriginalPalace': palace.isOriginalPalace,
      'decadalAgeRange': <int>[palace.decadal.startAge, palace.decadal.endAge],
      'isEmpty': empty,
      if (empty) 'borrowedMajorStars': borrowed,
      'majorStars': palace.majorStars
          .map((s) => _serializeStar(s, horo, lang))
          .toList(growable: false),
      'minorStars': palace.minorStars
          .map((s) => _serializeStar(s, horo, lang))
          .toList(growable: false),
      'adjectiveStars':
          palace.adjectiveStars.map((s) => s.name).toList(growable: false),
      'surroundedSummary': <String, dynamic>{
        'oppositeIndex': surrounded.opposite.index,
        'wealthIndex': surrounded.wealth.index,
        'careerIndex': surrounded.career.index,
        'majorStars': surroundedMajor,
      },
      'flyingMutagens': flying,
      'selfMutagedOut': selfOut,
      'selfMutagedIn': selfIn,
    };
    if (focused != null) {
      map['focused'] = focused;
    }
    return map;
  }

  static Map<String, dynamic> _serializeStar(
    FunctionalStar star,
    FunctionalHoroscope horo,
    AstroLanguage lang,
  ) {
    final map = <String, dynamic>{
      'name': star.name,
    };
    if (star.brightness != null) {
      map['brightness'] = LocaleRegistry.translate(star.brightness!.key, lang);
    }
    if (star.mutagen != null) {
      map['natalMutagen'] = LocaleRegistry.translate(star.mutagen!.key, lang);
    }
    final decadalMut = _mutagenInList(star.key, horo.decadal.mutagenKeys, lang);
    if (decadalMut != null) {
      map['decadalMutagen'] = decadalMut;
    }
    final yearlyMut = _mutagenInList(star.key, horo.yearly.mutagenKeys, lang);
    if (yearlyMut != null) {
      map['yearlyMutagen'] = yearlyMut;
    }
    return map;
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

  static Map<String, dynamic> _serializeHoroscope(
    FunctionalAstrolabe astrolabe,
    FunctionalHoroscope horo,
  ) {
    Map<String, String> buildPalaceStack(HoroscopeItem item) {
      final result = <String, String>{};
      for (var i = 0; i < 12; i++) {
        final natalName = astrolabe.palaces[i].name;
        result[item.palaceNames[i]] = natalName;
      }
      return result;
    }

    return <String, dynamic>{
      'solarDate': horo.solarDate,
      'lunarDate': horo.lunarDate,
      'nominalAge': horo.age.nominalAge,
      'isChildhood': horo.isChildhood,
      'decadal': <String, dynamic>{
        'index': horo.decadal.index,
        'name': horo.decadal.name,
        'ganZhi': '${horo.decadal.heavenlyStem}${horo.decadal.earthlyBranch}',
        'mutagen': horo.decadal.mutagen,
        'palaceMapping': buildPalaceStack(horo.decadal),
      },
      'age': <String, dynamic>{
        'index': horo.age.index,
        'nominalAge': horo.age.nominalAge,
        'ganZhi': '${horo.age.heavenlyStem}${horo.age.earthlyBranch}',
        'mutagen': horo.age.mutagen,
      },
      'yearly': <String, dynamic>{
        'index': horo.yearly.index,
        'name': horo.yearly.name,
        'ganZhi': '${horo.yearly.heavenlyStem}${horo.yearly.earthlyBranch}',
        'mutagen': horo.yearly.mutagen,
        'palaceMapping': buildPalaceStack(horo.yearly),
      },
      'monthly': <String, dynamic>{
        'index': horo.monthly.index,
        'ganZhi': '${horo.monthly.heavenlyStem}${horo.monthly.earthlyBranch}',
        'mutagen': horo.monthly.mutagen,
      },
      'daily': <String, dynamic>{
        'index': horo.daily.index,
        'ganZhi': '${horo.daily.heavenlyStem}${horo.daily.earthlyBranch}',
        'mutagen': horo.daily.mutagen,
      },
      'hourly': <String, dynamic>{
        'index': horo.hourly.index,
        'ganZhi': '${horo.hourly.heavenlyStem}${horo.hourly.earthlyBranch}',
        'mutagen': horo.hourly.mutagen,
      },
    };
  }
}
