import 'dart:math' as math;

import '../core/index_math.dart';

/// Result of converting a civil wall-clock timestamp to True Solar Time.
class TrueSolarTimeResult {
  const TrueSolarTimeResult({
    required this.civilTime,
    required this.meanSolarTime,
    required this.trueSolarTime,
    required this.longitudeOffsetMinutes,
    required this.equationOfTimeMinutes,
    required this.dstCorrectionMinutes,
    required this.effectiveSolarDate,
    required this.timeIndex,
    required this.minutesToNearestBoundary,
    required this.isBoundaryWarning,
  });

  /// Input civil clock time normalized into UTC-tagged wall components
  /// (free from host OS timezone/DST mutation).
  final DateTime civilTime;

  /// Local mean solar time (`civilTime + longitudeOffset + dstCorrection`).
  final DateTime meanSolarTime;

  /// True solar time (`meanSolarTime + equationOfTime`).
  final DateTime trueSolarTime;

  /// Longitude correction relative to the standard timezone meridian in
  /// minutes: `longitude * 4.0 - utcOffsetMinutes`.
  final double longitudeOffsetMinutes;

  /// Equation of Time (EoT) correction in minutes.
  final double equationOfTimeMinutes;

  /// Historical China DST correction applied (`-60.0` if active, else `0.0`).
  final double dstCorrectionMinutes;

  /// Calendar date (`YYYY-M-D` UTC date) after true solar time rollover.
  final DateTime effectiveSolarDate;

  /// Chinese two-hour period index (`0..12`):
  /// `0` = early Rat (`00:00–00:59`), `1..11` = Ox..Pig, `12` = late Rat (`23:00–23:59`).
  final int timeIndex;

  /// Distance in minutes from [trueSolarTime] to the nearest two-hour period
  /// boundary (`00:00`, `01:00`, `03:00`, ..., `23:00`, `24:00`).
  final double minutesToNearestBoundary;

  /// `true` when [minutesToNearestBoundary] is within the configured warning
  /// threshold (default `<= 15.0` minutes).
  final bool isBoundaryWarning;

  /// Canonical `YYYY-M-D` string for [effectiveSolarDate].
  String get effectiveSolarDateStr =>
      '${effectiveSolarDate.year}-${effectiveSolarDate.month}-${effectiveSolarDate.day}';
}

/// Pure mathematical True Solar Time (真太阳时) calculator.
///
/// Does not bundle any city/geocoding database: callers provide the birth
/// [longitude], standard [utcOffsetMinutes], and wall-clock [civilTime].
abstract final class TrueSolarTimeCalculator {
  /// Mainland China historical Daylight Saving Time windows (1986–1991),
  /// expressed in civil wall-clock boundaries `[start, end)`.
  static final List<(DateTime start, DateTime end)> _chinaDstWindows = [
    (DateTime.utc(1986, 5, 4, 2), DateTime.utc(1986, 9, 14, 2)),
    (DateTime.utc(1987, 4, 12, 2), DateTime.utc(1987, 9, 13, 2)),
    (DateTime.utc(1988, 4, 10, 2), DateTime.utc(1988, 9, 11, 2)),
    (DateTime.utc(1989, 4, 16, 2), DateTime.utc(1989, 9, 17, 2)),
    (DateTime.utc(1990, 4, 15, 2), DateTime.utc(1990, 9, 16, 2)),
    (DateTime.utc(1991, 4, 14, 2), DateTime.utc(1991, 9, 15, 2)),
  ];

  static const List<double> _hourBoundaryMinutes = [
    0.0,
    60.0,
    180.0,
    300.0,
    420.0,
    540.0,
    660.0,
    780.0,
    900.0,
    1020.0,
    1140.0,
    1260.0,
    1380.0,
    1440.0,
  ];

  /// Computes True Solar Time for [civilTime].
  ///
  /// - [longitude]: east positive, west negative (`-180.0..180.0`).
  /// - [utcOffsetMinutes]: standard timezone offset from UTC in minutes
  ///   (e.g. `480` for UTC+8 Beijing, `-300` for UTC-5 New York EST).
  /// - [applyChinaDstHistory]: when `true` and `utcOffsetMinutes == 480`,
  ///   automatically deducts 60 minutes during 1986–1991 Mainland China DST.
  /// - [boundaryWarningMinutes]: threshold for [TrueSolarTimeResult.isBoundaryWarning].
  ///
  /// Wall-clock arithmetic is performed in UTC-tagged components to avoid host
  /// OS timezone/DST shifts on local `DateTime` objects.
  static TrueSolarTimeResult calculate(
    DateTime civilTime, {
    required double longitude,
    required int utcOffsetMinutes,
    bool applyChinaDstHistory = true,
    double boundaryWarningMinutes = 15.0,
  }) {
    if (longitude < -180.0 || longitude > 180.0 || !longitude.isFinite) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Longitude must be within [-180, 180].',
      );
    }

    final civilWall = DateTime.utc(
      civilTime.year,
      civilTime.month,
      civilTime.day,
      civilTime.hour,
      civilTime.minute,
      civilTime.second,
      civilTime.millisecond,
      civilTime.microsecond,
    );

    final inChinaDst = applyChinaDstHistory &&
        utcOffsetMinutes == 480 &&
        isInChinaDst(civilWall);
    final dstCorrectionMinutes = inChinaDst ? -60.0 : 0.0;

    final standardWall = civilWall.add(
      Duration(minutes: dstCorrectionMinutes.round()),
    );
    final dayOfYear = _dayOfYear(standardWall);
    final eotMinutes = equationOfTimeMinutes(dayOfYear);
    final longitudeOffsetMinutes = longitude * 4.0 - utcOffsetMinutes;

    final meanSolarTime = civilWall.add(
      Duration(
        microseconds:
            ((longitudeOffsetMinutes + dstCorrectionMinutes) * 60000000.0)
                .round(),
      ),
    );
    final trueSolarTime = meanSolarTime.add(
      Duration(microseconds: (eotMinutes * 60000000.0).round()),
    );

    final effectiveSolarDate = DateTime.utc(
      trueSolarTime.year,
      trueSolarTime.month,
      trueSolarTime.day,
    );
    final timeIndex = timeToIndex(trueSolarTime.hour);

    final minuteOfDay = trueSolarTime.hour * 60.0 +
        trueSolarTime.minute +
        trueSolarTime.second / 60.0 +
        trueSolarTime.millisecond / 60000.0;
    var minDistance = double.infinity;
    for (final boundary in _hourBoundaryMinutes) {
      final distance = (minuteOfDay - boundary).abs();
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return TrueSolarTimeResult(
      civilTime: civilWall,
      meanSolarTime: meanSolarTime,
      trueSolarTime: trueSolarTime,
      longitudeOffsetMinutes: longitudeOffsetMinutes,
      equationOfTimeMinutes: eotMinutes,
      dstCorrectionMinutes: dstCorrectionMinutes,
      effectiveSolarDate: effectiveSolarDate,
      timeIndex: timeIndex,
      minutesToNearestBoundary: minDistance,
      isBoundaryWarning: minDistance <= boundaryWarningMinutes,
    );
  }

  /// Returns `true` if wall-clock [civilWall] falls within Mainland China's
  /// 1986–1991 historical Daylight Saving Time windows.
  static bool isInChinaDst(DateTime civilWall) {
    final normalized = DateTime.utc(
      civilWall.year,
      civilWall.month,
      civilWall.day,
      civilWall.hour,
      civilWall.minute,
      civilWall.second,
      civilWall.millisecond,
    );
    for (final (start, end) in _chinaDstWindows) {
      if (!normalized.isBefore(start) && normalized.isBefore(end)) {
        return true;
      }
    }
    return false;
  }

  /// Computes Equation of Time in minutes for 1-based [dayOfYear].
  static double equationOfTimeMinutes(int dayOfYear) {
    final b = 2.0 * math.pi * (dayOfYear - 81) / 365.0;
    return 9.87 * math.sin(2.0 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);
  }

  static int _dayOfYear(DateTime date) {
    final jan1 = DateTime.utc(date.year, 1, 1);
    final current = DateTime.utc(date.year, date.month, date.day);
    return current.difference(jan1).inDays + 1;
  }
}
