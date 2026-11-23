import 'dart:convert';

import 'package:iztro_dart/iztro_dart.dart';
import 'package:test/test.dart';

void main() {
  setUp(Astro.resetConfig);
  tearDown(Astro.resetConfig);

  group('LLM Chart DSL & PatternDetector (M3)', () {
    test('toLlmJson produces deterministic fingerprint and complete schema',
        () {
      final chart1 = Astro.bySolar('2000-8-16', 2, Gender.female);
      final chart2 = Astro.bySolar('2000-8-16', 2, Gender.female);
      final diffGender = Astro.bySolar('2000-8-16', 2, Gender.male);

      final dsl1 = chart1.toLlmJson(
        targetDate: DateTime(2026, 11, 23),
        focusPalaces: const [PalaceName.soul, PalaceName.wealth],
      );
      final dsl2 = chart2.toLlmJson(targetDate: DateTime(2026, 11, 23));
      final dsl3 = diffGender.toLlmJson(targetDate: DateTime(2026, 11, 23));

      expect(
        (dsl1['meta'] as Map<String, dynamic>)['fingerprint'],
        (dsl2['meta'] as Map<String, dynamic>)['fingerprint'],
      );
      expect(
        (dsl1['meta'] as Map<String, dynamic>)['fingerprint'],
        isNot((dsl3['meta'] as Map<String, dynamic>)['fingerprint']),
      );

      final meta = dsl1['meta'] as Map<String, dynamic>;
      expect(meta['iztroBaseline'], '2.6.5');
      expect(meta['focusPalaces'], ['命宫', '财帛']);

      final palaces = dsl1['palaces'] as List<dynamic>;
      expect(palaces, hasLength(12));

      // Empty palace includes borrowedMajorStars.
      final parentsJson = palaces
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['name'] == '父母');
      expect(parentsJson['isEmpty'], isTrue);
      expect(parentsJson['borrowedMajorStars'], isNotEmpty);

      // Focus marker works accurately.
      final soulJson = palaces
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['name'] == '命宫');
      expect(soulJson['focused'], isTrue);
      expect(parentsJson['focused'], isFalse);

      // Active horoscope uses supplied dynamic targetDate (not hardcoded).
      final activeHoro = dsl1['activeHoroscope'] as Map<String, dynamic>;
      expect(activeHoro['solarDate'], '2026-11-23');
      expect(
        (activeHoro['yearly'] as Map<String, dynamic>)['ganZhi'],
        '丙午',
      );

      // Full JSON roundtrip succeeds cleanly.
      expect(() => jsonEncode(dsl1), returnsNormally);
    });

    test('PatternDetector detects classical formations and break factors', () {
      // Scan a variety of birth dates to verify pattern rules return valid objects.
      final patternsFound = <String>{};
      for (var day = 1; day <= 28; day++) {
        for (var t = 0; t < 12; t++) {
          final chart = Astro.bySolar('1995-5-$day', t, Gender.male);
          final detected = PatternDetector.detect(chart);
          for (final p in detected) {
            patternsFound.add(p.name);
            expect(p.evidence, isNotEmpty);
            expect(p.isClean, p.breakFactors.isEmpty);
          }
        }
      }
      expect(patternsFound, contains('杀破狼格'));
      expect(patternsFound, contains('机月同梁格'));
      expect(patternsFound, contains('命无正曜格'));
    });
  });
}
