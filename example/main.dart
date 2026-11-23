import 'dart:convert';

import 'package:iztro_dart/iztro_dart.dart';

void main() {
  // 1. Basic solar chart
  final chart = Astro.bySolar('2000-8-16', 2, Gender.female);
  print('=== Natal Chart ===');
  print('Solar: ${chart.solarDate}, Lunar: ${chart.lunarDate}');
  print('Four Pillars: ${chart.chineseDate}');
  print(
    'Soul Palace: ${chart.earthlyBranchOfSoulPalace}, '
    'Body Palace: ${chart.earthlyBranchOfBodyPalace}, '
    'Five Elements: ${chart.fiveElementsClass}',
  );

  // 2. True Solar Time (Chengdu, 104.07 E, 1988-07-15 China DST)
  final tstChart = Astro.byTrueSolarTime(
    DateTime(1988, 7, 15, 13, 20),
    longitude: 104.0668,
    utcOffsetMinutes: 480,
    gender: Gender.male,
  );
  print('\n=== True Solar Time ===');
  print(
    'Civil: ${tstChart.trueSolarTime.civilTime} -> '
    'TST: ${tstChart.trueSolarTime.trueSolarTime} '
    '(timeIndex=${tstChart.trueSolarTime.timeIndex}, '
    'boundaryWarning=${tstChart.trueSolarTime.isBoundaryWarning})',
  );

  // 3. Six-layer horoscope & chainable queries
  final horo = chart.horoscope('2023-8-19 3:12');
  final soul = chart.palace(PalaceName.soul)!;
  final flanked = chart.flankingPalaces(PalaceName.soul);
  print('\n=== Horoscope & Queries ===');
  print(
    '2023-8-19: age=${horo.age.nominalAge}, '
    'decadal=${horo.decadal.heavenlyStem}${horo.decadal.earthlyBranch}, '
    'yearly=${horo.yearly.heavenlyStem}${horo.yearly.earthlyBranch}',
  );
  print('Soul surrounded has Ziwei: ${chart.isSurrounded(PalaceName.soul, [
        StarKey.ziweiMaj
      ])}');
  print('Soul flies Lu to Wealth: ${soul.fliesTo(PalaceName.wealth, [
        Mutagen.lu
      ])}');
  print('Soul self-mutaged out: ${soul.selfMutagedOneOf()}');
  print('Soul self-mutaged in: ${soul.selfMutagedInOneOf()}');
  print(
    'Soul flanked by: ${flanked.previous.name}(${flanked.previous.earthlyBranch}) '
    '& ${flanked.next.name}(${flanked.next.earthlyBranch})',
  );

  // 4. LLM Chart DSL
  final dsl = chart.toLlmJson(
    targetDate: DateTime(2026, 5, 1),
    focusPalaces: const [PalaceName.soul, PalaceName.career],
  );
  const encoder = JsonEncoder.withIndent('  ');
  final metaSummary = encoder.convert({
    'meta': dsl['meta'],
    'detectedPatterns': dsl['detectedPatterns'],
  });
  print('\n=== LLM Chart DSL (excerpt) ===');
  print(metaSummary);
}
