import '../core/config.dart';
import '../core/index_math.dart';
import '../core/types.dart';
import '../data/stars_meta.dart';
import '../star/functional_star.dart';
import 'functional_astrolabe.dart';
import 'functional_flanking_palaces.dart';
import 'functional_palace.dart';
import 'functional_surpalaces.dart';

Set<StarKey> _palaceStarKeys(FunctionalPalace palace) {
  return <StarKey>{
    for (final s in palace.majorStars) s.key,
    for (final s in palace.minorStars) s.key,
    for (final s in palace.adjectiveStars) s.key,
  };
}

/// Returns surrounded palaces (三方四正) for [indexOrName] in [astrolabe].
FunctionalSurpalaces getSurroundedPalaces(
  FunctionalAstrolabe astrolabe,
  Object indexOrName,
) {
  final target = astrolabe.palace(indexOrName);
  if (target == null) {
    throw ArgumentError.value(
      indexOrName,
      'indexOrName',
      'indexOrName is incorrect.',
    );
  }
  final palaceIndex = earthlyBranchToPalaceIndex(target.branch);
  final opposite = astrolabe.palace(fixIndex(palaceIndex + 6))!;
  final career = astrolabe.palace(fixIndex(palaceIndex + 4))!;
  final wealth = astrolabe.palace(fixIndex(palaceIndex + 8))!;

  return FunctionalSurpalaces(
    target: target,
    opposite: opposite,
    wealth: wealth,
    career: career,
  );
}

/// Returns adjacent flanking palaces (夹宫) for [indexOrName] in [astrolabe].
FunctionalFlankingPalaces getFlankingPalaces(
  FunctionalAstrolabe astrolabe,
  Object indexOrName,
) {
  final target = astrolabe.palace(indexOrName);
  if (target == null) {
    throw ArgumentError.value(
      indexOrName,
      'indexOrName',
      'invalid palace index or name.',
    );
  }
  final previous = astrolabe.palace(fixIndex(target.index - 1))!;
  final next = astrolabe.palace(fixIndex(target.index + 1))!;
  return FunctionalFlankingPalaces(previous: previous, next: next);
}

bool hasStars(FunctionalPalace palace, List<StarKey> stars) {
  final keys = _palaceStarKeys(palace);
  return stars.every(keys.contains);
}

bool notHaveStars(FunctionalPalace palace, List<StarKey> stars) {
  final keys = _palaceStarKeys(palace);
  return stars.every((s) => !keys.contains(s));
}

bool hasOneOfStars(FunctionalPalace palace, List<StarKey> stars) {
  final keys = _palaceStarKeys(palace);
  return stars.any(keys.contains);
}

bool hasMutagenInPalace(FunctionalPalace palace, Mutagen mutagen) {
  final stars = <FunctionalStar>[...palace.majorStars, ...palace.minorStars];
  return stars.any((s) => s.mutagen == mutagen);
}

bool isSurroundedByStars(
  FunctionalSurpalaces surpalaces,
  List<StarKey> stars,
) {
  final keys = <StarKey>{
    for (final p in surpalaces.allPalaces) ..._palaceStarKeys(p),
  };
  return stars.every(keys.contains);
}

bool notSurroundedByStars(
  FunctionalSurpalaces surpalaces,
  List<StarKey> stars,
) {
  final keys = <StarKey>{
    for (final p in surpalaces.allPalaces) ..._palaceStarKeys(p),
  };
  return stars.every((s) => !keys.contains(s));
}

bool isSurroundedByOneOfStars(
  FunctionalSurpalaces surpalaces,
  List<StarKey> stars,
) {
  final keys = <StarKey>{
    for (final p in surpalaces.allPalaces) ..._palaceStarKeys(p),
  };
  return stars.any(keys.contains);
}

bool isFlankedByStars(
  FunctionalFlankingPalaces flanking,
  List<StarKey> stars,
) {
  final keys = <StarKey>{
    ..._palaceStarKeys(flanking.previous),
    ..._palaceStarKeys(flanking.next),
  };
  return stars.every(keys.contains);
}

bool notFlankedByStars(
  FunctionalFlankingPalaces flanking,
  List<StarKey> stars,
) {
  final keys = <StarKey>{
    ..._palaceStarKeys(flanking.previous),
    ..._palaceStarKeys(flanking.next),
  };
  return stars.every((s) => !keys.contains(s));
}

bool isFlankedByOneOfStars(
  FunctionalFlankingPalaces flanking,
  List<StarKey> stars,
) {
  final keys = <StarKey>{
    ..._palaceStarKeys(flanking.previous),
    ..._palaceStarKeys(flanking.next),
  };
  return stars.any(keys.contains);
}

/// Maps [stem] + [mutagens] to the target [StarKey]s using [config].
List<StarKey> mutagensToStars(
  HeavenlyStem stem,
  List<Mutagen> mutagens,
  ResolvedAstroConfig config,
) {
  final stemStars = resolveMutagenStars(stem, config);
  final result = <StarKey>[];
  for (final m in mutagens) {
    if (m.index < stemStars.length) {
      result.add(stemStars[m.index]);
    }
  }
  return result;
}
