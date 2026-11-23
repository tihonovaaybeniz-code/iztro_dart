import '../astro/functional_astrolabe.dart';
import '../astro/functional_palace.dart';
import '../core/types.dart';
import '../data/locales/locale_registry.dart';

/// Represents a single placed Ziwei Doushu star with contextual navigation
/// and JSON serialization aligned with `iztro@2.6.5`.
class FunctionalStar {
  FunctionalStar({
    required this.key,
    required this.name,
    required this.type,
    required this.scope,
    this.brightness,
    this.mutagen,
    this.language = AstroLanguage.zhCN,
    bool includeBrightnessInJson = false,
    bool includeMutagenInJson = false,
  })  : _includeBrightnessInJson = includeBrightnessInJson,
        _includeMutagenInJson = includeMutagenInJson;

  /// Canonical star identifier independent of output language.
  final StarKey key;

  /// Localized display name (according to chart language).
  final String name;

  /// Star category (`major`, `soft`, `tough`, `adjective`, `flower`, `helper`, `lucun`, `tianma`).
  final StarType type;

  /// Horoscope / chart scope (`origin`, `decadal`, `yearly`, `monthly`, `daily`, `hourly`).
  final Scope scope;

  /// Seven-level brightness (`miao`..`xian`), or `null` when unavailable.
  final Brightness? brightness;

  /// Active mutagen (`lu`, `quan`, `ke`, `ji`), or `null` when none.
  final Mutagen? mutagen;

  /// Output language of this star instance.
  final AstroLanguage language;

  final bool _includeBrightnessInJson;
  final bool _includeMutagenInJson;

  FunctionalPalace? _palace;
  FunctionalAstrolabe? _astrolabe;

  /// Attaches palace context (used internally by astrolabe context binding).
  void bindPalace(FunctionalPalace palace) {
    _palace = palace;
  }

  /// Attaches astrolabe context (used internally by astrolabe context binding).
  void bindAstrolabe(FunctionalAstrolabe astrolabe) {
    _astrolabe = astrolabe;
  }

  /// Returns the [FunctionalPalace] containing this star, if bound.
  FunctionalPalace? palace() => _palace;

  /// Returns the opposite palace (对宫) of this star's palace, if bound.
  FunctionalPalace? oppositePalace() {
    final p = _palace;
    final a = _astrolabe;
    if (p == null || a == null) {
      return null;
    }
    return a.palace((p.index + 6) % 12);
  }

  /// Returns `true` if [brightness] matches any item in [brightnesses].
  bool withBrightness(List<Brightness> brightnesses) {
    final current = brightness;
    if (current == null) {
      return false;
    }
    return brightnesses.contains(current);
  }

  /// Convenience single-value overload for [withBrightness].
  bool hasBrightness(Brightness value) => brightness == value;

  /// Returns `true` if [mutagen] matches any item in [mutagens].
  bool withMutagen(List<Mutagen> mutagens) {
    final current = mutagen;
    if (current == null) {
      return false;
    }
    return mutagens.contains(current);
  }

  /// Convenience single-value overload for [withMutagen].
  bool hasMutagen(Mutagen value) => mutagen == value;

  /// Serializes to an `iztro`-compatible plain JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'type': type.key,
      'scope': scope.key,
    };
    if (_includeBrightnessInJson || brightness != null) {
      map['brightness'] = brightness != null
          ? LocaleRegistry.translate(brightness!.key, language)
          : '';
    }
    if (_includeMutagenInJson || mutagen != null) {
      map['mutagen'] = mutagen != null
          ? LocaleRegistry.translate(mutagen!.key, language)
          : '';
    }
    return map;
  }

  @override
  String toString() => name;
}
