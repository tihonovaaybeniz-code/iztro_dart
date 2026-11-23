import 'prompt_builder.dart';

/// Deterministic candidate day summary produced on-device by combining almanac
/// ZeJi hits, personal zodiac clash check, and Ziwei flow-day overlay.
class ZejiCandidateDay {
  const ZejiCandidateDay({
    required this.solarDate,
    required this.lunarText,
    required this.weekdayText,
    required this.ganZhiDay,
    required this.zhiShen,
    required this.jianChu,
    required this.chongSha,
    required this.almanacScore,
    required this.luckyHours,
    this.clashesUser = false,
    this.ziweiFlowDayPalace,
    this.ziweiFlowDayMutagens = const [],
  });

  /// Canonical `YYYY-MM-DD` solar date.
  final String solarDate;

  /// Chinese lunar label, e.g. `四月初八`.
  final String lunarText;

  final String weekdayText;
  final String ganZhiDay;
  final String zhiShen;
  final String jianChu;
  final String chongSha;
  final int almanacScore;

  /// Auspicious hours on this date, e.g. `['巳时(09:00-11:00)', ...]`.
  final List<String> luckyHours;

  /// Whether this day's Chongshen clashes with the user's (or partner's) zodiac.
  final bool clashesUser;

  /// Natal palace overlaid by the Ziwei flow-day (if birth profile provided).
  final String? ziweiFlowDayPalace;

  /// Active flow-day mutagen summary, e.g. `['禄:天同', '忌:巨门']`.
  final List<String> ziweiFlowDayMutagens;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'solarDate': solarDate,
        'lunarText': lunarText,
        'weekdayText': weekdayText,
        'ganZhiDay': ganZhiDay,
        'zhiShen': zhiShen,
        'jianChu': jianChu,
        'chongSha': chongSha,
        'almanacScore': almanacScore,
        'luckyHours': luckyHours,
        'clashesUser': clashesUser,
        if (ziweiFlowDayPalace != null)
          'ziweiFlowDayPalace': ziweiFlowDayPalace,
        if (ziweiFlowDayMutagens.isNotEmpty)
          'ziweiFlowDayMutagens': ziweiFlowDayMutagens,
      };
}

/// Detailed AI recommendation entry for one candidate day.
class ZejiPickDetail {
  const ZejiPickDetail({
    required this.date,
    required this.reason,
    required this.bestHours,
    required this.caution,
  });

  final String date;
  final String reason;
  final String bestHours;
  final String caution;

  factory ZejiPickDetail.fromJson(Map<String, dynamic> json) {
    return ZejiPickDetail(
      date: (json['date'] ?? '').toString().trim(),
      reason: (json['reason'] ?? '').toString().trim(),
      bestHours: (json['bestHours'] ?? '').toString().trim(),
      caution: (json['caution'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': date,
        'reason': reason,
        'bestHours': bestHours,
        'caution': caution,
      };
}

/// Structured AI ZeJi (auspicious date selection) recommendation payload.
class ZejiRecommendationPayload {
  const ZejiRecommendationPayload({
    required this.eventWord,
    required this.headline,
    required this.bestDate,
    required this.bestDateSummary,
    required this.topPicks,
    required this.preparationTips,
  });

  final String eventWord;
  final String headline;
  final String bestDate;
  final String bestDateSummary;
  final List<ZejiPickDetail> topPicks;
  final List<String> preparationTips;

  factory ZejiRecommendationPayload.fromJson(
    Map<String, dynamic> json, {
    String fallbackEventWord = '',
  }) {
    final rawPicks = json['topPicks'];
    final picks = rawPicks is List
        ? rawPicks
            .whereType<Map<Object?, Object?>>()
            .map((e) => ZejiPickDetail.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.date.isNotEmpty)
            .toList(growable: false)
        : const <ZejiPickDetail>[];

    final rawTips = json['preparationTips'];
    final tips = rawTips is List
        ? rawTips
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    final parsedWord = (json['eventWord'] ?? '').toString().trim();

    return ZejiRecommendationPayload(
      eventWord: parsedWord.isEmpty ? fallbackEventWord : parsedWord,
      headline: (json['headline'] ?? '').toString().trim(),
      bestDate: (json['bestDate'] ?? '').toString().trim(),
      bestDateSummary: (json['bestDateSummary'] ?? '').toString().trim(),
      topPicks: picks,
      preparationTips: tips,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'eventWord': eventWord,
        'headline': headline,
        'bestDate': bestDate,
        'bestDateSummary': bestDateSummary,
        'topPicks': topPicks.map((p) => p.toJson()).toList(growable: false),
        'preparationTips': preparationTips,
      };
}

/// Builds deterministic, anti-hallucination AI ZeJi prompts from pre-filtered
/// [ZejiCandidateDay] facts (LLM never searches calendars or invents dates).
abstract final class ZejiPromptBuilder {
  static final BigInt _fnvOffsetBasis = BigInt.parse(
    'cbf29ce484222325',
    radix: 16,
  );
  static final BigInt _fnvPrime = BigInt.parse('100000001b3', radix: 16);
  static final BigInt _mask64 = (BigInt.one << 64) - BigInt.one;

  /// Fixed system prompt enforcing zero date fabrication and cultural framing.
  static const String zejiSystemPrompt = '''
你是一位精通传统黄历择日与民俗文化研究的个人日程顾问。

【核心防幻觉铁律 — 必须 100% 遵守】
1. 严禁自行推算历法或编造输入列表之外的日期、干支、值神、冲煞与吉时；只能从输入《候选吉日事实表》中挑选并解释。
2. 必须尊重输入中标注的个人生肖（及伴侣生肖）与冲煞避忌，给出具体原因与对应最佳吉时。
3. 风格温和、理性、重现实筹备建议，作为传统民俗文化参考；严禁恐吓性迷信言辞。
4. 只输出一段合法的 JSON 对象本身，不要输出 Markdown 代码块标记，不要输出推理或前后说明文字。''';

  /// Renders compact plain-text DSL for Top-N candidate days.
  static String renderCompactDsl({
    required String eventWord,
    required String userAnimal,
    String? partnerAnimal,
    required List<ZejiCandidateDay> candidates,
  }) {
    final buf = StringBuffer()
      ..writeln('# 个人择吉候选事实表')
      ..writeln(
        '事项:$eventWord | 本人生肖:$userAnimal'
        '${partnerAnimal != null && partnerAnimal.isNotEmpty ? " | 伴侣/同行生肖:$partnerAnimal" : ""}',
      )
      ..writeln('候选日数:${candidates.length}')
      ..writeln();

    for (var i = 0; i < candidates.length; i++) {
      final c = candidates[i];
      final hours = c.luckyHours.isEmpty ? '无标注' : c.luckyHours.join('、');
      buf.write(
        '${i + 1}. ${c.solarDate} (${c.weekdayText}, 农历${c.lunarText}) | '
        '日柱:${c.ganZhiDay} | 值神:${c.zhiShen} | 建除:${c.jianChu} | '
        '${c.chongSha} | 黄历分:${c.almanacScore} | '
        '冲本人:${c.clashesUser ? "是(注意)" : "否"} | 吉时:$hours',
      );
      if (c.ziweiFlowDayPalace != null) {
        buf.write(' | 紫微流日:${c.ziweiFlowDayPalace}');
      }
      if (c.ziweiFlowDayMutagens.isNotEmpty) {
        buf.write('(${c.ziweiFlowDayMutagens.join(",")})');
      }
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  /// Builds a [ZiweiLlmPrompt] targeting [ZejiRecommendationPayload].
  static ZiweiLlmPrompt buildRecommendPrompt({
    required String eventWord,
    required String userAnimal,
    String? partnerAnimal,
    required List<ZejiCandidateDay> candidates,
    String? chartFingerprint,
    String? extraInstructions,
  }) {
    if (candidates.isEmpty) {
      throw ArgumentError.value(
        candidates,
        'candidates',
        'At least one candidate day is required.',
      );
    }

    final dsl = renderCompactDsl(
      eventWord: eventWord,
      userAnimal: userAnimal,
      partnerAnimal: partnerAnimal,
      candidates: candidates,
    );

    final datesSig = candidates
        .map(
          (c) =>
              '${c.solarDate}:${c.clashesUser}:${c.ziweiFlowDayPalace ?? ""}',
        )
        .join(',');
    final fpSource =
        '$eventWord|$userAnimal|${partnerAnimal ?? ""}|${chartFingerprint ?? ""}|$datesSig';
    final hash = _fnv64Hex(fpSource);

    final schemaHint = '''
{
  "eventWord": "$eventWord",
  "headline": "12~24字本次择吉核心结论",
  "bestDate": "从候选列表选取的首选日期 YYYY-MM-DD",
  "bestDateSummary": "60~100字首选日综合推荐理由（可作免费预览展示）",
  "topPicks": [
    {
      "date": "候选日期 YYYY-MM-DD",
      "reason": "60~110字结合值神/建除/冲煞避忌与流日叠宫的适配原因",
      "bestHours": "从该日候选吉时中精选 1~2 个并简要说明",
      "caution": "30~60字当天煞方及现实筹备提醒"
    }
  ],
  "preparationTips": ["通用筹备建议1", "通用筹备建议2", "通用筹备建议3"]
}''';

    final buf = StringBuffer()
      ..writeln('请从以下已筛出的候选日期中，为「$eventWord」精选并生成最多 3 个推荐日的结构化 JSON：')
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
    buf.writeln(dsl);

    return ZiweiLlmPrompt(
      scene: ZiweiPromptScene.zeji,
      promptVersion: ZiweiPromptBuilder.promptVersion,
      fingerprint: hash,
      cacheKey:
          '$hash:${ZiweiPromptScene.zeji.key}:${ZiweiPromptBuilder.promptVersion}',
      systemPrompt: zejiSystemPrompt,
      userPrompt: buf.toString().trimRight(),
      expectedSchemaHint: schemaHint,
      dslFormat: ZiweiDslFormat.compactText,
    );
  }

  static String _fnv64Hex(String input) {
    var hash = _fnvOffsetBasis;
    for (final unit in input.codeUnits) {
      hash = ((hash ^ BigInt.from(unit)) * _fnvPrime) & _mask64;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
