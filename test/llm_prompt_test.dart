import 'dart:convert';

import 'package:iztro_dart/iztro_dart.dart';
import 'package:test/test.dart';

void main() {
  setUp(Astro.resetConfig);
  tearDown(Astro.resetConfig);

  group('ChartCompactDsl & ZiweiPromptBuilder (v0.2.0)', () {
    test(
        'compact DSL is substantially shorter than JSON while keeping full facts',
        () {
      final chart = Astro.bySolar('2000-8-16', 2, Gender.female);
      final targetDate = DateTime(2026, 5, 1);

      final jsonStr = jsonEncode(
        chart.toLlmJson(
          targetDate: targetDate,
          focusPalaces: const [PalaceName.parents],
        ),
      );
      final compact = chart.toCompactDsl(
        targetDate: targetDate,
        focusPalaces: const [PalaceName.parents],
      );

      expect(compact.length, lessThan(jsonStr.length * 0.65));
      expect(compact, contains('★焦点'));
      expect(compact, contains('空宫(借'));
      expect(compact, contains('飞化:'));
      expect(compact, contains('丙午'));
    });

    test('builds hero, palace, yearly, and topic prompts with cache keys', () {
      final chart = Astro.bySolar('1995-8-16', 5, Gender.female);
      final target = DateTime(2026, 6, 15);

      final hero = chart.buildHeroPrompt(targetDate: target);
      final palace =
          chart.buildPalacePrompt(PalaceName.career, targetDate: target);
      final yearly = chart.buildYearlyPrompt(targetDate: target);
      final careerTopic = ZiweiPromptBuilder.buildTopicPrompt(
        chart,
        ZiweiPromptScene.careerWealth,
        targetDate: target,
      );
      final loveTopic = ZiweiPromptBuilder.buildTopicPrompt(
        chart,
        ZiweiPromptScene.relationship,
        targetDate: target,
      );

      expect(hero.toOpenAiMessages(), hasLength(2));
      expect(hero.toOpenAiMessages().first['role'], 'system');
      expect(hero.toOpenAiMessages().last['role'], 'user');
      expect(hero.systemPrompt, contains('核心防幻觉铁律'));
      expect(hero.cacheKey, contains(':hero:2026:v1:compact'));

      expect(palace.focusPalaceName, '官禄');
      expect(palace.cacheKey, contains(':palace:careerPalace:2026:v1:compact'));

      expect(yearly.targetYear, 2026);
      expect(yearly.userPrompt, contains('丙午'));

      expect(careerTopic.userPrompt, contains('官禄宫与财帛宫'));
      expect(loveTopic.userPrompt, contains('夫妻宫'));

      // JSON format option embeds full JSON DSL.
      final jsonPrompt = chart.buildHeroPrompt(
        targetDate: target,
        format: ZiweiDslFormat.json,
      );
      expect(jsonPrompt.cacheKey, endsWith(':json'));
      expect(jsonPrompt.userPrompt, contains('"iztroBaseline":"2.6.5"'));
    });
  });

  group('ZiweiLlmResponseParser', () {
    test('parses clean hero, palace, and yearly JSON payloads', () {
      const heroRaw = '''
{
  "title": "紫微守命 · 稳健掌局型",
  "subtitle": "重秩序讲章法，流年宜顺势借力。",
  "tags": ["重诺守信", "统筹力强", "稳步破局"],
  "overview": "命宫紫微坐守，三方四正配合得宜，行事有章法。",
  "yearlyTheme": "2026丙午流年重在聚焦主业与资源协同。"
}
''';
      final hero = ZiweiLlmResponseParser.parseHeroReading(heroRaw);
      expect(hero, isNotNull);
      expect(hero!.title, '紫微守命 · 稳健掌局型');
      expect(hero.tags, ['重诺守信', '统筹力强', '稳步破局']);

      const palaceRaw = '''
{
  "palaceName": "官禄",
  "corePattern": "官禄宫星曜组合稳重，擅长把复杂任务拆解推进。",
  "flowYearFocus": "丙午流年工作节奏加快，适合承担跨团队协调。",
  "modifierAnalysis": "三方四正得吉曜辅佐，飞星禄权照入事业宫。",
  "actionAdvice": "保持核心项目优先级，定期复盘关键里程碑。"
}
''';
      final palace = ZiweiLlmResponseParser.parsePalaceReading(
        palaceRaw,
        fallbackPalaceName: '官禄',
      );
      expect(palace, isNotNull);
      expect(palace!.palaceName, '官禄');
      expect(palace.actionAdvice, contains('里程碑'));

      const yearlyRaw = '''
{
  "year": 2026,
  "yearGanZhi": "丙午",
  "headline": "蓄势进阶、稳中求进的一年",
  "opportunities": "流年天同化禄带动合作机会提升。",
  "risks": "注意沟通节奏，避免因急于推进而忽略细节。",
  "keyMonths": ["农历三月：适合敲定长期规划", "农历九月：团队协作收获期"],
  "actionChecklist": ["聚焦核心赛道", "留足现金缓冲"]
}
''';
      final yearly = ZiweiLlmResponseParser.parseYearlyReading(
        yearlyRaw,
        year: 2026,
        yearGanZhi: '丙午',
      );
      expect(yearly, isNotNull);
      expect(yearly!.year, 2026);
      expect(yearly.keyMonths, hasLength(2));
    });

    test(
        'recovers valid JSON from <think> tags, markdown fences, and leaked reasoning prose',
        () {
      const thinkAndFence = '''
<think>
先检查输入数据... {"draft": true}
</think>
```json
{
  "title": "天府坐命 · 厚积薄发型",
  "subtitle": "重稳健积累，宜在规范体系内发挥。",
  "tags": ["务实", "守成", "包容"],
  "overview": "命宫天府庙旺守垣，抗风险意识强，遇事沉着。",
  "yearlyTheme": "流年适合梳理资产与能力护城河。"
}
```
''';
      final parsed1 = ZiweiLlmResponseParser.parseHeroReading(thinkAndFence);
      expect(parsed1, isNotNull);
      expect(parsed1!.title, '天府坐命 · 厚积薄发型');

      // Reproduces reasoning leak seen in raw DeepSeek probe before final JSON.
      const leakedReasoning = '''
{"ok": We need to output strictly JSON with {"title":"..."}.
Thinking complete, final output:
{"title":"廉贪同度 · 锐意破局型","subtitle":"行动力强且重人际链接","tags":["果敢","敏锐","重情"],"overview":"命宫星曜活跃，三方见吉星辅佐。","yearlyTheme":"丙午年宜主动拓展合作。"}
''';
      final parsed2 = ZiweiLlmResponseParser.parseHeroReading(leakedReasoning);
      expect(parsed2, isNotNull);
      expect(parsed2!.title, '廉贪同度 · 锐意破局型');
      expect(parsed2.tags, ['果敢', '敏锐', '重情']);

      expect(ZiweiLlmResponseParser.parseHeroReading('not json'), isNull);
    });
  });
}
