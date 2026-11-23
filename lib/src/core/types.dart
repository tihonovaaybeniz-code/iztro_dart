/// Supported output and lookup languages, aligned with `iztro@2.6.5`.
enum AstroLanguage {
  enUS('en-US'),
  jaJP('ja-JP'),
  koKR('ko-KR'),
  zhCN('zh-CN'),
  zhTW('zh-TW'),
  viVN('vi-VN');

  const AstroLanguage(this.code);

  /// BCP-47 style locale identifier used by `iztro`.
  final String code;

  static AstroLanguage? tryParse(String value) {
    final normalized = value.trim().replaceAll('_', '-').toLowerCase();
    for (final lang in AstroLanguage.values) {
      if (lang.code.toLowerCase() == normalized) {
        return lang;
      }
    }
    return null;
  }
}

/// Ten Heavenly Stems (十天干).
enum HeavenlyStem {
  jia('jiaHeavenly', '甲'),
  yi('yiHeavenly', '乙'),
  bing('bingHeavenly', '丙'),
  ding('dingHeavenly', '丁'),
  wu('wuHeavenly', '戊'),
  ji('jiHeavenly', '己'),
  geng('gengHeavenly', '庚'),
  xin('xinHeavenly', '辛'),
  ren('renHeavenly', '壬'),
  gui('guiHeavenly', '癸');

  const HeavenlyStem(this.key, this.zh);

  /// Canonical `iztro` i18n key.
  final String key;

  /// Simplified Chinese character.
  final String zh;

  static HeavenlyStem? tryParse(String value) {
    final trimmed = value.trim();
    for (final stem in HeavenlyStem.values) {
      if (stem.key == trimmed || stem.zh == trimmed || stem.name == trimmed) {
        return stem;
      }
    }
    return null;
  }
}

/// Twelve Earthly Branches (十二地支).
enum EarthlyBranch {
  zi('ziEarthly', '子'),
  chou('chouEarthly', '丑'),
  yin('yinEarthly', '寅'),
  mao('maoEarthly', '卯'),
  chen('chenEarthly', '辰'),
  si('siEarthly', '巳'),
  wu('wuEarthly', '午'),
  wei('weiEarthly', '未'),
  shen('shenEarthly', '申'),
  you('youEarthly', '酉'),
  xu('xuEarthly', '戌'),
  hai('haiEarthly', '亥');

  const EarthlyBranch(this.key, this.zh);

  /// Canonical `iztro` i18n key.
  final String key;

  /// Simplified Chinese character.
  final String zh;

  static EarthlyBranch? tryParse(String value) {
    final trimmed = value.trim();
    for (final branch in EarthlyBranch.values) {
      if (branch.key == trimmed ||
          branch.zh == trimmed ||
          branch.name == trimmed) {
        return branch;
      }
    }
    return null;
  }
}

/// Twelve Zodiac signs ordered from Rat (子) to Pig (亥).
enum ZodiacSign {
  rat('rat'),
  ox('ox'),
  tiger('tiger'),
  rabbit('rabbit'),
  dragon('dragon'),
  snake('snake'),
  horse('horse'),
  sheep('sheep'),
  monkey('monkey'),
  rooster('rooster'),
  dog('dog'),
  pig('pig');

  const ZodiacSign(this.key);

  /// Canonical `iztro` i18n key.
  final String key;
}

/// Twelve Western constellations.
enum Constellation {
  aries('aries'),
  taurus('taurus'),
  gemini('gemini'),
  cancer('cancer'),
  leo('leo'),
  virgo('virgo'),
  libra('libra'),
  scorpio('scorpio'),
  sagittarius('sagittarius'),
  capricorn('capricorn'),
  aquarius('aquarius'),
  pisces('pisces');

  const Constellation(this.key);

  /// Canonical `iztro` i18n key.
  final String key;
}

/// Twelve Ziwei Doushu palaces in `iztro` canonical counterclockwise order.
enum PalaceName {
  soul('soulPalace'),
  parents('parentsPalace'),
  spirit('spiritPalace'),
  property('propertyPalace'),
  career('careerPalace'),
  friends('friendsPalace'),
  surface('surfacePalace'),
  health('healthPalace'),
  wealth('wealthPalace'),
  children('childrenPalace'),
  spouse('spousePalace'),
  siblings('siblingsPalace');

  const PalaceName(this.key);

  /// Canonical `iztro` i18n key.
  final String key;

  static PalaceName? tryFromKey(String key) {
    for (final palace in PalaceName.values) {
      if (palace.key == key || palace.name == key) {
        return palace;
      }
    }
    return null;
  }
}

/// Gender (男 / 女).
enum Gender {
  male('male', YinYang.yang),
  female('female', YinYang.yin);

  const Gender(this.key, this.yinYang);

  /// Canonical `iztro` i18n key.
  final String key;

  /// Yin-Yang polarity.
  final YinYang yinYang;
}

/// Yin or Yang polarity.
enum YinYang {
  yin('阴'),
  yang('阳');

  const YinYang(this.zh);

  final String zh;
}

/// Five Elements (五行).
enum FiveElement {
  wood('木'),
  metal('金'),
  water('水'),
  fire('火'),
  earth('土');

  const FiveElement(this.zh);

  final String zh;
}

/// Five Elements Class (五行局).
enum FiveElementsClass {
  water2nd(2, 'water2nd'),
  wood3rd(3, 'wood3rd'),
  metal4th(4, 'metal4th'),
  earth5th(5, 'earth5th'),
  fire6th(6, 'fire6th');

  const FiveElementsClass(this.value, this.key);

  /// Numeric starting decadal age (2..6).
  final int value;

  /// Canonical `iztro` i18n key.
  final String key;

  static FiveElementsClass fromValue(int value) {
    for (final item in FiveElementsClass.values) {
      if (item.value == value) {
        return item;
      }
    }
    throw ArgumentError.value(value, 'value', 'Invalid FiveElementsClass.');
  }
}

/// Four Mutagens (四化: 禄、权、科、忌).
enum Mutagen {
  lu('sihuaLu'),
  quan('sihuaQuan'),
  ke('sihuaKe'),
  ji('sihuaJi');

  const Mutagen(this.key);

  /// Canonical `iztro` i18n key.
  final String key;

  static Mutagen? tryFromKey(String key) {
    for (final item in Mutagen.values) {
      if (item.key == key || item.name == key) {
        return item;
      }
    }
    return null;
  }
}

/// Seven star brightness levels (庙旺得利平不陷).
enum Brightness {
  miao('miao'),
  wang('wang'),
  de('de'),
  li('li'),
  ping('ping'),
  bu('bu'),
  xian('xian');

  const Brightness(this.key);

  /// Canonical `iztro` i18n key.
  final String key;

  static Brightness? tryFromKey(String key) {
    for (final item in Brightness.values) {
      if (item.key == key || item.name == key) {
        return item;
      }
    }
    return null;
  }
}

/// Horoscope / chart scope.
enum Scope {
  origin('origin'),
  decadal('decadal'),
  yearly('yearly'),
  monthly('monthly'),
  daily('daily'),
  hourly('hourly');

  const Scope(this.key);

  final String key;
}

/// Star classification.
enum StarType {
  major('major'),
  soft('soft'),
  tough('tough'),
  adjective('adjective'),
  flower('flower'),
  helper('helper'),
  lucun('lucun'),
  tianma('tianma');

  const StarType(this.key);

  final String key;
}

/// Year/month division rule (`normal` = Lunar New Year / 1st day; `exact` = Lichun / solar term).
enum DivideType {
  normal('normal'),
  exact('exact');

  const DivideType(this.key);

  final String key;
}

/// Nominal age increment rule (`normal` = calendar year; `birthday` = lunar birthday).
enum AgeDivideType {
  normal('normal'),
  birthday('birthday');

  const AgeDivideType(this.key);

  final String key;
}

/// Late Rat hour (23:00–00:00) day division rule (`forward` = next day; `current` = same day).
enum DayDivideType {
  forward('forward'),
  current('current');

  const DayDivideType(this.key);

  final String key;
}

/// Star placement school/algorithm (`defaultAlgorithm` = general; `zhongzhou` = Zhongzhou school).
enum Algorithm {
  defaultAlgorithm('default'),
  zhongzhou('zhongzhou');

  const Algorithm(this.key);

  final String key;
}

/// Chart type (`heaven` = soul palace; `earth` = body palace; `human` = spirit palace).
enum AstroType {
  heaven('heaven'),
  earth('earth'),
  human('human');

  const AstroType(this.key);

  final String key;
}

/// Thirteen Chinese two-hour periods (0 = early Rat, 1..11 = Ox..Pig, 12 = late Rat).
enum ChineseTime {
  earlyRatHour(0, 'earlyRatHour', '00:00~01:00'),
  oxHour(1, 'oxHour', '01:00~03:00'),
  tigerHour(2, 'tigerHour', '03:00~05:00'),
  rabbitHour(3, 'rabbitHour', '05:00~07:00'),
  dragonHour(4, 'dragonHour', '07:00~09:00'),
  snakeHour(5, 'snakeHour', '09:00~11:00'),
  horseHour(6, 'horseHour', '11:00~13:00'),
  goatHour(7, 'goatHour', '13:00~15:00'),
  monkeyHour(8, 'monkeyHour', '15:00~17:00'),
  roosterHour(9, 'roosterHour', '17:00~19:00'),
  dogHour(10, 'dogHour', '19:00~21:00'),
  pigHour(11, 'pigHour', '21:00~23:00'),
  lateRatHour(12, 'lateRatHour', '23:00~00:00');

  const ChineseTime(this.timeIndex, this.key, this.timeRange);

  /// Time index `0..12`.
  final int timeIndex;

  /// Canonical `iztro` i18n key.
  final String key;

  /// Wall-clock range string.
  final String timeRange;

  static ChineseTime fromIndex(int index) {
    if (index < 0 || index > 12) {
      throw RangeError.range(index, 0, 12, 'timeIndex');
    }
    return ChineseTime.values[index];
  }
}

/// All 162 canonical star keys in `iztro@2.6.5`.
enum StarKey {
  // 14 major stars
  ziweiMaj('ziweiMaj'),
  tianjiMaj('tianjiMaj'),
  taiyangMaj('taiyangMaj'),
  wuquMaj('wuquMaj'),
  tiantongMaj('tiantongMaj'),
  lianzhenMaj('lianzhenMaj'),
  tianfuMaj('tianfuMaj'),
  taiyinMaj('taiyinMaj'),
  tanlangMaj('tanlangMaj'),
  jumenMaj('jumenMaj'),
  tianxiangMaj('tianxiangMaj'),
  tianliangMaj('tianliangMaj'),
  qishaMaj('qishaMaj'),
  pojunMaj('pojunMaj'),

  // 14 minor stars
  zuofuMin('zuofuMin'),
  youbiMin('youbiMin'),
  wenchangMin('wenchangMin'),
  wenquMin('wenquMin'),
  lucunMin('lucunMin'),
  tianmaMin('tianmaMin'),
  qingyangMin('qingyangMin'),
  tuoluoMin('tuoluoMin'),
  huoxingMin('huoxingMin'),
  lingxingMin('lingxingMin'),
  tiankuiMin('tiankuiMin'),
  tianyueMin('tianyueMin'),
  dikongMin('dikongMin'),
  dijieMin('dijieMin'),

  // Adjective / flower / helper stars
  jieshaAdj('jieshaAdj'),
  tiankong('tiankong'),
  tianxing('tianxing'),
  tianyao('tianyao'),
  jieshen('jieshen'),
  yinsha('yinsha'),
  tianxi('tianxi'),
  tianguan('tianguan'),
  tianfu('tianfu'),
  tianku('tianku'),
  tianxu('tianxu'),
  longchi('longchi'),
  fengge('fengge'),
  hongluan('hongluan'),
  guchen('guchen'),
  guasu('guasu'),
  feilian('feilian'),
  posui('posui'),
  taifu('taifu'),
  fenggao('fenggao'),
  tianwu('tianwu'),
  tianyue('tianyue'),
  santai('santai'),
  bazuo('bazuo'),
  engguang('engguang'),
  tiangui('tiangui'),
  tiancai('tiancai'),
  tianshou('tianshou'),
  jiekong('jiekong'),
  xunzhong('xunzhong'),
  xunkong('xunkong'),
  kongwang('kongwang'),
  jielu('jielu'),
  yuede('yuede'),
  tianshang('tianshang'),
  tianshi('tianshi'),
  tianchu('tianchu'),

  // Changsheng 12 stars
  changsheng('changsheng'),
  muyu('muyu'),
  guandai('guandai'),
  linguan('linguan'),
  diwang('diwang'),
  shuai('shuai'),
  bing('bing'),
  si('si'),
  mu('mu'),
  jue('jue'),
  tai('tai'),
  yang('yang'),

  // Boshi 12 stars
  boshi('boshi'),
  lishi('lishi'),
  qinglong('qinglong'),
  xiaohao('xiaohao'),
  jiangjun('jiangjun'),
  zhoushu('zhoushu'),
  faylian('faylian'),
  xishen('xishen'),
  bingfu('bingfu'),
  dahao('dahao'),
  suipo('suipo'),
  fubing('fubing'),
  guanfu('guanfu'),

  // Suiqian 12 stars
  suijian('suijian'),
  huiqi('huiqi'),
  sangmen('sangmen'),
  guansuo('guansuo'),
  gwanfu('gwanfu'),
  longde('longde'),
  baihu('baihu'),
  tiande('tiande'),
  diaoke('diaoke'),

  // Jiangqian 12 stars
  jiangxing('jiangxing'),
  panan('panan'),
  suiyi('suiyi'),
  xiishen('xiishen'),
  huagai('huagai'),
  jiesha('jiesha'),
  zhaisha('zhaisha'),
  tiansha('tiansha'),
  zhibei('zhibei'),
  xianchi('xianchi'),
  yuesha('yuesha'),
  wangshen('wangshen'),

  // Decadal horoscope stars
  yunkui('yunkui'),
  yunyue('yunyue'),
  yunchang('yunchang'),
  yunqu('yunqu'),
  yunluan('yunluan'),
  yunxi('yunxi'),
  yunlu('yunlu'),
  yunyang('yunyang'),
  yuntuo('yuntuo'),
  yunma('yunma'),

  // Yearly horoscope stars
  liukui('liukui'),
  liuyue('liuyue'),
  liuchang('liuchang'),
  liuqu('liuqu'),
  liuluan('liuluan'),
  liuxi('liuxi'),
  liulu('liulu'),
  liuyang('liuyang'),
  liutuo('liutuo'),
  liuma('liuma'),
  nianjie('nianjie'),

  // Monthly horoscope stars
  yuekui('yuekui'),
  yueyue('yueyue'),
  yuechang('yuechang'),
  yuequ('yuequ'),
  yueluan('yueluan'),
  yuexi('yuexi'),
  yuelu('yuelu'),
  yueyang('yueyang'),
  yuetuo('yuetuo'),
  yuema('yuema'),

  // Daily horoscope stars
  rikui('rikui'),
  riyue('riyue'),
  richang('richang'),
  riqu('riqu'),
  riluan('riluan'),
  rixi('rixi'),
  rilu('rilu'),
  riyang('riyang'),
  rituo('rituo'),
  rima('rima'),

  // Hourly horoscope stars
  shikui('shikui'),
  shiyue('shiyue'),
  shichang('shichang'),
  shiqu('shiqu'),
  shiluan('shiluan'),
  shixi('shixi'),
  shilu('shilu'),
  shiyang('shiyang'),
  shituo('shituo'),
  shima('shima');

  const StarKey(this.key);

  /// Canonical `iztro` star key.
  final String key;

  static final Map<String, StarKey> _byKey = {
    for (final star in StarKey.values) star.key: star,
  };

  /// Looks up a [StarKey] by canonical key string.
  static StarKey? tryFromKey(String key) => _byKey[key];
}
