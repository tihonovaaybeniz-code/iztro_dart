import '../core/types.dart';
import '../star/functional_star.dart';
import 'functional_astrolabe.dart';
import 'functional_palace.dart';
import 'functional_surpalaces.dart';
import 'horoscope_calc.dart';

/// Six-layer horoscope object (`decadal`, `age`, `yearly`, `monthly`, `daily`,
/// `hourly`) with chainable query methods, matching
/// `iztro@2.6.5#FunctionalHoroscope`.
class FunctionalHoroscope {
  const FunctionalHoroscope({
    required this.solarDate,
    required this.lunarDate,
    required this.decadal,
    required this.age,
    required this.yearly,
    required this.monthly,
    required this.daily,
    required this.hourly,
    required this.astrolabe,
    required this.isChildhood,
  });

  final String solarDate;
  final String lunarDate;
  final HoroscopeItem decadal;
  final AgeHoroscopeItem age;
  final YearlyHoroscopeItem yearly;
  final HoroscopeItem monthly;
  final HoroscopeItem daily;
  final HoroscopeItem hourly;
  final FunctionalAstrolabe astrolabe;
  final bool isChildhood;

  /// Returns the natal palace corresponding to the current small-limit age.
  FunctionalPalace? agePalace() => astrolabe.palace(age.index);

  /// Returns the natal palace carrying [palaceName] under the specified [scope].
  FunctionalPalace? palace(PalaceName palaceName, Scope scope) {
    final idx = _getHoroscopePalaceIndex(scope, palaceName);
    return idx < 0 ? null : astrolabe.palace(idx);
  }

  /// Returns surrounded palaces (三方四正) of [palaceName] under [scope].
  FunctionalSurpalaces? surroundPalaces(PalaceName palaceName, Scope scope) {
    final idx = _getHoroscopePalaceIndex(scope, palaceName);
    return idx < 0 ? null : astrolabe.surroundedPalaces(idx);
  }

  /// Checks whether ALL [horoscopeStars] appear in the merged decadal + yearly
  /// flow stars at [palaceName] under [scope].
  bool hasHoroscopeStars(
    PalaceName palaceName,
    Scope scope,
    List<StarKey> horoscopeStars,
  ) {
    final starKeys = _mergedDecadalYearlyKeys(palaceName, scope);
    if (starKeys == null) {
      return false;
    }
    return horoscopeStars.every(starKeys.contains);
  }

  /// Checks whether NONE of [horoscopeStars] appear in the merged decadal +
  /// yearly flow stars at [palaceName] under [scope].
  bool notHaveHoroscopeStars(
    PalaceName palaceName,
    Scope scope,
    List<StarKey> horoscopeStars,
  ) {
    final starKeys = _mergedDecadalYearlyKeys(palaceName, scope);
    if (starKeys == null) {
      return false;
    }
    return horoscopeStars.every((s) => !starKeys.contains(s));
  }

  /// Checks whether AT LEAST ONE of [horoscopeStars] appears in the merged
  /// decadal + yearly flow stars at [palaceName] under [scope].
  bool hasOneOfHoroscopeStars(
    PalaceName palaceName,
    Scope scope,
    List<StarKey> horoscopeStars,
  ) {
    final starKeys = _mergedDecadalYearlyKeys(palaceName, scope);
    if (starKeys == null) {
      return false;
    }
    return horoscopeStars.any(starKeys.contains);
  }

  /// Checks whether the palace carrying [palaceName] in [scope] contains a
  /// star triggered by [horoscopeMutagen] of that [scope].
  bool hasHoroscopeMutagen(
    PalaceName palaceName,
    Scope scope,
    Mutagen horoscopeMutagen,
  ) {
    if (scope == Scope.origin) {
      return false;
    }
    final idx = _getHoroscopePalaceIndex(scope, palaceName);
    if (idx < 0) {
      return false;
    }
    final targetPalace = astrolabe.palace(idx);
    if (targetPalace == null) {
      return false;
    }
    final palaceStarKeys = <StarKey>{
      for (final s in targetPalace.majorStars) s.key,
      for (final s in targetPalace.minorStars) s.key,
    };
    final scopeMutagenStar =
        _scopeItem(scope).mutagenKeys[horoscopeMutagen.index];
    return palaceStarKeys.contains(scopeMutagenStar);
  }

  HoroscopeItem _scopeItem(Scope scope) {
    return switch (scope) {
      Scope.origin => throw ArgumentError.value(scope, 'scope'),
      Scope.decadal => decadal,
      Scope.yearly => yearly,
      Scope.monthly => monthly,
      Scope.daily => daily,
      Scope.hourly => hourly,
    };
  }

  int _getHoroscopePalaceIndex(Scope scope, PalaceName palaceName) {
    if (scope == Scope.origin) {
      return astrolabe.palace(palaceName)?.index ?? -1;
    }
    return _scopeItem(scope).palaceNamesEnum.indexOf(palaceName);
  }

  Set<StarKey>? _mergedDecadalYearlyKeys(PalaceName palaceName, Scope scope) {
    final decadalStars = decadal.stars;
    final yearlyStars = yearly.stars;
    if (decadalStars == null || yearlyStars == null) {
      return null;
    }
    final idx = _getHoroscopePalaceIndex(scope, palaceName);
    if (idx < 0) {
      return null;
    }
    return <StarKey>{
      for (final FunctionalStar s in decadalStars[idx]) s.key,
      for (final FunctionalStar s in yearlyStars[idx]) s.key,
    };
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lunarDate': lunarDate,
        'solarDate': solarDate,
        'decadal': decadal.toJson(),
        'age': age.toJson(),
        'yearly': yearly.toJson(),
        'monthly': monthly.toJson(),
        'daily': daily.toJson(),
        'hourly': hourly.toJson(),
      };
}
