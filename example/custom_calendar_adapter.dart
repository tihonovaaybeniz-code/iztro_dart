import 'package:iztro_dart/iztro_dart.dart';

/// Minimal example showing how a host app can plug in an existing lunar
/// calendar engine by extending [BaseLunarCalendarAdapter].
final class DemoCustomLunarAdapter extends BaseLunarCalendarAdapter {
  const DemoCustomLunarAdapter();

  @override
  LunarDateInfo solarToLunar(
    int year,
    int month,
    int day, {
    required int timeIndex,
    required DivideType yearDivide,
    required DivideType horoscopeDivide,
  }) {
    // Replace with calls into your host calendar engine (e.g. calendar_core).
    return const DefaultLunarAdapter().solarToLunar(
      year,
      month,
      day,
      timeIndex: timeIndex,
      yearDivide: yearDivide,
      horoscopeDivide: horoscopeDivide,
    );
  }

  @override
  ({int year, int month, int day}) lunarToSolar(
    int lunarYear,
    int lunarMonth,
    int lunarDay, {
    bool isLeapMonth = false,
  }) {
    return const DefaultLunarAdapter().lunarToSolar(
      lunarYear,
      lunarMonth,
      lunarDay,
      isLeapMonth: isLeapMonth,
    );
  }
}

void main() {
  final chart = Astro.bySolar(
    '2000-8-16',
    2,
    Gender.female,
    calendar: const DemoCustomLunarAdapter(),
  );
  print(
      'Custom adapter chart: ${chart.lunarDate} / ${chart.fiveElementsClass}');
}
