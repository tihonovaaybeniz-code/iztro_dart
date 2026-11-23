import '../core/types.dart';
import 'analyzer.dart';
import 'functional_palace.dart';

/// Surrounded palaces (三方四正): target palace, opposite palace (对宫),
/// wealth palace (财帛位), and career palace (官禄位),
/// matching `iztro@2.6.5#FunctionalSurpalaces`.
class FunctionalSurpalaces {
  const FunctionalSurpalaces({
    required this.target,
    required this.opposite,
    required this.wealth,
    required this.career,
  });

  final FunctionalPalace target;
  final FunctionalPalace opposite;
  final FunctionalPalace wealth;
  final FunctionalPalace career;

  Iterable<FunctionalPalace> get allPalaces sync* {
    yield target;
    yield opposite;
    yield wealth;
    yield career;
  }

  /// Returns `true` if ALL [stars] appear across these four palaces.
  bool have(List<StarKey> stars) => isSurroundedByStars(this, stars);

  /// Returns `true` if NONE of [stars] appear across these four palaces.
  bool notHave(List<StarKey> stars) => notSurroundedByStars(this, stars);

  /// Returns `true` if AT LEAST ONE of [stars] appears across these four palaces.
  bool haveOneOf(List<StarKey> stars) => isSurroundedByOneOfStars(this, stars);

  /// Returns `true` if any of these four palaces holds a star with [mutagen].
  bool haveMutagen(Mutagen mutagen) =>
      target.hasMutagen(mutagen) ||
      opposite.hasMutagen(mutagen) ||
      wealth.hasMutagen(mutagen) ||
      career.hasMutagen(mutagen);

  /// Returns `true` if none of these four palaces holds a star with [mutagen].
  bool notHaveMutagen(Mutagen mutagen) => !haveMutagen(mutagen);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'target': target.toJson(),
        'opposite': opposite.toJson(),
        'wealth': wealth.toJson(),
        'career': career.toJson(),
      };
}
