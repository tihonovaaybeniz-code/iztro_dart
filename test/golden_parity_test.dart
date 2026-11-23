import 'dart:convert';
import 'dart:io';

import 'package:iztro_dart/iztro_dart.dart';
import 'package:test/test.dart';

void main() {
  setUp(Astro.resetConfig);
  tearDown(Astro.resetConfig);

  const fixtureFiles = [
    'test/fixtures/regular_400.json',
    'test/fixtures/leap_100.json',
    'test/fixtures/boundary_100.json',
    'test/fixtures/algorithm_astrotype_locale_120.json',
    'test/fixtures/horoscope_150.json',
  ];

  for (final filePath in fixtureFiles) {
    final fileName = filePath.split('/').last;
    test('100% parity with iztro@2.6.5 on $fileName', () {
      final raw = File(filePath).readAsStringSync();
      final cases =
          (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      expect(cases, isNotEmpty);

      for (final item in cases) {
        final input = item['input'] as Map<String, dynamic>;
        final id = input['id'] as String;
        final chart = Astro.withOptions(_parseOptions(input));

        final actualJson = Map<String, dynamic>.of(chart.toJson());
        final expectedJson = _normalizeUpstreamChartQuirks(
          jsonDecode(jsonEncode(item['expected'])) as Map<String, dynamic>,
          actualJson: actualJson,
          input: input,
        );

        expect(
          actualJson['copyright'],
          startsWith('copyright © 2023-'),
          reason: '$id copyright',
        );
        actualJson.remove('copyright');
        expectedJson.remove('copyright');

        final diff =
            _firstDiff(expectedJson, actualJson, path: '$id.astrolabe');
        expect(diff, isNull, reason: diff);

        if (item.containsKey('horoscopeQuery')) {
          final query = item['horoscopeQuery'] as Map<String, dynamic>;
          final targetDate = query['targetDate'] as String;
          final targetTimeIndex = query['targetTimeIndex'] as int;
          final horo = chart.horoscope(targetDate, targetTimeIndex);

          final expectedHoroscope = _normalizeUpstreamHoroscopeQuirks(
            jsonDecode(jsonEncode(item['expectedHoroscope']))
                as Map<String, dynamic>,
            language: chart.configSnapshot.language,
          );

          final horoDiff = _firstDiff(
            expectedHoroscope,
            horo.toJson(),
            path: '$id.horoscope',
          );
          expect(horoDiff, isNull, reason: horoDiff);

          final decadalDiff = _firstDiff(
            item['expectedDecadalList'],
            chart.decadalList().map((d) => d.toJson()).toList(),
            path: '$id.decadalList',
          );
          expect(decadalDiff, isNull, reason: decadalDiff);

          final yearlyIdx = query['yearlyDecadalIndex'] as int;
          final yearlyDiff = _firstDiff(
            item['expectedYearlyList'],
            chart.yearlyList(yearlyIdx).map((y) => y.toJson()).toList(),
            path: '$id.yearlyList',
          );
          expect(yearlyDiff, isNull, reason: yearlyDiff);

          final monthlyYear = query['monthlyYear'] as int;
          final monthlyFixLeap = query['monthlyFixLeap'] as bool;
          final monthlyDiff = _firstDiff(
            item['expectedMonthlyList'],
            chart
                .monthlyList(monthlyYear, fixLeap: monthlyFixLeap)
                .map((m) => m.toJson())
                .toList(),
            path: '$id.monthlyList',
          );
          expect(monthlyDiff, isNull, reason: monthlyDiff);

          final flankingDiff = _firstDiff(
            item['expectedFlanking0'],
            chart.flankingPalaces(0).toJson(),
            path: '$id.flanking0',
          );
          expect(flankingDiff, isNull, reason: flankingDiff);
        }
      }
    });
  }
}

AstroOptions _parseOptions(Map<String, dynamic> input) {
  final cfgMap =
      (input['config'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

  Map<HeavenlyStem, List<StarKey>>? customMutagens;
  if (cfgMap['mutagens'] is Map<String, dynamic>) {
    final rawMut = cfgMap['mutagens'] as Map<String, dynamic>;
    customMutagens = <HeavenlyStem, List<StarKey>>{};
    for (final entry in rawMut.entries) {
      final stem = LocaleRegistry.parseHeavenlyStem(entry.key);
      final stars = (entry.value as List<dynamic>)
          .map((s) => LocaleRegistry.tryParseStarKey(s as String)!)
          .toList(growable: false);
      customMutagens[stem] = stars;
    }
  }

  Map<StarKey, List<Brightness?>>? customBrightness;
  if (cfgMap['brightness'] is Map<String, dynamic>) {
    final rawBri = cfgMap['brightness'] as Map<String, dynamic>;
    customBrightness = <StarKey, List<Brightness?>>{};
    for (final entry in rawBri.entries) {
      final star = LocaleRegistry.tryParseStarKey(entry.key)!;
      final levels = (entry.value as List<dynamic>)
          .map(
            (b) => (b as String).isEmpty
                ? null
                : LocaleRegistry.tryParseBrightness(b),
          )
          .toList(growable: false);
      customBrightness[star] = levels;
    }
  }

  final config = AstroConfig(
    yearDivide: _parseDivide(cfgMap['yearDivide'] as String?),
    horoscopeDivide: _parseDivide(cfgMap['horoscopeDivide'] as String?),
    ageDivide: switch (cfgMap['ageDivide'] as String?) {
      'birthday' => AgeDivideType.birthday,
      'normal' => AgeDivideType.normal,
      _ => null,
    },
    dayDivide: switch (cfgMap['dayDivide'] as String?) {
      'current' => DayDivideType.current,
      'forward' => DayDivideType.forward,
      _ => null,
    },
    algorithm: switch (cfgMap['algorithm'] as String?) {
      'zhongzhou' => Algorithm.zhongzhou,
      'default' => Algorithm.defaultAlgorithm,
      _ => null,
    },
    mutagens: customMutagens,
    brightness: customBrightness,
  );

  final language = input['language'] != null
      ? AstroLanguage.tryParse(input['language'] as String)
      : null;

  return AstroOptions(
    type: input['type'] == 'lunar' ? AstroDateType.lunar : AstroDateType.solar,
    dateStr: input['dateStr'] as String,
    timeIndex: input['timeIndex'] as int,
    gender: input['gender'] == 'male' ? Gender.male : Gender.female,
    isLeapMonth: (input['isLeapMonth'] as bool?) ?? false,
    fixLeap: (input['fixLeap'] as bool?) ?? true,
    language: language,
    astroType: switch (input['astroType'] as String?) {
      'earth' => AstroType.earth,
      'human' => AstroType.human,
      _ => AstroType.heaven,
    },
    config: config,
  );
}

DivideType? _parseDivide(String? value) {
  return switch (value) {
    'exact' => DivideType.exact,
    'normal' => DivideType.normal,
    _ => null,
  };
}

String? _firstDiff(
  Object? expected,
  Object? actual, {
  required String path,
}) {
  if (expected is Map && actual is Map) {
    final expKeys = expected.keys.toSet();
    final actKeys = actual.keys.toSet();
    if (expKeys.length != actKeys.length || !expKeys.containsAll(actKeys)) {
      final missing = expKeys.difference(actKeys);
      final extra = actKeys.difference(expKeys);
      return '$path key mismatch: missing=$missing, extra=$extra';
    }
    for (final k in expKeys) {
      final sub = _firstDiff(expected[k], actual[k], path: '$path.$k');
      if (sub != null) {
        return sub;
      }
    }
    return null;
  }

  if (expected is List && actual is List) {
    if (expected.length != actual.length) {
      return '$path length mismatch: expected=${expected.length}, actual=${actual.length}';
    }
    for (var i = 0; i < expected.length; i++) {
      final sub = _firstDiff(expected[i], actual[i], path: '$path[$i]');
      if (sub != null) {
        return sub;
      }
    }
    return null;
  }

  if (expected != actual) {
    return '$path value mismatch:\n  expected: $expected\n  actual:   $actual';
  }
  return null;
}

/// Normalizes verified upstream `iztro@2.6.5` bugs in golden expectations ONLY
/// when the exact documented bug signature holds:
///
/// 1. `ko-KR` + `astroType: earth | human`: upstream `rearrangeAstrolable` checks
///    `kot(item.name) === 'tianshang'`, which collides with `tianxiangMaj`
///    ('천상') and fails to remove the stale `tianshang` entry, leaving two
///    `'천상'` adjectiveStars across the 12 palaces while `iztro_dart` uses
///    canonical [StarKey.tianshang] and moves it cleanly.
/// 2. `en-US` + `astroType: earth | human`: upstream `rearrangeAstrolable` calls
///    `t(palace.earthlyBranch)` without `kot(...)`; when branch is `'si'`,
///    i18next matches Changsheng12 star key `'si'` -> `'dead'` instead of `'si'`.
Map<String, dynamic> _normalizeUpstreamChartQuirks(
  Map<String, dynamic> expected, {
  required Map<String, dynamic> actualJson,
  required Map<String, dynamic> input,
}) {
  final isRearrange =
      input['astroType'] == 'earth' || input['astroType'] == 'human';
  if (!isRearrange) {
    return expected;
  }

  if (input['language'] == 'en-US') {
    if (expected['earthlyBranchOfSoulPalace'] == 'dead' &&
        actualJson['earthlyBranchOfSoulPalace'] == 'si') {
      expected['earthlyBranchOfSoulPalace'] = 'si';
    }
    if (expected['earthlyBranchOfBodyPalace'] == 'dead' &&
        actualJson['earthlyBranchOfBodyPalace'] == 'si') {
      expected['earthlyBranchOfBodyPalace'] = 'si';
    }
  }

  if (input['language'] != 'ko-KR') {
    return expected;
  }

  final expPalaces =
      (expected['palaces'] as List<dynamic>).cast<Map<String, dynamic>>();
  final actPalaces =
      (actualJson['palaces'] as List<dynamic>).cast<Map<String, dynamic>>();

  int countCheonsang(List<Map<String, dynamic>> palaces) {
    var total = 0;
    for (final p in palaces) {
      for (final s in (p['adjectiveStars'] as List<dynamic>)) {
        if ((s as Map<String, dynamic>)['name'] == '천상') {
          total++;
        }
      }
    }
    return total;
  }

  if (countCheonsang(expPalaces) == 2 && countCheonsang(actPalaces) == 1) {
    for (var i = 0; i < 12; i++) {
      final expAdj = (expPalaces[i]['adjectiveStars'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final actAdj = (actPalaces[i]['adjectiveStars'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final expCount = expAdj.where((s) => s['name'] == '천상').length;
      final actCount = actAdj.where((s) => s['name'] == '천상').length;
      if (expCount > actCount) {
        final removeIdx = expAdj.lastIndexWhere((s) => s['name'] == '천상');
        if (removeIdx != -1) {
          expAdj.removeAt(removeIdx);
        }
      }
    }
  }
  return expected;
}

/// 2. `nominalAge <= 0` (`index == -1`): upstream `FunctionalAstrolabe.ts:483`
///    has typo `kot(..., 'Heavnly')` and line `493` skips `t(...)`, outputting
///    untranslated `'jia'` / `'zi'` literals when `index == -1`.
Map<String, dynamic> _normalizeUpstreamHoroscopeQuirks(
  Map<String, dynamic> expected, {
  required AstroLanguage language,
}) {
  final jia = LocaleRegistry.translate(HeavenlyStem.jia.key, language);
  final zi = LocaleRegistry.translate(EarthlyBranch.zi.key, language);

  for (final key in const ['decadal', 'age']) {
    final section = expected[key] as Map<String, dynamic>;
    if (section['index'] == -1) {
      if (section['heavenlyStem'] == 'jia') {
        section['heavenlyStem'] = jia;
      }
      if (section['earthlyBranch'] == 'zi') {
        section['earthlyBranch'] = zi;
      }
    }
  }
  return expected;
}
