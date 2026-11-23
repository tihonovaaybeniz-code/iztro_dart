import '../core/types.dart';

/// Metadata for a single Earthly Branch (十二地支).
class EarthlyBranchMeta {
  const EarthlyBranchMeta({
    required this.yinYang,
    required this.fiveElement,
    required this.crash,
    required this.soul,
    required this.body,
    required this.inside,
    required this.outside,
    required this.healthTip,
  });

  final YinYang yinYang;
  final FiveElement fiveElement;
  final EarthlyBranch crash;
  final StarKey soul;
  final StarKey body;
  final String inside;
  final String outside;
  final String healthTip;
}

/// Twelve Earthly Branches table matching `iztro/src/data/earthlyBranches.ts` (`v2.6.5`).
const Map<EarthlyBranch, EarthlyBranchMeta> earthlyBranchesMeta = {
  EarthlyBranch.zi: EarthlyBranchMeta(
    yinYang: YinYang.yang,
    fiveElement: FiveElement.water,
    crash: EarthlyBranch.wu,
    soul: StarKey.tanlangMaj,
    body: StarKey.huoxingMin,
    inside: '胆',
    outside: '下体',
    healthTip: '生殖系统、膀胱、尿道之疾病，听觉障碍',
  ),
  EarthlyBranch.chou: EarthlyBranchMeta(
    yinYang: YinYang.yin,
    fiveElement: FiveElement.earth,
    crash: EarthlyBranch.wei,
    soul: StarKey.jumenMaj,
    body: StarKey.tianxiangMaj,
    inside: '肝',
    outside: '小腿、脚（右）',
    healthTip: '胸部、肋膜炎、胃病、脚部',
  ),
  EarthlyBranch.yin: EarthlyBranchMeta(
    yinYang: YinYang.yang,
    fiveElement: FiveElement.wood,
    crash: EarthlyBranch.shen,
    soul: StarKey.lucunMin,
    body: StarKey.tianliangMaj,
    inside: '肺',
    outside: '大腿（右）',
    healthTip: '胆囊、关节、胫部、神经痛、风湿',
  ),
  EarthlyBranch.mao: EarthlyBranchMeta(
    yinYang: YinYang.yin,
    fiveElement: FiveElement.wood,
    crash: EarthlyBranch.you,
    soul: StarKey.wenquMin,
    body: StarKey.tiantongMaj,
    inside: '大肠',
    outside: '腰（右）、背',
    healthTip: '肝病、颜面神经、失眠、神经衰弱',
  ),
  EarthlyBranch.chen: EarthlyBranchMeta(
    yinYang: YinYang.yang,
    fiveElement: FiveElement.earth,
    crash: EarthlyBranch.xu,
    soul: StarKey.lianzhenMaj,
    body: StarKey.wenchangMin,
    inside: '胃',
    outside: '胸、胳膊（右）',
    healthTip: '消化系统、脊椎、皮肤疾病',
  ),
  EarthlyBranch.si: EarthlyBranchMeta(
    yinYang: YinYang.yin,
    fiveElement: FiveElement.fire,
    crash: EarthlyBranch.hai,
    soul: StarKey.wuquMaj,
    body: StarKey.tianjiMaj,
    inside: '脾',
    outside: '左肩',
    healthTip: '喉头、牙病、感冒',
  ),
  EarthlyBranch.wu: EarthlyBranchMeta(
    yinYang: YinYang.yang,
    fiveElement: FiveElement.fire,
    crash: EarthlyBranch.zi,
    soul: StarKey.pojunMaj,
    body: StarKey.huoxingMin,
    inside: '心',
    outside: '头',
    healthTip: '心脏、视觉、味觉障碍、火难',
  ),
  EarthlyBranch.wei: EarthlyBranchMeta(
    yinYang: YinYang.yin,
    fiveElement: FiveElement.earth,
    crash: EarthlyBranch.chou,
    soul: StarKey.wuquMaj,
    body: StarKey.tianxiangMaj,
    inside: '小肠',
    outside: '脸',
    healthTip: '消化系统、胰脏、健忘症、疲倦、手腕、嘴唇',
  ),
  EarthlyBranch.shen: EarthlyBranchMeta(
    yinYang: YinYang.yang,
    fiveElement: FiveElement.metal,
    crash: EarthlyBranch.yin,
    soul: StarKey.lianzhenMaj,
    body: StarKey.tianliangMaj,
    inside: '膀胱',
    outside: '胸、胳膊（左）',
    healthTip: '呼吸系统、肺部、消化系统、大肠',
  ),
  EarthlyBranch.you: EarthlyBranchMeta(
    yinYang: YinYang.yin,
    fiveElement: FiveElement.metal,
    crash: EarthlyBranch.mao,
    soul: StarKey.wenquMin,
    body: StarKey.tiantongMaj,
    inside: '肾',
    outside: '腰（左）、腹',
    healthTip: '吐血、痢血、小肠之疾、脑出血、头腕部',
  ),
  EarthlyBranch.xu: EarthlyBranchMeta(
    yinYang: YinYang.yang,
    fiveElement: FiveElement.earth,
    crash: EarthlyBranch.chen,
    soul: StarKey.lucunMin,
    body: StarKey.wenchangMin,
    inside: '心包',
    outside: '大腿（左）',
    healthTip: '下半身之疾、子宫、痔疮、脚部',
  ),
  EarthlyBranch.hai: EarthlyBranchMeta(
    yinYang: YinYang.yin,
    fiveElement: FiveElement.water,
    crash: EarthlyBranch.si,
    soul: StarKey.jumenMaj,
    body: StarKey.tianjiMaj,
    inside: '三焦',
    outside: '小腿、脚（左）',
    healthTip: '排泄机能障碍、肾脏、尿道、偏头痛',
  ),
};
