# iztro_dart

[![Dart CI](https://github.com/tihonovaaybeniz-code/iztro_dart/actions/workflows/ci.yml/badge.svg)](https://github.com/tihonovaaybeniz-code/iztro_dart/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

纯 Dart 紫微斗数（Ziwei Doushu）排盘、运限分析与 LLM 结构化表达引擎，基于 [`SylarLong/iztro`](https://github.com/SylarLong/iztro) (`v2.6.5`) 全量移植并扩展。

> **100% Pure Dart · 零 Flutter 依赖 · 零 `dart:io` 依赖** — 天然支持 Android、iOS、macOS、Windows、Linux、Web 与 Dart VM 服务端。

---

## 特性概览 / Features

| 模块 | 能力说明 | 对齐与增值 |
|---|---|---|
| **纯 Dart 架构** | 核心库仅依赖纯 Dart MIT 库 [`lunar`](https://pub.dev/packages/lunar)（与 `iztro` 底层 `lunar-typescript` 同源），无 Flutter / GetX / 网络库 / `dart:io` | 全端可编译运行 |
| **可插拔历法层** | 内置 `DefaultLunarAdapter`（支持公历/农历互转、1582 年儒略历切换、立春/节气交节精确干支）；通过 `LunarCalendarAdapter` / `BaseLunarCalendarAdapter` 可注入宿主自有历法引擎 | 杜绝多历法口径不一致 |
| **真太阳时校正** | 经度差 + 均时差（EoT）+ 中国大陆 1986–1991 历史夏令时表 + 相邻时辰 15 分钟边界预警 + `Astro.byTrueSolarTime(...)` | 纯数学计算，不内置城市数据库 |
| **本命与三盘重排** | 十四主星、六吉六煞、禄马、全部杂曜、长生/博士/将前/岁前十二神、来因宫；支持天盘 / 地盘（身宫立命）/ 人盘（福德立命）及通行派 / 中州派 | 完整对齐 `iztro@2.6.5` |
| **全量配置与隔离** | 支持 `yearDivide`、`horoscopeDivide`、`ageDivide`（自然年/农历生日）、`dayDivide`（早晚子时进日/留当日）、`mutagens` & `brightness` 自定义覆写；全局修改不污染已生成星盘 | 不可变配置快照 |
| **六层运限与链式查询** | 大限、童限、小限、流年、流月、流日、流时、`decadalList()` / `yearlyList()` / `monthlyList()`；三方四正、夹宫（`flankingPalaces`）、飞星四化（`fliesTo`）、离心自化（`selfMutaged`）、向心自化（`selfMutagedIn`） | `selfMutagedIn` & `palaceAtBranch` 为增值能力 |
| **6 语种词典** | 原生内置 `zh-CN`、`zh-TW`、`en-US`、`ja-JP`、`ko-KR`、`vi-VN` 完整本地化及星曜别名反查 | 零外部 i18n 运行时依赖 |
| **LLM Chart DSL** | `astrolabe.toLlmJson(...)` 生成紧凑 JSON（含 64-bit FNV-1a 命盘指纹、空宫借星、飞星冲照、动态流年叠宫），`PatternDetector.detect(...)` 预检 14 类经典格局与破格因子 | 辅助大模型无幻觉解盘 |

---

## 安装 / Installation

在 `pubspec.yaml` 中通过 Git Tag 引入（纯 Dart 与 Flutter 工程均适用）：

```yaml
dependencies:
  iztro_dart:
    git:
      url: https://github.com/tihonovaaybeniz-code/iztro_dart.git
      ref: v0.2.0
```

---

## 快速开始 / Quick Start

### 1. 基础排盘与运限 / Basic Chart & Horoscope

```dart
import 'package:iztro_dart/iztro_dart.dart';

void main() {
  // 公历排盘（亦支持 Astro.byLunar / Astro.withOptions）
  final chart = Astro.bySolar('2000-8-16', 2, Gender.female);

  print(chart.lunarDate);                 // 二〇〇〇年七月十七
  print(chart.chineseDate);               // 庚辰 甲申 丙午 庚寅
  print(chart.fiveElementsClass);         // 木三局
  print(chart.earthlyBranchOfSoulPalace); // 午

  // 按地支直接查宫（方便以 子=0..亥=11 为基准的 UI 组件调用）
  final ziPalace = chart.palaceAtBranch(EarthlyBranch.zi);
  print(ziPalace.name);

  // 六层运限查询
  final horo = chart.horoscope('2023-8-19 3:12');
  print('虚岁=${horo.age.nominalAge}, 大限=${horo.decadal.heavenlyStem}${horo.decadal.earthlyBranch}');
}
```

### 2. 真太阳时排盘 / True Solar Time

```dart
final tstResult = Astro.byTrueSolarTime(
  DateTime(1988, 7, 15, 13, 20), // 含中国夏令时历史区间
  longitude: 104.0668,           // 成都经度（东经为正）
  utcOffsetMinutes: 480,         // UTC+8
  gender: Gender.male,
);

print('真太阳时: ${tstResult.trueSolarTime.trueSolarTime}');
print('边界预警(<=15min): ${tstResult.trueSolarTime.isBoundaryWarning}');
print('命宫主星: ${tstResult.astrolabe.palace(PalaceName.soul)!.majorStars}');
```

### 3. 链式查询、飞星四化与夹宫 / Chainable Queries

```dart
final soul = chart.palace(PalaceName.soul)!;
final surrounded = chart.surroundedPalaces(PalaceName.soul);
final flanked = chart.flankingPalaces(PalaceName.soul);

final hasZiwei = surrounded.have([StarKey.ziweiMaj]);
final fliesLuToWealth = soul.fliesTo(PalaceName.wealth, [Mutagen.lu]);
final selfOut = soul.selfMutagedOneOf();    // 离心自化
final selfIn = soul.selfMutagedInOneOf();   // 向心自化（对宫宫干四化飞入本宫）
```

### 4. 自定义历法适配器 / Custom `LunarCalendarAdapter`

继承 `BaseLunarCalendarAdapter` 只需实现 `solarToLunar` 与 `lunarToSolar` 即可接入外部历法库（完整示例见 [`example/custom_calendar_adapter.dart`](example/custom_calendar_adapter.dart)）：

```dart
final class MyHostCalendarAdapter extends BaseLunarCalendarAdapter {
  const MyHostCalendarAdapter();

  @override
  LunarDateInfo solarToLunar(
    int year,
    int month,
    int day, {
    required int timeIndex,
    required DivideType yearDivide,
    required DivideType horoscopeDivide,
  }) {
    // 桥接宿主工程自有历法服务...
    throw UnimplementedError();
  }

  @override
  ({int year, int month, int day}) lunarToSolar(
    int lunarYear,
    int lunarMonth,
    int lunarDay, {
    bool isLeapMonth = false,
  }) {
    throw UnimplementedError();
  }
}
```

### 5. LLM Chart DSL、固定提示词模板与响应解析 / LLM Integration

```dart
// 结构化 JSON DSL 或高密度紧凑文本 DSL（节省约 40%–60% 输入 Token）
final dsl = chart.toLlmJson(
  targetDate: DateTime.now(),
  focusPalaces: const [PalaceName.soul, PalaceName.career],
);
final compactText = chart.toCompactDsl(focusPalaces: const [PalaceName.soul]);

// 开箱即用的防幻觉固定 Prompt（支持命格总览 / 单宫四段详批 / 流年运势 / 事业财富 / 感情婚姻）
final heroPrompt = chart.buildHeroPrompt();
final palacePrompt = chart.buildPalacePrompt(PalaceName.career);
final yearlyPrompt = chart.buildYearlyPrompt(targetDate: DateTime(2026, 5, 1));

// 发送 heroPrompt.toOpenAiMessages() 到任意大模型后，容错解析回结构化对象
final heroReading = ZiweiLlmResponseParser.parseHeroReading(rawModelOutput);
final palaceReading = ZiweiLlmResponseParser.parsePalaceReading(
  rawPalaceOutput,
  fallbackPalaceName: '官禄',
);

// 规则引擎预检经典格局与破格因素
final patterns = PatternDetector.detect(chart);
for (final p in patterns) {
  print('${p.name} (成格=${p.isClean}, 破格因素=${p.breakFactors})');
}
```

---

## 与 `iztro@2.6.5` 对拍验证报告 / Golden Parity Report

本仓库使用官方 NPM 包 `iztro@2.6.5`（见 [`tool/generate_golden_fixtures.mjs`](tool/generate_golden_fixtures.mjs)）导出 **870 组**黄金回归测试集，在 [`test/golden_parity_test.dart`](test/golden_parity_test.dart) 中进行逐字段深对比：

| 用例集 | 数量 | 覆盖维度 | 通过情况 |
|---|---|---|---|
| `regular_400.json` | 400 | 1920–2050 随机公历日期 × 0–12 时辰 × 男女 | **400 / 400 (100%)** |
| `leap_100.json` | 100 | 1950–2040 真实闰月（初一/十五/十六/末日，`fixLeap: true/false`，公农历双入口） | **100 / 100 (100%)** |
| `boundary_100.json` | 100 | 早晚子时（`dayDivide: forward/current`）、闰二月廿九跨日、除夕/正月初一、立春与节气交界（`yearDivide` / `horoscopeDivide`） | **100 / 100 (100%)** |
| `algorithm_astrotype_locale_120.json` | 120 | 中州派（`zhongzhou`）、地盘/人盘重排、`ageDivide: birthday`、自定义四化/亮度覆写、全 6 种语言 | **120 / 120 (100%)\*** |
| `horoscope_150.json` | 150 | 童限（1–6 岁）/成人大限/闰月流月、`horoscope()` 6 层、`decadalList()`、`yearlyList()`、`monthlyList()`、`flankingPalaces()` | **150 / 150 (100%)\*** |
| **合计** | **870** | — | **870 / 870 (100%)** |

\* **已知上游 `iztro@2.6.5` 缺陷说明（`iztro_dart` 已修复，未复刻其 Bug）**：
1. **韩语地盘/人盘重排重复 `천상`（`tianshang`）**（涉及 20 组 `ko-KR` + `earth/human` 用例）：`iztro@2.6.5` `rearrangeAstrolable` 使用 `kot(item.name) === 'tianshang'` 反查，因韩语中天相与天伤均译为 `'천상'`，`kot` 优先命中 `tianxiangMaj`，导致旧宫位未删除而追加第二颗 `천상`。`iztro_dart` 按强类型 `StarKey.tianshang` 移动，无重复星。
2. **英文地盘/人盘重排 `巳` 宫误输出 `'dead'`**（涉及 2 组 `en-US` + `earth/human` 用例）：`iztro@2.6.5` 在 `astro.ts:557-558` 直接调用 `t(palace.earthlyBranch)`（未先经过 `kot`），导致 `'si'` 命中了长生十二神 `'si': 'dead'`。`iztro_dart` 正确保留地支 `'si'`。
3. **未起运（`nominalAge <= 0` 且 `index == -1`）兜底天干地支未翻译**（涉及 4 组 `ageDivide: 'birthday'` 出生当日推运限用例）：`iztro@2.6.5` 在 `FunctionalAstrolabe.ts:483` 存在拼写错误 `kot(..., 'Heavnly')` 且 `493` 行未翻译，输出字面量 `'jia'`/`'zi'`。`iztro_dart` 正确按当前语言翻译输出。

---

## 致谢与协议 / License & Attribution

本项目采用 **MIT License** 开源，详见 [LICENSE](LICENSE) 与 [NOTICE](NOTICE)。

- 核心排盘算法、四化/亮度/杂曜规则与 6 语种专业术语移植自 [`SylarLong/iztro`](https://github.com/SylarLong/iztro) (`v2.6.5`, MIT License)。
- 默认历法适配器使用 [`6tail/lunar-flutter`](https://github.com/6tail/lunar-flutter) (`lunar`, MIT License)。
