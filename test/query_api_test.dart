import 'package:iztro_dart/iztro_dart.dart';
import 'package:test/test.dart';

void main() {
  setUp(Astro.resetConfig);
  tearDown(Astro.resetConfig);

  group('Horoscope & chainable query APIs (M3)', () {
    test('horoscope(' '2023-8-19 3:12' ') matches iztro@2.6.5 assertions', () {
      final chart = Astro.bySolar('2000-8-16', 2, Gender.female);
      final horo = chart.horoscope('2023-8-19 3:12');

      expect(horo.solarDate, '2023-8-19');
      expect(horo.decadal.index, 2);
      expect(horo.decadal.heavenlyStem, '庚');
      expect(horo.decadal.earthlyBranch, '辰');
      expect(horo.decadal.palaceNames, [
        '夫妻',
        '兄弟',
        '命宫',
        '父母',
        '福德',
        '田宅',
        '官禄',
        '仆役',
        '迁移',
        '疾厄',
        '财帛',
        '子女',
      ]);
      expect(horo.decadal.mutagen, ['太阳', '武曲', '太阴', '天同']);
      expect(horo.age.index, 9);
      expect(horo.age.nominalAge, 24);
      expect(horo.yearly.index, 1);
      expect(horo.yearly.heavenlyStem, '癸');
      expect(horo.yearly.earthlyBranch, '卯');
      expect(horo.yearly.mutagen, ['破军', '巨门', '太阴', '贪狼']);
      expect(horo.monthly.index, 3);
      expect(horo.monthly.heavenlyStem, '庚');
      expect(horo.monthly.earthlyBranch, '申');
      expect(horo.agePalace()?.index, 9);
      expect(horo.palace(PalaceName.soul, Scope.yearly)?.index, 1);
      expect(horo.surroundPalaces(PalaceName.soul, Scope.decadal)?.target.index,
          2);
      expect(horo.toJson()['solarDate'], '2023-8-19');
    });

    test('childhood decadal fallback and ageDivide birthday rule', () {
      final normalAge = Astro.bySolar('2020-6-1', 4, Gender.male);
      final childHoro = normalAge.horoscope('2021-5-1');
      expect(childHoro.isChildhood, isTrue);
      expect(childHoro.age.nominalAge, 2);
      expect(childHoro.decadal.name, '童限');
      // Age 2 childhood falls on Wealth palace.
      expect(
        childHoro.decadal.index,
        normalAge.palace(PalaceName.wealth)!.index,
      );

      final birthdayAge = Astro.withOptions(
        const AstroOptions(
          dateStr: '2000-8-16', // lunar 2000-7-17
          timeIndex: 2,
          gender: Gender.female,
          config: AstroConfig(ageDivide: AgeDivideType.birthday),
        ),
      );
      // Before lunar 7-17 in 2023 (2023-8-16 is lunar 7-1): nominal age = 23.
      expect(birthdayAge.horoscope('2023-8-16').age.nominalAge, 23);
      // After lunar 7-17 in 2023 (2023-9-5 is lunar 7-21): nominal age = 24.
      expect(birthdayAge.horoscope('2023-9-5').age.nominalAge, 24);
    });

    test('decadalList, yearlyList, and monthlyList return expected lengths',
        () {
      final chart = Astro.bySolar('2000-8-16', 2, Gender.female);

      final decadals = chart.decadalList();
      expect(decadals, hasLength(12));
      expect(decadals.first.ageRange, (3, 12));
      expect(decadals.first.yearRange, (2002, 2011));

      final yearlies = chart.yearlyList(0);
      expect(yearlies, hasLength(10));
      expect(yearlies.first.age, 3);
      expect(yearlies.last.age, 12);

      // 2023 has leap 2nd month -> 14 segments with fixLeap=true, 13 with false.
      expect(chart.monthlyList(2023, fixLeap: true), hasLength(14));
      expect(chart.monthlyList(2023, fixLeap: false), hasLength(13));
      expect(chart.monthlyList(2024), hasLength(12));
    });

    test('palace queries: surrounded, flanking, flying mutagens, selfMutagedIn',
        () {
      final chart = Astro.bySolar('2000-8-16', 2, Gender.female);
      final soul = chart.palace(PalaceName.soul)!;
      final parents = chart.palace(PalaceName.parents)!;

      expect(parents.isEmpty(), isTrue);
      expect(parents.isEmpty([StarKey.tuoluoMin]), isFalse);
      expect(soul.isEmpty(), isFalse);

      final flanked = chart.flankingPalaces(0);
      expect(flanked.previous.index, 11);
      expect(flanked.next.index, 1);

      final surrounded = chart.surroundedPalaces(PalaceName.soul);
      expect(surrounded.target.index, soul.index);
      expect(surrounded.opposite.index, (soul.index + 6) % 12);

      final places = soul.mutagedPlaces();
      expect(places, hasLength(4));

      // Verify fliesTo matches mutagedPlaces for each mutagen.
      for (var i = 0; i < Mutagen.values.length; i++) {
        final target = places[i];
        if (target != null) {
          expect(soul.fliesTo(target.index, [Mutagen.values[i]]), isTrue);
          expect(soul.fliesOneOfTo(target.index, [Mutagen.values[i]]), isTrue);
        }
      }

      // Verify selfMutagedIn (centripetal): opposite palace stem mutagen landing here.
      for (final p in chart.palaces) {
        final opp = chart.palace((p.index + 6) % 12)!;
        final oppStars = resolveMutagenStars(opp.stem, chart.configSnapshot);
        for (var mIdx = 0; mIdx < Mutagen.values.length; mIdx++) {
          final expected = p.has([oppStars[mIdx]]);
          expect(p.selfMutagedIn([Mutagen.values[mIdx]]), expected);
        }
      }
    });

    test('star contextual queries & horoscope star/mutagen checks', () {
      final chart = Astro.bySolar('2000-8-16', 2, Gender.female);
      final ziwei = chart.star(StarKey.ziweiMaj);
      expect(ziwei.palace()?.palaceName, PalaceName.soul);
      expect(ziwei.oppositePalace()?.palaceName, PalaceName.surface);
      expect(ziwei.surroundedPalaces()?.target.index, ziwei.palace()?.index);
      expect(ziwei.withBrightness([Brightness.miao, Brightness.wang]), isTrue);

      final horo = chart.horoscope('2023-8-19 3:12');
      // 癸卯 year -> 巨门化权 in yearly scope
      final juMenPalace = chart.star(StarKey.jumenMaj).palace()!;
      final yearlyPalaceName = horo.yearly.palaceNamesEnum[juMenPalace.index];
      expect(
        horo.hasHoroscopeMutagen(yearlyPalaceName, Scope.yearly, Mutagen.quan),
        isTrue,
      );
    });
  });
}
