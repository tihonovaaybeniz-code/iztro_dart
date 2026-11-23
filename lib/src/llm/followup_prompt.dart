import 'dart:convert';

import '../astro/functional_astrolabe.dart';
import '../core/types.dart';
import 'chart_dsl.dart';
import 'compact_dsl.dart';
import 'prompt_builder.dart';

/// Whitelisted preset follow-up questions attached below palace cards.
///
/// Using an explicit enum whitelist prevents arbitrary prompt injection and
/// keeps follow-up responses cacheable across users with identical charts.
enum ZiweiFollowupQuestion {
  careerMove(
    id: 'career_move',
    title: '今年适合变动/跳槽吗？',
    focusPalaces: [PalaceName.career, PalaceName.surface, PalaceName.soul],
    instruction: '请重点对比官禄宫、迁移宫与流年叠宫的禄权科忌及冲宫，分析今年“稳守深耕”还是“主动换赛道/外拓”更合适，并给出判断信号。',
  ),
  careerFriction(
    id: 'career_friction',
    title: '如何化解职场压力与人际摩擦？',
    focusPalaces: [PalaceName.career, PalaceName.friends, PalaceName.soul],
    instruction: '请聚焦官禄宫、仆役(交友)宫、煞星及破格因子（若有），分析协作痛点与具体沟通降摩擦策略。',
  ),
  wealthStrategy(
    id: 'wealth_strategy',
    title: '我的求财方式与理财避坑重点？',
    focusPalaces: [PalaceName.wealth, PalaceName.property, PalaceName.soul],
    instruction: '请结合财帛宫、田宅宫与飞星禄忌去向，说明偏重专业正财还是资源整合，并提醒稳健财务边界（不得给出具体证券买卖指令）。',
  ),
  loveHarmony(
    id: 'love_harmony',
    title: '亲密关系互动模式与相处建议？',
    focusPalaces: [PalaceName.spouse, PalaceName.spirit, PalaceName.soul],
    instruction: '请结合夫妻宫、福德宫及空宫借星/飞星四化，温和解析伴侣期待与日常相处节奏，严禁绝对化婚恋断语。',
  ),
  healthRhythm(
    id: 'health_rhythm',
    title: '今年身心压力源与作息调养重点？',
    focusPalaces: [PalaceName.health, PalaceName.spirit, PalaceName.soul],
    instruction: '请结合疾厄宫与福德宫星曜及流年四化，说明今年情绪消耗与作息养护重点（仅作日常节律参考，严禁给出医疗诊断）。',
  ),
  yearlyOpportunity(
    id: 'yearly_opportunity',
    title: '今年最值得发力的方向与月份？',
    focusPalaces: [PalaceName.soul, PalaceName.career, PalaceName.wealth],
    instruction: '请结合大限、流年叠宫及禄权科落宫，提炼今年 1~2 个高回报发力方向，并提示需保持耐心的关键月份。',
  );

  const ZiweiFollowupQuestion({
    required this.id,
    required this.title,
    required this.focusPalaces,
    required this.instruction,
  });

  /// Canonical whitelist ID sent in backend thin-proxy requests.
  final String id;

  /// UI chip display title.
  final String title;

  /// Palaces highlighted as `★焦点` in the DSL.
  final List<PalaceName> focusPalaces;

  /// Question-specific reasoning focus appended to the prompt.
  final String instruction;

  /// Looks up a whitelisted question by [id].
  static ZiweiFollowupQuestion? tryFromId(String id) {
    final trimmed = id.trim();
    for (final q in ZiweiFollowupQuestion.values) {
      if (q.id == trimmed || q.name == trimmed) {
        return q;
      }
    }
    return null;
  }
}

/// Structured JSON answer returned for a [ZiweiFollowupQuestion].
class ZiweiFollowupAnswerPayload {
  const ZiweiFollowupAnswerPayload({
    required this.questionId,
    required this.questionTitle,
    required this.summary,
    required this.analysis,
    required this.actionSteps,
    required this.caution,
  });

  final String questionId;
  final String questionTitle;
  final String summary;
  final String analysis;
  final List<String> actionSteps;
  final String caution;

  factory ZiweiFollowupAnswerPayload.fromJson(
    Map<String, dynamic> json, {
    String fallbackQuestionId = '',
    String fallbackQuestionTitle = '',
  }) {
    final rawSteps = json['actionSteps'];
    final steps = rawSteps is List
        ? rawSteps
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    final parsedId = (json['questionId'] ?? '').toString().trim();
    final parsedTitle = (json['questionTitle'] ?? '').toString().trim();

    return ZiweiFollowupAnswerPayload(
      questionId: parsedId.isEmpty ? fallbackQuestionId : parsedId,
      questionTitle: parsedTitle.isEmpty ? fallbackQuestionTitle : parsedTitle,
      summary: (json['summary'] ?? '').toString().trim(),
      analysis: (json['analysis'] ?? '').toString().trim(),
      actionSteps: steps,
      caution: (json['caution'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'questionId': questionId,
        'questionTitle': questionTitle,
        'summary': summary,
        'analysis': analysis,
        'actionSteps': actionSteps,
        'caution': caution,
      };
}

/// Builds fixed, cacheable prompts for preset [ZiweiFollowupQuestion] chips.
abstract final class ZiweiFollowupPromptBuilder {
  /// Builds a [ZiweiLlmPrompt] targeting [ZiweiFollowupAnswerPayload].
  static ZiweiLlmPrompt build(
    FunctionalAstrolabe astrolabe,
    ZiweiFollowupQuestion question, {
    DateTime? targetDate,
    int? timeIndex,
    ZiweiDslFormat format = ZiweiDslFormat.compactText,
    String? extraInstructions,
  }) {
    final effectiveTarget = targetDate ?? DateTime.now();
    final horo = astrolabe.horoscope(effectiveTarget, timeIndex);
    final fingerprint = ChartDsl.fingerprintOf(astrolabe);
    final dsl = format == ZiweiDslFormat.compactText
        ? ChartCompactDsl.render(
            astrolabe,
            targetDate: effectiveTarget,
            timeIndex: timeIndex,
            focusPalaces: question.focusPalaces,
          )
        : jsonEncode(
            astrolabe.toLlmJson(
              targetDate: effectiveTarget,
              timeIndex: timeIndex,
              focusPalaces: question.focusPalaces,
            ),
          );

    final schemaHint = '''
{
  "questionId": "${question.id}",
  "questionTitle": "${question.title}",
  "summary": "20~40字一句话明确结论",
  "analysis": "120~180字紧扣星曜、亮度、四化飞星与叠宫的分析依据",
  "actionSteps": ["可执行步骤1", "可执行步骤2", "可执行步骤3"],
  "caution": "40~80字温和提醒（避免宿命论恐吓）"
}''';

    final buf = StringBuffer()
      ..writeln('请针对以下预设追问生成结构化回答 JSON：')
      ..writeln('【问题】${question.title} (id=${question.id})')
      ..writeln('【解析要点】${question.instruction}')
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
      ..writeln(
        '【当前流年干支参考】${horo.yearly.heavenlyStem}${horo.yearly.earthlyBranch}',
      )
      ..writeln('【命盘输入数据（严禁篡改或补充未列出的星曜）】')
      ..writeln(dsl);

    return ZiweiLlmPrompt(
      scene: ZiweiPromptScene.followup,
      promptVersion: ZiweiPromptBuilder.promptVersion,
      fingerprint: fingerprint,
      cacheKey:
          '$fingerprint:${ZiweiPromptScene.followup.key}:${question.id}:${effectiveTarget.year}:${ZiweiPromptBuilder.promptVersion}:${format.key}',
      systemPrompt: ZiweiPromptBuilder.baseSystemPrompt,
      userPrompt: buf.toString().trimRight(),
      expectedSchemaHint: schemaHint,
      dslFormat: format,
      targetYear: effectiveTarget.year,
    );
  }
}
