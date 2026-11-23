import 'dart:convert';

import '../astro/functional_astrolabe.dart';
import '../core/types.dart';
import '../data/locales/locale_registry.dart';
import 'chart_dsl.dart';
import 'compact_dsl.dart';

/// Supported prompt scenarios for [ZiweiPromptBuilder].
enum ZiweiPromptScene {
  hero('hero'),
  palace('palace'),
  yearly('yearly'),
  careerWealth('careerWealth'),
  relationship('relationship'),
  followup('followup'),
  zeji('zeji');

  const ZiweiPromptScene(this.key);

  final String key;
}

/// Serialization format embedded into the LLM user prompt.
enum ZiweiDslFormat {
  compactText('compact'),
  json('json');

  const ZiweiDslFormat(this.key);

  final String key;
}

/// Self-contained prompt bundle ready for OpenAI-compatible `/v1/chat/completions`
/// requests and fingerprint-based caching.
class ZiweiLlmPrompt {
  const ZiweiLlmPrompt({
    required this.scene,
    required this.promptVersion,
    required this.fingerprint,
    required this.cacheKey,
    required this.systemPrompt,
    required this.userPrompt,
    required this.expectedSchemaHint,
    required this.dslFormat,
    this.focusPalaceName,
    this.targetYear,
  });

  final ZiweiPromptScene scene;
  final String promptVersion;
  final String fingerprint;
  final String cacheKey;
  final String systemPrompt;
  final String userPrompt;
  final String expectedSchemaHint;
  final ZiweiDslFormat dslFormat;
  final String? focusPalaceName;
  final int? targetYear;

  /// Formats as standard OpenAI/DeepSeek `messages` payload.
  List<Map<String, String>> toOpenAiMessages() => <Map<String, String>>[
        <String, String>{'role': 'system', 'content': systemPrompt},
        <String, String>{'role': 'user', 'content': userPrompt},
      ];

  Map<String, dynamic> toJson() => <String, dynamic>{
        'scene': scene.key,
        'promptVersion': promptVersion,
        'fingerprint': fingerprint,
        'cacheKey': cacheKey,
        'dslFormat': dslFormat.key,
        if (focusPalaceName != null) 'focusPalaceName': focusPalaceName,
        if (targetYear != null) 'targetYear': targetYear,
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt,
        'expectedSchemaHint': expectedSchemaHint,
      };
}

/// Builds fixed, hallucination-resistant prompts from a [FunctionalAstrolabe]
/// for downstream LLM inference.
abstract final class ZiweiPromptBuilder {
  /// Bump this version whenever prompt rules or output schemas change so cache
  /// keys invalidate cleanly.
  static const String promptVersion = 'v1';

  /// Fixed anti-hallucination and compliance system prompt.
  static const String baseSystemPrompt = '''
你是一位精通《紫微斗数全书》与现代心理/人生决策分析的紫微斗数专业解读顾问。

【核心防幻觉铁律 — 必须 100% 遵守】
1. 严禁重新排盘或自行推算干支、星曜、亮度、四化；所有论断必须严格以输入命盘数据中明确列出的星曜、亮度（庙旺得利平不陷）、生年/大限/流年四化、飞星四化去向（冲宫）与《格局预检》为唯一事实来源。
2. 遇到「空宫」时，必须明确结合其「借对宫主星」及三方四正来分析，不得把空宫当成无主星可言，也不得把对宫借星说成原本就在本宫。
3. 提及格局时，必须直接依据「格局预检」给出的名称、成格/破格状态与破格因子，客观说明，不得编造未命中的格局。
4. 论断风格：使用现代简体中文白话表达，温暖、克制、重建设性与可落地建议。严禁制造恐慌、绝对化宿命论（如“必离婚”“必破产”“有血光之灾”），严禁给出医疗诊断或具体金融投资买卖指令。
5. 输出格式：只输出一段合法的 JSON 对象本身，不要输出任何 Markdown 代码块标记（不要 ```json）、不要输出推理过程、不要输出前缀或后缀说明文字，确保字符串内双引号合法转义。''';

  /// Builds a prompt targeting a [ZiweiHeroReadingPayload] JSON response.
  static ZiweiLlmPrompt buildHeroPrompt(
    FunctionalAstrolabe astrolabe, {
    DateTime? targetDate,
    int? timeIndex,
    ZiweiDslFormat format = ZiweiDslFormat.compactText,
    String? extraInstructions,
  }) {
    final effectiveTarget = targetDate ?? DateTime.now();
    final horo = astrolabe.horoscope(effectiveTarget, timeIndex);
    final fingerprint = ChartDsl.fingerprintOf(astrolabe);
    final dsl = _renderDsl(
      astrolabe,
      format: format,
      targetDate: effectiveTarget,
      timeIndex: timeIndex,
      focusPalaces: const [
        PalaceName.soul,
        PalaceName.career,
        PalaceName.wealth
      ],
    );

    const schemaHint = '''
{
  "title": "6~14字命格称号，如：紫府同宫 · 沉稳掌局型",
  "subtitle": "18~36字一句话核心定调，点明命宫主星特质与行运底色",
  "tags": ["核心标签1(2~5字)", "核心标签2(2~5字)", "核心标签3(2~5字)"],
  "overview": "150~220字白话命格综述，必须点明命宫核心星曜（空宫说明借星）、三方四正联动、格局预检结论与破格注意点",
  "yearlyTheme": "80~120字当前流年核心主题，结合流年干支、叠宫与流年四化"
}''';

    final userPrompt = _composeUserPrompt(
      taskTitle:
          '请为以下命盘生成「命格总览」结构化解读 JSON（聚焦命宫、身宫、格局预检及 ${effectiveTarget.year} 流年大势）：',
      schemaHint: schemaHint,
      dsl: dsl,
      horoYearlyGanZhi:
          '${horo.yearly.heavenlyStem}${horo.yearly.earthlyBranch}',
      extraInstructions: extraInstructions,
    );

    return ZiweiLlmPrompt(
      scene: ZiweiPromptScene.hero,
      promptVersion: promptVersion,
      fingerprint: fingerprint,
      cacheKey:
          '$fingerprint:${ZiweiPromptScene.hero.key}:${effectiveTarget.year}:$promptVersion:${format.key}',
      systemPrompt: baseSystemPrompt,
      userPrompt: userPrompt,
      expectedSchemaHint: schemaHint,
      dslFormat: format,
      targetYear: effectiveTarget.year,
    );
  }

  /// Builds a prompt targeting a [ZiweiPalaceReadingPayload] JSON response for
  /// a single [focusPalace] (1:1 aligned with host `ZiweiPalaceReading`).
  static ZiweiLlmPrompt buildPalacePrompt(
    FunctionalAstrolabe astrolabe,
    PalaceName focusPalace, {
    DateTime? targetDate,
    int? timeIndex,
    ZiweiDslFormat format = ZiweiDslFormat.compactText,
    String? extraInstructions,
  }) {
    final effectiveTarget = targetDate ?? DateTime.now();
    final horo = astrolabe.horoscope(effectiveTarget, timeIndex);
    final lang = astrolabe.configSnapshot.language;
    final palaceDisplayName = LocaleRegistry.translate(focusPalace.key, lang);
    final fingerprint = ChartDsl.fingerprintOf(astrolabe);
    final dsl = _renderDsl(
      astrolabe,
      format: format,
      targetDate: effectiveTarget,
      timeIndex: timeIndex,
      focusPalaces: [focusPalace],
    );

    final schemaHint = '''
{
  "palaceName": "$palaceDisplayName",
  "corePattern": "110~170字落星核心格局：分析$palaceDisplayName所坐主星（若为空宫须明言借对宫何星）与亮度，解析底层行为倾向",
  "flowYearFocus": "90~140字${effectiveTarget.year}${horo.yearly.heavenlyStem}${horo.yearly.earthlyBranch}流年此宫重点：结合大限/流年叠宫与四化引动，给出今年节奏提示",
  "modifierAnalysis": "100~150字三方四正与飞星共振：结合辅星、煞星、本宫宫干飞星四化（禄权科忌落宫与冲宫）及离心/向心自化进行分析",
  "actionAdvice": "90~140字现实破局与相处建议：给出 2~3 条具体可执行的现代生活或职场策略"
}''';

    final userPrompt = _composeUserPrompt(
      taskTitle:
          '请聚焦「$palaceDisplayName」生成结构化四段深度详批 JSON（严格围绕标记★焦点的宫位及其三方四正与飞星）：',
      schemaHint: schemaHint,
      dsl: dsl,
      horoYearlyGanZhi:
          '${horo.yearly.heavenlyStem}${horo.yearly.earthlyBranch}',
      extraInstructions: extraInstructions,
    );

    return ZiweiLlmPrompt(
      scene: ZiweiPromptScene.palace,
      promptVersion: promptVersion,
      fingerprint: fingerprint,
      cacheKey:
          '$fingerprint:${ZiweiPromptScene.palace.key}:${focusPalace.key}:${effectiveTarget.year}:$promptVersion:${format.key}',
      systemPrompt: baseSystemPrompt,
      userPrompt: userPrompt,
      expectedSchemaHint: schemaHint,
      dslFormat: format,
      focusPalaceName: palaceDisplayName,
      targetYear: effectiveTarget.year,
    );
  }

  /// Builds a prompt targeting a [ZiweiYearlyReadingPayload] JSON response.
  static ZiweiLlmPrompt buildYearlyPrompt(
    FunctionalAstrolabe astrolabe, {
    DateTime? targetDate,
    int? timeIndex,
    ZiweiDslFormat format = ZiweiDslFormat.compactText,
    String? extraInstructions,
  }) {
    final effectiveTarget = targetDate ?? DateTime.now();
    final horo = astrolabe.horoscope(effectiveTarget, timeIndex);
    final yearlyGanZhi =
        '${horo.yearly.heavenlyStem}${horo.yearly.earthlyBranch}';
    final fingerprint = ChartDsl.fingerprintOf(astrolabe);
    final dsl = _renderDsl(
      astrolabe,
      format: format,
      targetDate: effectiveTarget,
      timeIndex: timeIndex,
      focusPalaces: [
        astrolabe.palace(horo.yearly.index)?.palaceName ?? PalaceName.soul,
        astrolabe.palace(horo.decadal.index)?.palaceName ?? PalaceName.career,
      ],
    );

    final schemaHint = '''
{
  "year": ${effectiveTarget.year},
  "yearGanZhi": "$yearlyGanZhi",
  "headline": "12~24字流年总纲",
  "opportunities": "110~160字今年机会与助力领域（结合大限/流年禄权科与叠宫）",
  "risks": "100~150字今年需防与压力源（结合流年化忌、冲宫与破格因子，温和提示）",
  "keyMonths": ["关键月份1及重点(如农历三月: ...)", "关键月份2及重点", "关键月份3及重点"],
  "actionChecklist": ["可执行行动建议1", "可执行行动建议2", "可执行行动建议3"]
}''';

    final userPrompt = _composeUserPrompt(
      taskTitle: '请围绕 ${effectiveTarget.year}（$yearlyGanZhi）流年生成结构化年度运势 JSON：',
      schemaHint: schemaHint,
      dsl: dsl,
      horoYearlyGanZhi: yearlyGanZhi,
      extraInstructions: extraInstructions,
    );

    return ZiweiLlmPrompt(
      scene: ZiweiPromptScene.yearly,
      promptVersion: promptVersion,
      fingerprint: fingerprint,
      cacheKey:
          '$fingerprint:${ZiweiPromptScene.yearly.key}:${effectiveTarget.year}:$promptVersion:${format.key}',
      systemPrompt: baseSystemPrompt,
      userPrompt: userPrompt,
      expectedSchemaHint: schemaHint,
      dslFormat: format,
      targetYear: effectiveTarget.year,
    );
  }

  /// Convenience topic builder for [ZiweiPromptScene.careerWealth] or
  /// [ZiweiPromptScene.relationship], returning a [ZiweiPalaceReadingPayload]
  /// or [ZiweiHeroReadingPayload]-compatible prompt.
  static ZiweiLlmPrompt buildTopicPrompt(
    FunctionalAstrolabe astrolabe,
    ZiweiPromptScene scene, {
    PalaceName focusPalace = PalaceName.soul,
    DateTime? targetDate,
    int? timeIndex,
    ZiweiDslFormat format = ZiweiDslFormat.compactText,
    String? extraInstructions,
  }) {
    return switch (scene) {
      ZiweiPromptScene.hero => buildHeroPrompt(
          astrolabe,
          targetDate: targetDate,
          timeIndex: timeIndex,
          format: format,
          extraInstructions: extraInstructions,
        ),
      ZiweiPromptScene.palace => buildPalacePrompt(
          astrolabe,
          focusPalace,
          targetDate: targetDate,
          timeIndex: timeIndex,
          format: format,
          extraInstructions: extraInstructions,
        ),
      ZiweiPromptScene.yearly => buildYearlyPrompt(
          astrolabe,
          targetDate: targetDate,
          timeIndex: timeIndex,
          format: format,
          extraInstructions: extraInstructions,
        ),
      ZiweiPromptScene.careerWealth => buildPalacePrompt(
          astrolabe,
          PalaceName.career,
          targetDate: targetDate,
          timeIndex: timeIndex,
          format: format,
          extraInstructions: '请特别结合官禄宫与财帛宫的双宫联动、飞星禄忌流向来解读事业赛道与求财模式。'
              '${extraInstructions != null ? " $extraInstructions" : ""}',
        ),
      ZiweiPromptScene.relationship => buildPalacePrompt(
          astrolabe,
          PalaceName.spouse,
          targetDate: targetDate,
          timeIndex: timeIndex,
          format: format,
          extraInstructions: '请特别结合夫妻宫、福德宫与迁移宫的情绪互动模式与伴侣相处建议来展开。'
              '${extraInstructions != null ? " $extraInstructions" : ""}',
        ),
      ZiweiPromptScene.followup ||
      ZiweiPromptScene.zeji =>
        throw ArgumentError.value(
          scene,
          'scene',
          'Use ZiweiFollowupPromptBuilder or ZejiPromptBuilder for followup/zeji scenes.',
        ),
    };
  }

  static String _renderDsl(
    FunctionalAstrolabe astrolabe, {
    required ZiweiDslFormat format,
    required DateTime targetDate,
    int? timeIndex,
    required List<PalaceName> focusPalaces,
  }) {
    if (format == ZiweiDslFormat.compactText) {
      return ChartCompactDsl.render(
        astrolabe,
        targetDate: targetDate,
        timeIndex: timeIndex,
        focusPalaces: focusPalaces,
      );
    }
    return jsonEncode(
      astrolabe.toLlmJson(
        targetDate: targetDate,
        timeIndex: timeIndex,
        focusPalaces: focusPalaces,
      ),
    );
  }

  static String _composeUserPrompt({
    required String taskTitle,
    required String schemaHint,
    required String dsl,
    required String horoYearlyGanZhi,
    String? extraInstructions,
  }) {
    final buf = StringBuffer()
      ..writeln(taskTitle)
      ..writeln()
      ..writeln('【必须严格遵循的 JSON 字段结构】')
      ..writeln(schemaHint.trim())
      ..writeln();
    if (extraInstructions != null && extraInstructions.trim().isNotEmpty) {
      buf
        ..writeln('【补充要求】')
        ..writeln(extraInstructions.trim())
        ..writeln();
    }
    buf
      ..writeln('【当前流年干支参考】$horoYearlyGanZhi')
      ..writeln('【命盘输入数据（严禁篡改或补充未列出的星曜）】')
      ..writeln(dsl);
    return buf.toString().trimRight();
  }
}
