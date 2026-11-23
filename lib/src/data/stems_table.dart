import '../core/types.dart';

/// Metadata for a single Heavenly Stem (十天干).
class HeavenlyStemMeta {
  const HeavenlyStemMeta({
    required this.yinYang,
    required this.fiveElement,
    required this.defaultMutagens,
    this.crash,
  });

  final YinYang yinYang;
  final FiveElement fiveElement;

  /// Opposing stem (甲庚、乙辛、丙壬、丁癸；戊己无冲).
  final HeavenlyStem? crash;

  /// Default `[禄, 权, 科, 忌]` four-mutagen stars.
  final List<StarKey> defaultMutagens;
}

/// Ten Heavenly Stems table matching `iztro/src/data/heavenlyStems.ts` (`v2.6.5`).
const Map<HeavenlyStem, HeavenlyStemMeta> heavenlyStemsMeta = {
  HeavenlyStem.jia: HeavenlyStemMeta(
    yinYang: YinYang.yang,
    fiveElement: FiveElement.wood,
    crash: HeavenlyStem.geng,
    defaultMutagens: [
      StarKey.lianzhenMaj,
      StarKey.pojunMaj,
      StarKey.wuquMaj,
      StarKey.taiyangMaj,
    ],
  ),
  HeavenlyStem.yi: HeavenlyStemMeta(
    yinYang: YinYang.yin,
    fiveElement: FiveElement.wood,
    crash: HeavenlyStem.xin,
    defaultMutagens: [
      StarKey.tianjiMaj,
      StarKey.tianliangMaj,
      StarKey.ziweiMaj,
      StarKey.taiyinMaj,
    ],
  ),
  HeavenlyStem.bing: HeavenlyStemMeta(
    yinYang: YinYang.yang,
    fiveElement: FiveElement.fire,
    crash: HeavenlyStem.ren,
    defaultMutagens: [
      StarKey.tiantongMaj,
      StarKey.tianjiMaj,
      StarKey.wenchangMin,
      StarKey.lianzhenMaj,
    ],
  ),
  HeavenlyStem.ding: HeavenlyStemMeta(
    yinYang: YinYang.yin,
    fiveElement: FiveElement.fire,
    crash: HeavenlyStem.gui,
    defaultMutagens: [
      StarKey.taiyinMaj,
      StarKey.tiantongMaj,
      StarKey.tianjiMaj,
      StarKey.jumenMaj,
    ],
  ),
  HeavenlyStem.wu: HeavenlyStemMeta(
    yinYang: YinYang.yang,
    fiveElement: FiveElement.earth,
    defaultMutagens: [
      StarKey.tanlangMaj,
      StarKey.taiyinMaj,
      StarKey.youbiMin,
      StarKey.tianjiMaj,
    ],
  ),
  HeavenlyStem.ji: HeavenlyStemMeta(
    yinYang: YinYang.yin,
    fiveElement: FiveElement.earth,
    defaultMutagens: [
      StarKey.wuquMaj,
      StarKey.tanlangMaj,
      StarKey.tianliangMaj,
      StarKey.wenquMin,
    ],
  ),
  HeavenlyStem.geng: HeavenlyStemMeta(
    yinYang: YinYang.yang,
    fiveElement: FiveElement.metal,
    crash: HeavenlyStem.jia,
    defaultMutagens: [
      StarKey.taiyangMaj,
      StarKey.wuquMaj,
      StarKey.taiyinMaj,
      StarKey.tiantongMaj,
    ],
  ),
  HeavenlyStem.xin: HeavenlyStemMeta(
    yinYang: YinYang.yin,
    fiveElement: FiveElement.metal,
    crash: HeavenlyStem.yi,
    defaultMutagens: [
      StarKey.jumenMaj,
      StarKey.taiyangMaj,
      StarKey.wenquMin,
      StarKey.wenchangMin,
    ],
  ),
  HeavenlyStem.ren: HeavenlyStemMeta(
    yinYang: YinYang.yang,
    fiveElement: FiveElement.water,
    crash: HeavenlyStem.bing,
    defaultMutagens: [
      StarKey.tianliangMaj,
      StarKey.ziweiMaj,
      StarKey.zuofuMin,
      StarKey.wuquMaj,
    ],
  ),
  HeavenlyStem.gui: HeavenlyStemMeta(
    yinYang: YinYang.yin,
    fiveElement: FiveElement.water,
    crash: HeavenlyStem.ding,
    defaultMutagens: [
      StarKey.pojunMaj,
      StarKey.jumenMaj,
      StarKey.taiyinMaj,
      StarKey.tanlangMaj,
    ],
  ),
};

/// Zhongzhou school mutagen preset for comparison / explicit config usage.
///
/// Notice `iztro@2.6.5` itself keeps the `heavenlyStems` mutagen table as
/// default even under `algorithm: 'zhongzhou'` (Zhongzhou differs in soul star,
/// tianshi/tianshang, suipo, jiekong/jieshaAdj/dahao/longde); this preset is
/// provided for callers who explicitly want Zhongzhou-style mutagens via
/// `AstroConfig(mutagens: zhongzhouMutagenPreset)`.
const Map<HeavenlyStem, List<StarKey>> zhongzhouMutagenPreset = {
  HeavenlyStem.geng: [
    StarKey.taiyangMaj,
    StarKey.wuquMaj,
    StarKey.tianfuMaj,
    StarKey.tiantongMaj,
  ],
  HeavenlyStem.wu: [
    StarKey.tanlangMaj,
    StarKey.taiyinMaj,
    StarKey.youbiMin,
    StarKey.tianjiMaj,
  ],
  HeavenlyStem.ren: [
    StarKey.tianliangMaj,
    StarKey.ziweiMaj,
    StarKey.zuofuMin,
    StarKey.wuquMaj,
  ],
  HeavenlyStem.gui: [
    StarKey.pojunMaj,
    StarKey.jumenMaj,
    StarKey.taiyinMaj,
    StarKey.tanlangMaj,
  ],
};

/// Five Tigers Rule (五虎遁): maps year stem to the stem of the Yin (1st) palace.
const Map<HeavenlyStem, HeavenlyStem> tigerRule = {
  HeavenlyStem.jia: HeavenlyStem.bing,
  HeavenlyStem.yi: HeavenlyStem.wu,
  HeavenlyStem.bing: HeavenlyStem.geng,
  HeavenlyStem.ding: HeavenlyStem.ren,
  HeavenlyStem.wu: HeavenlyStem.jia,
  HeavenlyStem.ji: HeavenlyStem.bing,
  HeavenlyStem.geng: HeavenlyStem.wu,
  HeavenlyStem.xin: HeavenlyStem.geng,
  HeavenlyStem.ren: HeavenlyStem.ren,
  HeavenlyStem.gui: HeavenlyStem.jia,
};

/// Five Rats Rule (五鼠遁): maps day stem to the stem of the Zi (0th) hour.
const Map<HeavenlyStem, HeavenlyStem> ratRule = {
  HeavenlyStem.jia: HeavenlyStem.jia,
  HeavenlyStem.yi: HeavenlyStem.bing,
  HeavenlyStem.bing: HeavenlyStem.wu,
  HeavenlyStem.ding: HeavenlyStem.geng,
  HeavenlyStem.wu: HeavenlyStem.ren,
  HeavenlyStem.ji: HeavenlyStem.jia,
  HeavenlyStem.geng: HeavenlyStem.bing,
  HeavenlyStem.xin: HeavenlyStem.wu,
  HeavenlyStem.ren: HeavenlyStem.geng,
  HeavenlyStem.gui: HeavenlyStem.ren,
};
