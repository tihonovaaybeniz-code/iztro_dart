import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import '../star/functional_star.dart';

/// A single horoscope layer item (大限 / 小限 / 流年 / 流月 / 流日 / 流时).
class HoroscopeItem {
  const HoroscopeItem({
    required this.index,
    required this.name,
    required this.stem,
    required this.branch,
    required this.palaceNamesEnum,
    required this.mutagenKeys,
    this.stars,
    this.language = AstroLanguage.zhCN,
  });

  final int index;
  final String name;
  final HeavenlyStem stem;
  final EarthlyBranch branch;
  final List<PalaceName> palaceNamesEnum;
  final List<StarKey> mutagenKeys;
  final List<List<FunctionalStar>>? stars;
  final AstroLanguage language;

  String get heavenlyStem => LocaleRegistry.translate(stem.key, language);

  String get earthlyBranch => LocaleRegistry.translate(branch.key, language);

  List<String> get palaceNames => palaceNamesEnum
      .map((p) => LocaleRegistry.translate(p.key, language))
      .toList(growable: false);

  List<String> get mutagen => mutagenKeys
      .map((s) => LocaleRegistry.translate(s.key, language))
      .toList(growable: false);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'index': index,
      'name': name,
      'heavenlyStem': heavenlyStem,
      'earthlyBranch': earthlyBranch,
      'palaceNames': palaceNames,
      'mutagen': mutagen,
    };
    if (stars != null) {
      map['stars'] = stars!
          .map(
            (list) => list.map((s) => s.toJson()).toList(growable: false),
          )
          .toList(growable: false);
    }
    return map;
  }
}

/// Small-limit (小限) horoscope item with [nominalAge].
class AgeHoroscopeItem extends HoroscopeItem {
  const AgeHoroscopeItem({
    required super.index,
    required super.name,
    required super.stem,
    required super.branch,
    required super.palaceNamesEnum,
    required super.mutagenKeys,
    required this.nominalAge,
    super.language,
  });

  final int nominalAge;

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['nominalAge'] = nominalAge;
    return map;
  }
}

/// Yearly (流年) horoscope item including `jiangqian12` and `suiqian12`.
class YearlyHoroscopeItem extends HoroscopeItem {
  const YearlyHoroscopeItem({
    required super.index,
    required super.name,
    required super.stem,
    required super.branch,
    required super.palaceNamesEnum,
    required super.mutagenKeys,
    required super.stars,
    required this.jiangqian12,
    required this.suiqian12,
    super.language,
  });

  final List<String> jiangqian12;
  final List<String> suiqian12;

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['yearlyDecStar'] = <String, dynamic>{
      'jiangqian12': jiangqian12,
      'suiqian12': suiqian12,
    };
    return map;
  }
}

/// Decadal list item returned by `FunctionalAstrolabe.decadalList()`.
class DecadalHoroscope extends HoroscopeItem {
  const DecadalHoroscope({
    required super.index,
    required super.name,
    required this.palaceNameEnum,
    required this.ageRange,
    required this.yearRange,
    required super.stem,
    required super.branch,
    required super.palaceNamesEnum,
    required super.mutagenKeys,
    required super.stars,
    super.language,
  });

  final PalaceName palaceNameEnum;
  final (int start, int end) ageRange;
  final (int start, int end) yearRange;

  String get palaceName =>
      LocaleRegistry.translate(palaceNameEnum.key, language);

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['palaceName'] = palaceName;
    map['ageRange'] = <int>[ageRange.$1, ageRange.$2];
    map['yearRange'] = <int>[yearRange.$1, yearRange.$2];
    return map;
  }
}

/// Yearly list item returned by `FunctionalAstrolabe.yearlyList()`.
class YearlyHoroscopeEntry extends HoroscopeItem {
  const YearlyHoroscopeEntry({
    required super.index,
    required super.name,
    required this.age,
    required this.year,
    required super.stem,
    required super.branch,
    required super.palaceNamesEnum,
    required super.mutagenKeys,
    required super.stars,
    super.language,
  });

  final int age;
  final int year;

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['age'] = age;
    map['year'] = year;
    return map;
  }
}

/// Leap-month segment classification for `monthlyList()`.
enum MonthlyPart {
  normal('normal'),
  first('first'),
  second('second');

  const MonthlyPart(this.key);

  final String key;
}

/// Monthly list item returned by `FunctionalAstrolabe.monthlyList()`.
class MonthlyHoroscopeEntry extends HoroscopeItem {
  const MonthlyHoroscopeEntry({
    required super.index,
    required super.name,
    required this.age,
    required this.year,
    required this.month,
    required this.isLeapMonth,
    required this.part,
    required this.dayRange,
    required super.stem,
    required super.branch,
    required super.palaceNamesEnum,
    required super.mutagenKeys,
    required super.stars,
    super.language,
  });

  final int age;
  final int year;
  final int month;
  final bool isLeapMonth;
  final MonthlyPart part;
  final (int start, int end) dayRange;

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['age'] = age;
    map['year'] = year;
    map['month'] = month;
    map['isLeapMonth'] = isLeapMonth;
    map['part'] = part.key;
    map['dayRange'] = <int>[dayRange.$1, dayRange.$2];
    return map;
  }
}
