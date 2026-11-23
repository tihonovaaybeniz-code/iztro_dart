import '../core/config.dart';
import '../core/index_math.dart';
import '../core/types.dart';
import 'brightness_table.dart';
import 'stems_table.dart';

/// Static five-element and Yin-Yang metadata for major stars, matching
/// `STARS_INFO` in `iztro/src/data/stars.ts`.
class StarElementMeta {
  const StarElementMeta({this.fiveElement, this.yinYang});

  final FiveElement? fiveElement;
  final YinYang? yinYang;
}

const Map<StarKey, StarElementMeta> starsElementMeta = {
  StarKey.ziweiMaj:
      StarElementMeta(fiveElement: FiveElement.earth, yinYang: YinYang.yin),
  StarKey.tianjiMaj:
      StarElementMeta(fiveElement: FiveElement.wood, yinYang: YinYang.yin),
  StarKey.taiyangMaj: StarElementMeta(),
  StarKey.wuquMaj:
      StarElementMeta(fiveElement: FiveElement.metal, yinYang: YinYang.yin),
  StarKey.tiantongMaj:
      StarElementMeta(fiveElement: FiveElement.water, yinYang: YinYang.yang),
  StarKey.lianzhenMaj:
      StarElementMeta(fiveElement: FiveElement.fire, yinYang: YinYang.yin),
  StarKey.tianfuMaj:
      StarElementMeta(fiveElement: FiveElement.earth, yinYang: YinYang.yang),
  StarKey.taiyinMaj:
      StarElementMeta(fiveElement: FiveElement.water, yinYang: YinYang.yin),
  StarKey.tanlangMaj: StarElementMeta(fiveElement: FiveElement.water),
  StarKey.jumenMaj:
      StarElementMeta(fiveElement: FiveElement.earth, yinYang: YinYang.yin),
  StarKey.tianxiangMaj: StarElementMeta(fiveElement: FiveElement.water),
  StarKey.tianliangMaj: StarElementMeta(fiveElement: FiveElement.earth),
  StarKey.qishaMaj: StarElementMeta(),
  StarKey.pojunMaj: StarElementMeta(fiveElement: FiveElement.water),
};

/// Ordered list of the 14 major stars.
const List<StarKey> majorStarKeys = [
  StarKey.ziweiMaj,
  StarKey.tianjiMaj,
  StarKey.taiyangMaj,
  StarKey.wuquMaj,
  StarKey.tiantongMaj,
  StarKey.lianzhenMaj,
  StarKey.tianfuMaj,
  StarKey.taiyinMaj,
  StarKey.tanlangMaj,
  StarKey.jumenMaj,
  StarKey.tianxiangMaj,
  StarKey.tianliangMaj,
  StarKey.qishaMaj,
  StarKey.pojunMaj,
];

/// Resolves [Brightness] of [star] at 0-based [palaceIndex] (`0 = 寅 .. 11 = 丑`)
/// using [config] overrides when present.
Brightness? resolveStarBrightness(
  StarKey star,
  int palaceIndex,
  ResolvedAstroConfig config,
) {
  final table = config.brightness[star] ?? defaultBrightnessTable[star];
  if (table == null || table.isEmpty) {
    return null;
  }
  final idx = fixIndex(palaceIndex);
  if (idx >= table.length) {
    return null;
  }
  return table[idx];
}

/// Returns the 4 mutagen target stars `[禄, 权, 科, 忌]` for [stem].
List<StarKey> resolveMutagenStars(
  HeavenlyStem stem,
  ResolvedAstroConfig config,
) {
  return config.mutagens[stem] ?? heavenlyStemsMeta[stem]!.defaultMutagens;
}

/// Resolves the [Mutagen] triggered on [star] by [stem], or `null` if none.
Mutagen? resolveStarMutagen(
  StarKey star,
  HeavenlyStem stem,
  ResolvedAstroConfig config,
) {
  final stars = resolveMutagenStars(stem, config);
  final idx = stars.indexOf(star);
  if (idx < 0 || idx >= Mutagen.values.length) {
    return null;
  }
  return Mutagen.values[idx];
}
