import '../calendar/calendar_adapter.dart';
import '../core/config.dart';
import '../core/index_math.dart';
import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import '../star/functional_star.dart';
import 'functional_palace.dart';

/// Raw date snapshot stored inside [FunctionalAstrolabe], aligned with
/// `iztro`'s `astrolabe.rawDates`.
class AstrolabeRawDates {
  const AstrolabeRawDates({
    required this.lunarDate,
    required this.chineseDate,
    required this.boundarySolarYear,
    required this.boundarySolarMonth,
    required this.boundarySolarDay,
    required this.boundaryTimeIndex,
  });

  final LunarDateInfo lunarDate;
  final LunarDateInfo chineseDate;
  final int boundarySolarYear;
  final int boundarySolarMonth;
  final int boundarySolarDay;
  final int boundaryTimeIndex;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lunarDate': <String, dynamic>{
          'lunarYear': lunarDate.lunarYear,
          'lunarMonth': lunarDate.lunarMonth,
          'lunarDay': lunarDate.lunarDay,
          'isLeap': lunarDate.isLeapMonth,
        },
        'chineseDate': <String, dynamic>{
          'yearly': <String>[lunarDate.yearStem.zh, lunarDate.yearBranch.zh],
          'monthly': <String>[lunarDate.monthStem.zh, lunarDate.monthBranch.zh],
          'daily': <String>[lunarDate.dayStem.zh, lunarDate.dayBranch.zh],
          'hourly': <String>[lunarDate.hourStem.zh, lunarDate.hourBranch.zh],
        },
      };
}

/// Complete Ziwei Doushu astrolabe object with immutable configuration and
/// calendar snapshots, aligned with `iztro@2.6.5#FunctionalAstrolabe`.
class FunctionalAstrolabe {
  FunctionalAstrolabe({
    required this.genderValue,
    required this.solarDate,
    required this.lunarDate,
    required this.chineseDate,
    required this.rawDates,
    required this.timeIndex,
    required this.time,
    required this.timeRange,
    required this.sign,
    required this.zodiac,
    required this.soulPalaceBranch,
    required this.bodyPalaceBranch,
    required this.soulStarKey,
    required this.bodyStarKey,
    required this.fiveElementsClassEnum,
    required this.palaces,
    required this.copyright,
    required this.configSnapshot,
    required this.calendarAdapter,
    required this.fixLeap,
    required this.astroType,
  }) {
    bindContext();
  }

  /// Gender enum.
  final Gender genderValue;

  /// Localized gender display text (matches `astrolabe.gender` in `iztro`).
  String get gender =>
      LocaleRegistry.translate(genderValue.key, configSnapshot.language);

  /// Original solar input date string (`YYYY-M-D`).
  final String solarDate;

  /// Formatted lunar date string according to chart language.
  final String lunarDate;

  /// Formatted four-pillar Chinese date string according to chart language.
  final String chineseDate;

  /// Raw calendar & pillar snapshot.
  final AstrolabeRawDates rawDates;

  /// Original birth time index (`0..12`).
  final int timeIndex;

  /// Localized birth hour label (e.g. `寅时`).
  final String time;

  /// Wall-clock range string (e.g. `03:00~05:00`).
  final String timeRange;

  /// Localized constellation sign.
  final String sign;

  /// Localized zodiac animal.
  final String zodiac;

  /// Earthly branch of Soul Palace (updated during earth/human rearrange).
  EarthlyBranch soulPalaceBranch;

  /// Earthly branch of Body Palace.
  EarthlyBranch bodyPalaceBranch;

  /// Localized Soul Palace branch (`命宫地支`).
  String get earthlyBranchOfSoulPalace =>
      LocaleRegistry.translate(soulPalaceBranch.key, configSnapshot.language);

  /// Localized Body Palace branch (`身宫地支`).
  String get earthlyBranchOfBodyPalace =>
      LocaleRegistry.translate(bodyPalaceBranch.key, configSnapshot.language);

  /// Soul star key (`命主`).
  final StarKey soulStarKey;

  /// Body star key (`身主`).
  final StarKey bodyStarKey;

  /// Localized Soul star (`命主`).
  String get soul =>
      LocaleRegistry.translate(soulStarKey.key, configSnapshot.language);

  /// Localized Body star (`身主`).
  String get body =>
      LocaleRegistry.translate(bodyStarKey.key, configSnapshot.language);

  /// Five Elements Class enum (updated during earth/human rearrange).
  FiveElementsClass fiveElementsClassEnum;

  /// Localized Five Elements Class (`水二局` .. `火六局`).
  String get fiveElementsClass => LocaleRegistry.translate(
        fiveElementsClassEnum.key,
        configSnapshot.language,
      );

  /// Twelve palaces ordered `0 = 寅 .. 11 = 丑`.
  final List<FunctionalPalace> palaces;

  /// Upstream attribution copyright string.
  final String copyright;

  /// Immutable configuration snapshot captured when generating this chart.
  final ResolvedAstroConfig configSnapshot;

  /// Calendar adapter snapshot captured when generating this chart.
  final LunarCalendarAdapter calendarAdapter;

  /// Leap-month adjustment option captured at creation.
  final bool fixLeap;

  /// Chart type (`heaven`, `earth`, or `human`).
  final AstroType astroType;

  /// Re-binds palace and star back-references after creation or rearrangement.
  void bindContext() {
    for (final palace in palaces) {
      palace.bindAstrolabe(this);
    }
  }

  /// Looks up a palace by [PalaceName], `int` index (`0..11`), or localized
  /// palace name [String].
  FunctionalPalace? palace(Object indexOrName) {
    if (indexOrName is int) {
      if (indexOrName < 0 || indexOrName >= palaces.length) {
        return null;
      }
      return palaces[indexOrName];
    }
    if (indexOrName is PalaceName) {
      for (final p in palaces) {
        if (p.palaceName == indexOrName) {
          return p;
        }
      }
      return null;
    }
    if (indexOrName is String) {
      final parsed = LocaleRegistry.tryParsePalaceName(indexOrName);
      if (parsed == null) {
        return null;
      }
      for (final p in palaces) {
        if (p.palaceName == parsed) {
          return p;
        }
      }
      return null;
    }
    throw ArgumentError.value(
      indexOrName,
      'indexOrName',
      'Expected int, PalaceName, or localized String.',
    );
  }

  /// Convenience UI lookup by [EarthlyBranch] (`子=0 .. 亥=11` widgets can call
  /// `palaceAtBranch(EarthlyBranch.zi)` without manual `-2` index conversion).
  FunctionalPalace palaceAtBranch(EarthlyBranch branch) {
    return palaces[earthlyBranchToPalaceIndex(branch)];
  }

  /// Finds a star in the natal chart by [StarKey] or localized star [String].
  FunctionalStar star(Object starKeyOrName) {
    final StarKey? key;
    if (starKeyOrName is StarKey) {
      key = starKeyOrName;
    } else if (starKeyOrName is String) {
      key = LocaleRegistry.tryParseStarKey(starKeyOrName);
    } else {
      throw ArgumentError.value(
        starKeyOrName,
        'starKeyOrName',
        'Expected StarKey or String.',
      );
    }

    if (key != null) {
      for (final p in palaces) {
        for (final s in p.allStars) {
          if (s.key == key) {
            s.bindPalace(p);
            s.bindAstrolabe(this);
            return s;
          }
        }
      }
    }
    throw ArgumentError.value(
      starKeyOrName,
      'starKeyOrName',
      'invalid star name.',
    );
  }

  /// Serializes the astrolabe to an `iztro`-compatible plain JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'gender': gender,
        'solarDate': solarDate,
        'lunarDate': lunarDate,
        'chineseDate': chineseDate,
        'rawDates': rawDates.toJson(),
        'time': time,
        'timeRange': timeRange,
        'sign': sign,
        'zodiac': zodiac,
        'earthlyBranchOfSoulPalace': earthlyBranchOfSoulPalace,
        'earthlyBranchOfBodyPalace': earthlyBranchOfBodyPalace,
        'soul': soul,
        'body': body,
        'fiveElementsClass': fiveElementsClass,
        'palaces': palaces.map((p) => p.toJson()).toList(growable: false),
        'copyright': copyright,
      };
}
