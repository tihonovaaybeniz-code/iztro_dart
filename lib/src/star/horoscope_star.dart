import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import 'functional_star.dart';
import 'location.dart';

/// Places horoscope flow stars (`魁钺昌曲禄羊陀马鸾喜`, plus `年解` for yearly),
/// matching `iztro/src/star/horoscopeStar.ts#getHoroscopeStar`.
List<List<FunctionalStar>> getHoroscopeStar(
  HeavenlyStem stem,
  EarthlyBranch branch,
  Scope scope, {
  AstroLanguage language = AstroLanguage.zhCN,
}) {
  final kuiYue = getKuiYueIndex(stem);
  final changQu = getChangQuIndexByHeavenlyStem(stem);
  final luYangTuoMa = getLuYangTuoMaIndex(stem, branch);
  final luanXi = getLuanXiIndex(branch);
  final stars = List<List<FunctionalStar>>.generate(12, (_) => []);

  final map = _scopeStarMap[scope]!;

  void addStar(int palaceIdx, StarKey key, StarType type) {
    stars[palaceIdx].add(
      FunctionalStar(
        key: key,
        name: LocaleRegistry.translate(key.key, language),
        type: type,
        scope: scope,
        language: language,
      ),
    );
  }

  if (scope == Scope.yearly) {
    final nianjieIndex = getNianjieIndex(branch);
    addStar(nianjieIndex, StarKey.nianjie, StarType.helper);
  }

  addStar(kuiYue.kuiIndex, map.tiankui, StarType.soft);
  addStar(kuiYue.yueIndex, map.tianyue, StarType.soft);
  addStar(changQu.changIndex, map.wenchang, StarType.soft);
  addStar(changQu.quIndex, map.wenqu, StarType.soft);
  addStar(luYangTuoMa.luIndex, map.lucun, StarType.lucun);
  addStar(luYangTuoMa.yangIndex, map.qingyang, StarType.tough);
  addStar(luYangTuoMa.tuoIndex, map.tuoluo, StarType.tough);
  addStar(luYangTuoMa.maIndex, map.tianma, StarType.tianma);
  addStar(luanXi.hongluanIndex, map.hongluan, StarType.flower);
  addStar(luanXi.tianxiIndex, map.tianxi, StarType.flower);

  return stars;
}

class _ScopeStars {
  const _ScopeStars({
    required this.tiankui,
    required this.tianyue,
    required this.wenchang,
    required this.wenqu,
    required this.lucun,
    required this.qingyang,
    required this.tuoluo,
    required this.tianma,
    required this.hongluan,
    required this.tianxi,
  });

  final StarKey tiankui;
  final StarKey tianyue;
  final StarKey wenchang;
  final StarKey wenqu;
  final StarKey lucun;
  final StarKey qingyang;
  final StarKey tuoluo;
  final StarKey tianma;
  final StarKey hongluan;
  final StarKey tianxi;
}

const Map<Scope, _ScopeStars> _scopeStarMap = {
  Scope.origin: _ScopeStars(
    tiankui: StarKey.tiankuiMin,
    tianyue: StarKey.tianyueMin,
    wenchang: StarKey.wenchangMin,
    wenqu: StarKey.wenquMin,
    lucun: StarKey.lucunMin,
    qingyang: StarKey.qingyangMin,
    tuoluo: StarKey.tuoluoMin,
    tianma: StarKey.tianmaMin,
    hongluan: StarKey.hongluan,
    tianxi: StarKey.tianxi,
  ),
  Scope.decadal: _ScopeStars(
    tiankui: StarKey.yunkui,
    tianyue: StarKey.yunyue,
    wenchang: StarKey.yunchang,
    wenqu: StarKey.yunqu,
    lucun: StarKey.yunlu,
    qingyang: StarKey.yunyang,
    tuoluo: StarKey.yuntuo,
    tianma: StarKey.yunma,
    hongluan: StarKey.yunluan,
    tianxi: StarKey.yunxi,
  ),
  Scope.yearly: _ScopeStars(
    tiankui: StarKey.liukui,
    tianyue: StarKey.liuyue,
    wenchang: StarKey.liuchang,
    wenqu: StarKey.liuqu,
    lucun: StarKey.liulu,
    qingyang: StarKey.liuyang,
    tuoluo: StarKey.liutuo,
    tianma: StarKey.liuma,
    hongluan: StarKey.liuluan,
    tianxi: StarKey.liuxi,
  ),
  Scope.monthly: _ScopeStars(
    tiankui: StarKey.yuekui,
    tianyue: StarKey.yueyue,
    wenchang: StarKey.yuechang,
    wenqu: StarKey.yuequ,
    lucun: StarKey.yuelu,
    qingyang: StarKey.yueyang,
    tuoluo: StarKey.yuetuo,
    tianma: StarKey.yuema,
    hongluan: StarKey.yueluan,
    tianxi: StarKey.yuexi,
  ),
  Scope.daily: _ScopeStars(
    tiankui: StarKey.rikui,
    tianyue: StarKey.riyue,
    wenchang: StarKey.richang,
    wenqu: StarKey.riqu,
    lucun: StarKey.rilu,
    qingyang: StarKey.riyang,
    tuoluo: StarKey.rituo,
    tianma: StarKey.rima,
    hongluan: StarKey.riluan,
    tianxi: StarKey.rixi,
  ),
  Scope.hourly: _ScopeStars(
    tiankui: StarKey.shikui,
    tianyue: StarKey.shiyue,
    wenchang: StarKey.shichang,
    wenqu: StarKey.shiqu,
    lucun: StarKey.shilu,
    qingyang: StarKey.shiyang,
    tuoluo: StarKey.shituo,
    tianma: StarKey.shima,
    hongluan: StarKey.shiluan,
    tianxi: StarKey.shixi,
  ),
};
