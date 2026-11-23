import 'package:iztro_dart/iztro_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TrueSolarTimeCalculator', () {
    test(
        'Urumqi (87.6168 E) shifts backward by ~129.5m and crosses midnight back',
        () {
      final result = TrueSolarTimeCalculator.calculate(
        DateTime(2000, 8, 16, 1, 30),
        longitude: 87.6168,
        utcOffsetMinutes: 480,
      );

      // (87.6168 * 4) - 480 = -129.5328 minutes
      expect(result.longitudeOffsetMinutes, closeTo(-129.5328, 0.001));
      expect(result.dstCorrectionMinutes, 0.0);
      expect(result.effectiveSolarDateStr, '2000-8-15');
      // ~23:16 -> late Rat hour (timeIndex 12)
      expect(result.trueSolarTime.hour, 23);
      expect(result.timeIndex, 12);
    });

    test('Kashgar (75.99 E) shifts backward by ~176m (~3 hours)', () {
      final result = TrueSolarTimeCalculator.calculate(
        DateTime(2024, 6, 15, 12, 0),
        longitude: 75.99,
        utcOffsetMinutes: 480,
      );

      expect(result.longitudeOffsetMinutes, closeTo(-176.04, 0.01));
      expect(result.trueSolarTime.hour, 9);
      expect(result.timeIndex, 5); // Si hour (09:00..10:59)
    });

    test('Chengdu (104.0668 E) shifts backward by ~63.7m', () {
      final result = TrueSolarTimeCalculator.calculate(
        DateTime(1995, 5, 20, 13, 30),
        longitude: 104.0668,
        utcOffsetMinutes: 480,
      );

      expect(result.longitudeOffsetMinutes, closeTo(-63.7328, 0.001));
      expect(result.trueSolarTime.hour, 12);
      expect(result.timeIndex, 6); // Wu hour (11:00..12:59)
      expect(result.isBoundaryWarning, isFalse);
    });

    test('Harbin (126.6424 E) shifts forward and crosses midnight on 23:30',
        () {
      final result = TrueSolarTimeCalculator.calculate(
        DateTime(2020, 11, 1, 23, 30), // EoT in early Nov is ~ +16m
        longitude: 126.6424,
        utcOffsetMinutes: 480,
      );

      // +26.57m longitude + ~16.3m EoT -> pushes 23:30 into 00:12 next day.
      expect(result.longitudeOffsetMinutes, closeTo(26.5696, 0.001));
      expect(result.equationOfTimeMinutes, greaterThan(15.0));
      expect(result.effectiveSolarDateStr, '2020-11-2');
      expect(result.trueSolarTime.hour, 0);
      expect(result.timeIndex, 0); // early Rat hour
      expect(result.isBoundaryWarning, isTrue); // ~12 min after 00:00
    });

    test('China 1988-07-15 DST deducts 60 minutes regardless of local DateTime',
        () {
      final localInput = TrueSolarTimeCalculator.calculate(
        DateTime(1988, 7, 15, 12, 30),
        longitude: 120.0,
        utcOffsetMinutes: 480,
      );
      final utcInput = TrueSolarTimeCalculator.calculate(
        DateTime.utc(1988, 7, 15, 12, 30),
        longitude: 120.0,
        utcOffsetMinutes: 480,
      );

      expect(localInput.dstCorrectionMinutes, -60.0);
      expect(localInput.meanSolarTime, DateTime.utc(1988, 7, 15, 11, 30));
      expect(localInput.trueSolarTime, utcInput.trueSolarTime);

      final withoutDst = TrueSolarTimeCalculator.calculate(
        DateTime(1988, 7, 15, 12, 30),
        longitude: 120.0,
        utcOffsetMinutes: 480,
        applyChinaDstHistory: false,
      );
      expect(withoutDst.dstCorrectionMinutes, 0.0);
      expect(withoutDst.meanSolarTime, DateTime.utc(1988, 7, 15, 12, 30));
    });

    test('China 1986 DST exact window boundaries', () {
      expect(
        TrueSolarTimeCalculator.isInChinaDst(DateTime.utc(1986, 5, 4, 1, 59)),
        isFalse,
      );
      expect(
        TrueSolarTimeCalculator.isInChinaDst(DateTime.utc(1986, 5, 4, 2, 0)),
        isTrue,
      );
      expect(
        TrueSolarTimeCalculator.isInChinaDst(DateTime.utc(1986, 9, 14, 1, 59)),
        isTrue,
      );
      expect(
        TrueSolarTimeCalculator.isInChinaDst(DateTime.utc(1986, 9, 14, 2, 0)),
        isFalse,
      );
    });

    test('Overseas timezone (New York -74.006 W, UTC-5) ignores China DST', () {
      final ny = TrueSolarTimeCalculator.calculate(
        DateTime(1988, 7, 15, 12, 0),
        longitude: -74.006,
        utcOffsetMinutes: -300,
        applyChinaDstHistory: true,
      );

      expect(ny.dstCorrectionMinutes, 0.0);
      // (-74.006 * 4) - (-300) = +3.976 min
      expect(ny.longitudeOffsetMinutes, closeTo(3.976, 0.001));
      expect(ny.effectiveSolarDateStr, '1988-7-15');
      expect(ny.timeIndex, 6); // 11:xx -> Wu hour
    });

    test('23:30 late Rat in Urumqi rolls back to 21:xx same day', () {
      final result = TrueSolarTimeCalculator.calculate(
        DateTime(2024, 3, 21, 23, 30),
        longitude: 87.6168,
        utcOffsetMinutes: 480,
      );

      expect(result.effectiveSolarDateStr, '2024-3-21');
      expect(result.trueSolarTime.hour, 21);
      expect(result.timeIndex, 11); // Hai hour (21:00..22:59)
    });

    test('boundary warning flags points <= 15m from two-hour edges', () {
      // 120.0 E on equinox-like EoT (~0): 00:50 -> 10m from 01:00 boundary.
      final near = TrueSolarTimeCalculator.calculate(
        DateTime(2024, 4, 15, 0, 50),
        longitude: 120.0,
        utcOffsetMinutes: 480,
      );
      expect(near.minutesToNearestBoundary, lessThanOrEqualTo(15.0));
      expect(near.isBoundaryWarning, isTrue);

      // 12:00 noon is ~60m away from 11:00 and 13:00 boundaries.
      final safe = TrueSolarTimeCalculator.calculate(
        DateTime(2024, 4, 15, 12, 0),
        longitude: 120.0,
        utcOffsetMinutes: 480,
      );
      expect(safe.minutesToNearestBoundary, greaterThan(50.0));
      expect(safe.isBoundaryWarning, isFalse);
    });
  });
}
