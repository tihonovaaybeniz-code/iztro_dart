import '../../calendar/calendar_adapter.dart';
import '../../core/types.dart';
import 'en_us.dart';
import 'ja_jp.dart';
import 'ko_kr.dart';
import 'star_aliases.dart';
import 'vi_vn.dart';
import 'zh_cn.dart';
import 'zh_tw.dart';

/// Built-in localization lookup and reverse-lookup (`kot`) registry,
/// aligned with `iztro/src/i18n/index.ts` (`v2.6.5`).
abstract final class LocaleRegistry {
  static const Map<AstroLanguage, Map<String, String>> _resources = {
    AstroLanguage.enUS: enUsTranslations,
    AstroLanguage.jaJP: jaJpTranslations,
    AstroLanguage.koKR: koKrTranslations,
    AstroLanguage.zhCN: zhCnTranslations,
    AstroLanguage.zhTW: zhTwTranslations,
    AstroLanguage.viVN: viVnTranslations,
  };

  /// Translates [key] into [language], interpolating `{{name}}` placeholders
  /// when [params] are supplied.
  static String translate(
    String key,
    AstroLanguage language, {
    Map<String, Object>? params,
  }) {
    if (key.isEmpty) {
      return '';
    }
    var result = _resources[language]?[key] ?? key;
    if (params != null && params.isNotEmpty) {
      for (final entry in params.entries) {
        result = result.replaceAll('{{${entry.key}}}', '${entry.value}');
      }
    }
    return result;
  }

  /// Reverse lookup (`kot` = Key of Translation), returning the canonical
  /// `iztro` key for any supported localized [value], or [value] if unmatched.
  static String kot(String value, {String? filter}) {
    final alias = starAliases[value];
    if (alias != null) {
      return alias.key;
    }

    for (final dict in _resources.values) {
      for (final entry in dict.entries) {
        if ((filter == null || entry.key.contains(filter)) &&
            entry.value == value) {
          return entry.key;
        }
      }
    }
    return value;
  }

  /// Formats [info] lunar date according to [language], matching `astro.ts`.
  static String formatLunarDate(LunarDateInfo info, AstroLanguage language) {
    if (language == AstroLanguage.zhCN || language == AstroLanguage.zhTW) {
      return info.lunarDateChinese;
    }
    return translate(
      'lunarDate',
      language,
      params: {
        'year': info.lunarYear,
        'month': info.lunarMonth,
        'day': info.lunarDay,
        'leapMonth': info.isLeapMonth ? translate('leapMonth', language) : '',
      },
    );
  }

  /// Formats the four pillars of [info] in [language], matching
  /// `translateChineseDate` in `iztro/src/utils/index.ts`.
  static String translateChineseDate(
    LunarDateInfo info,
    AstroLanguage language,
  ) {
    final parts = [
      translate(info.yearStem.key, language),
      translate(info.yearBranch.key, language),
      translate(info.monthStem.key, language),
      translate(info.monthBranch.key, language),
      translate(info.dayStem.key, language),
      translate(info.dayBranch.key, language),
      translate(info.hourStem.key, language),
      translate(info.hourBranch.key, language),
    ];
    final hasMultiChar = parts.any((item) => item.length > 1);
    if (hasMultiChar) {
      return '${parts[0]} ${parts[1]} - ${parts[2]} ${parts[3]} - ${parts[4]} ${parts[5]} - ${parts[6]} ${parts[7]}';
    }
    return '${parts[0]}${parts[1]} ${parts[2]}${parts[3]} ${parts[4]}${parts[5]} ${parts[6]}${parts[7]}';
  }

  /// Parses a localized or canonical gender string into [Gender].
  static Gender parseGender(String value) {
    final key = kot(value);
    if (key == Gender.male.key) {
      return Gender.male;
    }
    if (key == Gender.female.key) {
      return Gender.female;
    }
    throw ArgumentError.value(value, 'gender', 'invalid gender.');
  }

  /// Parses a localized or canonical Heavenly Stem string.
  static HeavenlyStem parseHeavenlyStem(String value) {
    final direct = HeavenlyStem.tryParse(value);
    if (direct != null) {
      return direct;
    }
    final key = kot(value, filter: 'Heavenly');
    final parsed = HeavenlyStem.tryParse(key);
    if (parsed != null) {
      return parsed;
    }
    throw ArgumentError.value(value, 'heavenlyStem', 'Invalid HeavenlyStem.');
  }

  /// Parses a localized or canonical Earthly Branch string.
  static EarthlyBranch parseEarthlyBranch(String value) {
    final direct = EarthlyBranch.tryParse(value);
    if (direct != null) {
      return direct;
    }
    final key = kot(value, filter: 'Earthly');
    final parsed = EarthlyBranch.tryParse(key);
    if (parsed != null) {
      return parsed;
    }
    throw ArgumentError.value(value, 'earthlyBranch', 'Invalid EarthlyBranch.');
  }

  /// Parses a localized or canonical palace name string.
  static PalaceName? tryParsePalaceName(String value) {
    final direct = PalaceName.tryFromKey(value);
    if (direct != null) {
      return direct;
    }
    final key = kot(value, filter: 'Palace');
    return PalaceName.tryFromKey(key);
  }

  /// Parses a localized, aliased, or canonical star name string.
  static StarKey? tryParseStarKey(String value) {
    final direct = StarKey.tryFromKey(value);
    if (direct != null) {
      return direct;
    }
    final key = kot(value);
    return StarKey.tryFromKey(key);
  }

  /// Parses a localized or canonical mutagen string.
  static Mutagen? tryParseMutagen(String value) {
    final direct = Mutagen.tryFromKey(value);
    if (direct != null) {
      return direct;
    }
    final key = kot(value);
    return Mutagen.tryFromKey(key);
  }

  /// Parses a localized or canonical brightness string.
  static Brightness? tryParseBrightness(String value) {
    final direct = Brightness.tryFromKey(value);
    if (direct != null) {
      return direct;
    }
    final key = kot(value);
    return Brightness.tryFromKey(key);
  }
}
