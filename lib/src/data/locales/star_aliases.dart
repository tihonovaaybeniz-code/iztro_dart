import '../../core/types.dart';

/// Disambiguated star aliases matching `iztro/src/i18n/starAliases.ts` (`v2.6.5`),
/// used when looking up stars whose localized display text collides.
const Map<String, StarKey> starAliases = {
  // Korean
  '천상(天相)': StarKey.tianxiangMaj,
  '천상(天傷)': StarKey.tianshang,
  '천월(天鉞)': StarKey.tianyueMin,
  '천월(天月)': StarKey.tianyue,
  '겁살(劫殺)': StarKey.jieshaAdj,
  '겁살(劫煞)': StarKey.jiesha,
  '비렴(蜚廉)': StarKey.feilian,
  '비렴(飛廉)': StarKey.faylian,
  '관부(官府)': StarKey.guanfu,
  '관부(官符)': StarKey.gwanfu,
  // Vietnamese
  'Kiếp Sát(劫殺)': StarKey.jieshaAdj,
  'Kiếp Sát(劫煞)': StarKey.jiesha,
  'Phi Liêm(蜚廉)': StarKey.feilian,
  'Phi Liêm(飛廉)': StarKey.faylian,
};
