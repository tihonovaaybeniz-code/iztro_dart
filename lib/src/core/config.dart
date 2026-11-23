import 'types.dart';

/// User-supplied partial configuration overrides for `iztro_dart`.
class AstroConfig {
  const AstroConfig({
    this.language,
    this.yearDivide,
    this.horoscopeDivide,
    this.ageDivide,
    this.dayDivide,
    this.algorithm,
    this.mutagens,
    this.brightness,
  });

  final AstroLanguage? language;
  final DivideType? yearDivide;
  final DivideType? horoscopeDivide;
  final AgeDivideType? ageDivide;
  final DayDivideType? dayDivide;
  final Algorithm? algorithm;

  /// Custom mutagen table overrides keyed by [HeavenlyStem].
  /// Each value list maps `[禄, 权, 科, 忌]` to 4 [StarKey] entries.
  final Map<HeavenlyStem, List<StarKey>>? mutagens;

  /// Custom star brightness overrides keyed by [StarKey].
  /// Each value list holds 12 entries ordered from 寅 (index 0) to 丑 (index 11).
  final Map<StarKey, List<Brightness?>>? brightness;
}

/// Immutable resolved configuration snapshot captured by an astrolabe instance.
class ResolvedAstroConfig {
  ResolvedAstroConfig({
    this.language = AstroLanguage.zhCN,
    this.yearDivide = DivideType.normal,
    this.horoscopeDivide = DivideType.normal,
    this.ageDivide = AgeDivideType.normal,
    this.dayDivide = DayDivideType.forward,
    this.algorithm = Algorithm.defaultAlgorithm,
    Map<HeavenlyStem, List<StarKey>>? mutagens,
    Map<StarKey, List<Brightness?>>? brightness,
  })  : mutagens = _freezeMutagens(mutagens),
        brightness = _freezeBrightness(brightness);

  final AstroLanguage language;
  final DivideType yearDivide;
  final DivideType horoscopeDivide;
  final AgeDivideType ageDivide;
  final DayDivideType dayDivide;
  final Algorithm algorithm;
  final Map<HeavenlyStem, List<StarKey>> mutagens;
  final Map<StarKey, List<Brightness?>> brightness;

  static Map<HeavenlyStem, List<StarKey>> _freezeMutagens(
    Map<HeavenlyStem, List<StarKey>>? source,
  ) {
    if (source == null || source.isEmpty) {
      return const {};
    }
    return Map<HeavenlyStem, List<StarKey>>.unmodifiable({
      for (final entry in source.entries)
        entry.key: List<StarKey>.unmodifiable(entry.value),
    });
  }

  static Map<StarKey, List<Brightness?>> _freezeBrightness(
    Map<StarKey, List<Brightness?>>? source,
  ) {
    if (source == null || source.isEmpty) {
      return const {};
    }
    return Map<StarKey, List<Brightness?>>.unmodifiable({
      for (final entry in source.entries)
        entry.key: List<Brightness?>.unmodifiable(entry.value),
    });
  }

  ResolvedAstroConfig copyWith({
    AstroLanguage? language,
    DivideType? yearDivide,
    DivideType? horoscopeDivide,
    AgeDivideType? ageDivide,
    DayDivideType? dayDivide,
    Algorithm? algorithm,
    Map<HeavenlyStem, List<StarKey>>? mutagens,
    Map<StarKey, List<Brightness?>>? brightness,
  }) {
    return ResolvedAstroConfig(
      language: language ?? this.language,
      yearDivide: yearDivide ?? this.yearDivide,
      horoscopeDivide: horoscopeDivide ?? this.horoscopeDivide,
      ageDivide: ageDivide ?? this.ageDivide,
      dayDivide: dayDivide ?? this.dayDivide,
      algorithm: algorithm ?? this.algorithm,
      mutagens: mutagens ?? this.mutagens,
      brightness: brightness ?? this.brightness,
    );
  }
}

/// Manages global defaults and immutable per-chart configuration resolution.
///
/// Changing global defaults via [config] or [setLanguage] never mutates
/// already-created astrolabe instances, matching `iztro >= 2.6.2`.
abstract final class AstroConfigManager {
  static ResolvedAstroConfig _globalConfig = ResolvedAstroConfig();

  /// Returns an immutable snapshot of the current global configuration.
  static ResolvedAstroConfig getConfig() => _globalConfig;

  /// Returns the current global default output language.
  static AstroLanguage getLanguage() => _globalConfig.language;

  /// Sets the global default output language.
  static void setLanguage(AstroLanguage language) {
    _globalConfig = _globalConfig.copyWith(language: language);
  }

  /// Updates the global default configuration.
  static void config(AstroConfig options) {
    _globalConfig = resolveConfig(options, base: _globalConfig);
  }

  /// Resets the global configuration and language back to factory defaults.
  static void resetConfig() {
    _globalConfig = ResolvedAstroConfig();
  }

  /// Resolves [options] on top of [base] (or current global defaults) into a
  /// fresh immutable [ResolvedAstroConfig].
  static ResolvedAstroConfig resolveConfig(
    AstroConfig? options, {
    AstroLanguage? language,
    ResolvedAstroConfig? base,
  }) {
    final baseConfig = base ?? _globalConfig;
    if (options == null && language == null) {
      return baseConfig;
    }

    Map<HeavenlyStem, List<StarKey>>? mergedMutagens;
    if (options?.mutagens != null) {
      mergedMutagens = {
        for (final entry in baseConfig.mutagens.entries)
          entry.key: List<StarKey>.of(entry.value),
        for (final entry in options!.mutagens!.entries)
          entry.key: List<StarKey>.of(entry.value),
      };
    }

    Map<StarKey, List<Brightness?>>? mergedBrightness;
    if (options?.brightness != null) {
      mergedBrightness = {
        for (final entry in baseConfig.brightness.entries)
          entry.key: List<Brightness?>.of(entry.value),
        for (final entry in options!.brightness!.entries)
          entry.key: List<Brightness?>.of(entry.value),
      };
    }

    return ResolvedAstroConfig(
      language: language ?? options?.language ?? baseConfig.language,
      yearDivide: options?.yearDivide ?? baseConfig.yearDivide,
      horoscopeDivide: options?.horoscopeDivide ?? baseConfig.horoscopeDivide,
      ageDivide: options?.ageDivide ?? baseConfig.ageDivide,
      dayDivide: options?.dayDivide ?? baseConfig.dayDivide,
      algorithm: options?.algorithm ?? baseConfig.algorithm,
      mutagens: mergedMutagens ?? baseConfig.mutagens,
      brightness: mergedBrightness ?? baseConfig.brightness,
    );
  }
}
