import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import '../star/functional_star.dart';
import 'functional_astrolabe.dart';
import 'palace_calc.dart';

/// Represents one of the 12 Ziwei Doushu palaces (`0 = 寅 .. 11 = 丑`).
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
