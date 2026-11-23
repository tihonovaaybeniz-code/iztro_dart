import '../core/types.dart';
import 'analyzer.dart';
import 'functional_palace.dart';

/// Adjacent flanking palaces (夹宫: previous and next),
/// matching `iztro@2.6.5#FunctionalFlankingPalaces`.
class FunctionalFlankingPalaces {
  const FunctionalFlankingPalaces({
    required this.previous,
    required this.next,
  });

  final FunctionalPalace previous;
  final FunctionalPalace next;

  /// Returns `true` if ALL [stars] appear across [previous] and [next].
  bool have(List<StarKey> stars) => isFlankedByStars(this, stars);

  /// Returns `true` if NONE of [stars] appear in either [previous] or [next].
  bool notHave(List<StarKey> stars) => notFlankedByStars(this, stars);

  /// Returns `true` if AT LEAST ONE of [stars] appears in [previous] or [next].
  bool haveOneOf(List<StarKey> stars) => isFlankedByOneOfStars(this, stars);

  /// Returns `true` if either flanking palace contains [mutagen].
  bool haveMutagen(Mutagen mutagen) =>
      previous.hasMutagen(mutagen) || next.hasMutagen(mutagen);

  /// Returns `true` if neither flanking palace contains [mutagen].
  bool notHaveMutagen(Mutagen mutagen) => !haveMutagen(mutagen);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'previous': previous.toJson(),
        'next': next.toJson(),
      };
}
