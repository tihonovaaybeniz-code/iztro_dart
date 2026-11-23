import '../core/config.dart';
import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import '../star/functional_star.dart';
import 'analyzer.dart';
import 'functional_astrolabe.dart';
import 'palace_calc.dart';

/// Represents one of the 12 Ziwei Doushu palaces (`0 = 寅 .. 11 = 丑`) with
/// chainable star, mutagen, and flying-star query methods.
class FunctionalPalace {
  FunctionalPalace({
    required this.index,
    required this.palaceName,
    required this.isBodyPalace,
    required this.isOriginalPalace,
    required this.stem,
    required this.branch,
    required this.majorStars,
    required this.minorStars,
    required this.adjectiveStars,
    required this.changsheng12,
    required this.boshi12,
    required this.jiangqian12,
    required this.suiqian12,
    required this.decadal,
    required this.ages,
    this.language = AstroLanguage.zhCN,
  });

  /// 0-based palace index (`0 = 寅 .. 11 = 丑`).
  final int index;

  /// Strong-typed palace identity. Mutable during `earth`/`human` rearrangement.
  PalaceName palaceName;

  /// Localized palace name matching `iztro`'s `palace.name`.
  String get name => LocaleRegistry.translate(palaceName.key, language);

  /// Whether this palace is the Body Palace (身宫).
  bool isBodyPalace;

  /// Whether this palace is the Original/Cause Palace (来因宫).
  final bool isOriginalPalace;

  /// Palace Heavenly Stem (宫干).
  final HeavenlyStem stem;

  /// Palace Earthly Branch (宫支).
  final EarthlyBranch branch;

  /// Localized Heavenly Stem name.
  String get heavenlyStem => LocaleRegistry.translate(stem.key, language);

  /// Localized Earthly Branch name.
  String get earthlyBranch => LocaleRegistry.translate(branch.key, language);

  List<FunctionalStar> majorStars;
  List<FunctionalStar> minorStars;
  List<FunctionalStar> adjectiveStars;

  String changsheng12;
  final String boshi12;
  final String jiangqian12;
  final String suiqian12;

  Decadal decadal;
  List<int> ages;

  final AstroLanguage language;

  FunctionalAstrolabe? _astrolabe;

  /// Attaches parent astrolabe reference (used by query methods).
  void bindAstrolabe(FunctionalAstrolabe astrolabe) {
    _astrolabe = astrolabe;
    for (final s in majorStars) {
      s.bindPalace(this);
      s.bindAstrolabe(astrolabe);
    }
    for (final s in minorStars) {
      s.bindPalace(this);
      s.bindAstrolabe(astrolabe);
    }
    for (final s in adjectiveStars) {
      s.bindPalace(this);
      s.bindAstrolabe(astrolabe);
    }
  }

  /// Returns parent [FunctionalAstrolabe], if bound.
  FunctionalAstrolabe? astrolabe() => _astrolabe;

  /// All stars placed in this palace (`majorStars + minorStars + adjectiveStars`).
  Iterable<FunctionalStar> get allStars sync* {
    yield* majorStars;
    yield* minorStars;
    yield* adjectiveStars;
  }

  /// Returns `true` if ALL [stars] exist in this palace.
  bool has(List<StarKey> stars) => hasStars(this, stars);

  /// Returns `true` if NONE of [stars] exist in this palace.
  bool notHave(List<StarKey> stars) => notHaveStars(this, stars);

  /// Returns `true` if AT LEAST ONE of [stars] exists in this palace.
  bool hasOneOf(List<StarKey> stars) => hasOneOfStars(this, stars);

  /// Returns `true` if a major/minor star in this palace carries birth [mutagen].
  bool hasMutagen(Mutagen mutagen) => hasMutagenInPalace(this, mutagen);

  /// Returns `true` if no major/minor star in this palace carries birth [mutagen].
  bool notHaveMutagen(Mutagen mutagen) => !hasMutagen(mutagen);

  /// Returns `true` if this palace has no major stars (`empty palace` / 空宫).
  ///
  /// Matching `iztro@2.6.5`, if [excludeStars] is passed and any of those stars
  /// are present in this palace, returns `false`.
  bool isEmpty([List<StarKey>? excludeStars]) {
    if (majorStars.any((s) => s.type == StarType.major)) {
      return false;
    }
    if (excludeStars != null &&
        excludeStars.isNotEmpty &&
        hasOneOf(excludeStars)) {
      return false;
    }
    return true;
  }

  /// Returns `true` if ALL [mutagens] triggered by this palace's stem fly into
  /// [target] (`PalaceName`, `int` index, or localized `String`).
  bool fliesTo(Object target, List<Mutagen> mutagens) {
    final toPalace = _astrolabe?.palace(target);
    if (toPalace == null) {
      return false;
    }
    final stars = mutagensToStars(stem, mutagens, _activeConfig);
    if (stars.isEmpty) {
      return false;
    }
    return toPalace.has(stars);
  }

  /// Returns `true` if AT LEAST ONE of [mutagens] triggered by this palace's
  /// stem flies into [target].
  bool fliesOneOfTo(Object target, List<Mutagen> mutagens) {
    final toPalace = _astrolabe?.palace(target);
    if (toPalace == null) {
      return false;
    }
    final stars = mutagensToStars(stem, mutagens, _activeConfig);
    if (stars.isEmpty) {
      return true;
    }
    return toPalace.hasOneOf(stars);
  }

  /// Returns `true` if NONE of [mutagens] triggered by this palace's stem fly
  /// into [target].
  bool notFlyTo(Object target, List<Mutagen> mutagens) {
    final toPalace = _astrolabe?.palace(target);
    if (toPalace == null) {
      return false;
    }
    final stars = mutagensToStars(stem, mutagens, _activeConfig);
    if (stars.isEmpty) {
      return true;
    }
    return toPalace.notHave(stars);
  }

  /// Outward self-mutagen (离心自化): returns `true` if ALL [mutagens]
  /// triggered by THIS palace's stem land on stars inside THIS palace.
  bool selfMutaged(List<Mutagen> mutagens) {
    final stars = mutagensToStars(stem, mutagens, _activeConfig);
    return has(stars);
  }

  /// Outward self-mutagen (离心自化): returns `true` if AT LEAST ONE of
  /// [mutagens] (all 4 mutagens if omitted) lands inside THIS palace.
  bool selfMutagedOneOf([List<Mutagen>? mutagens]) {
    final targets =
        (mutagens == null || mutagens.isEmpty) ? Mutagen.values : mutagens;
    final stars = mutagensToStars(stem, targets, _activeConfig);
    return hasOneOf(stars);
  }

  /// Returns `true` if NONE of [mutagens] (all 4 mutagens if omitted)
  /// outward self-mutage in THIS palace.
  bool notSelfMutaged([List<Mutagen>? mutagens]) {
    final targets =
        (mutagens == null || mutagens.isEmpty) ? Mutagen.values : mutagens;
    final stars = mutagensToStars(stem, targets, _activeConfig);
    return notHave(stars);
  }

  /// Centripetal self-mutagen (向心自化, `iztro_dart` value-add): returns
  /// `true` if ALL [mutagens] triggered by the OPPOSITE palace's stem land on
  /// stars inside THIS palace.
  bool selfMutagedIn(List<Mutagen> mutagens) {
    final opposite = _astrolabe?.palace((index + 6) % 12);
    if (opposite == null) {
      return false;
    }
    final stars = mutagensToStars(opposite.stem, mutagens, _activeConfig);
    return has(stars);
  }

  /// Centripetal self-mutagen (向心自化, `iztro_dart` value-add): returns
  /// `true` if AT LEAST ONE of [mutagens] (all 4 if omitted) triggered by the
  /// OPPOSITE palace's stem lands on a star inside THIS palace.
  bool selfMutagedInOneOf([List<Mutagen>? mutagens]) {
    final opposite = _astrolabe?.palace((index + 6) % 12);
    if (opposite == null) {
      return false;
    }
    final targets =
        (mutagens == null || mutagens.isEmpty) ? Mutagen.values : mutagens;
    final stars = mutagensToStars(opposite.stem, targets, _activeConfig);
    return hasOneOf(stars);
  }

  /// Returns the 4 target palaces `[禄, 权, 科, 忌]` where this palace's stem
  /// mutagens land.
  List<FunctionalPalace?> mutagedPlaces() {
    final astro = _astrolabe;
    if (astro == null) {
      return const [];
    }
    final stars = mutagensToStars(stem, Mutagen.values, _activeConfig);
    return stars
        .map((starKey) => astro.star(starKey).palace())
        .toList(growable: false);
  }

  ResolvedAstroConfig get _activeConfig =>
      _astrolabe?.configSnapshot ?? AstroConfigManager.getConfig();

  /// Serializes to an `iztro`-compatible plain JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'index': index,
        'name': name,
        'isBodyPalace': isBodyPalace,
        'isOriginalPalace': isOriginalPalace,
        'heavenlyStem': heavenlyStem,
        'earthlyBranch': earthlyBranch,
        'majorStars': majorStars.map((s) => s.toJson()).toList(growable: false),
        'minorStars': minorStars.map((s) => s.toJson()).toList(growable: false),
        'adjectiveStars':
            adjectiveStars.map((s) => s.toJson()).toList(growable: false),
        'changsheng12': changsheng12,
        'boshi12': boshi12,
        'jiangqian12': jiangqian12,
        'suiqian12': suiqian12,
        'decadal': decadal.toJson(),
        'ages': List<int>.of(ages),
      };
}
