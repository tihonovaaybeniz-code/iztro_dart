import 'package:iztro_dart/iztro_dart.dart';
import 'package:test/test.dart';

void main() {
  setUp(Astro.resetConfig);
  tearDown(Astro.resetConfig);

  group('ZiweiFollowupPromptBuilder (v0.3.0)', () {
    test('builds deterministic cacheKey and parses followup JSON answer', () {
      final chart = Astro.bySolar('1995-8-16', 5, Gender.female);
      final target = DateTime(2026, 6, 15);
      final prompt = chart.buildFollowupPrompt(
        ZiweiFollowupQuestion.careerMove,
        targetDate: target,
      );

      expect(prompt.scene, ZiweiPromptScene.followup);
      expect(prompt.cacheKey, contains(':followup:career_move:2026:v1:'));
      expect(prompt.userPrompt, contains('今年适合变动/跳槽吗？'));
      expect(prompt.userPrompt, contains('★焦点'));
      expect(
        ZiweiFollowupQuestion.tryFromId('career_move'),
        ZiweiFollowupQuestion.careerMove,
      );
      expect(ZiweiFollowupQuestion.tryFromId('unknown'), isNull);

      const raw = '''
```json
{
  "questionId": "career_move",
  "questionTitle": "今年适合变动/跳槽吗？",
  "summary": "2026丙午年宜先稳内部节奏，下半年再择机评估外部机会。",
  "analysis": "官禄廉贞庙逢流年化忌，变动成本偏高，先夯实核心项目更稳妥。",
  "actionSteps": ["完善核心项目交付文档", "Q3前先做横向行业调研"],
  "caution": "避免因短期情绪波动做出仓促跳槽决定。"
}
```
''';
      final parsed = ZiweiLlmResponseParser.parseFollowupAnswer(
        raw,
        fallbackQuestionId: ZiweiFollowupQuestion.careerMove.id,
        fallbackQuestionTitle: ZiweiFollowupQuestion.careerMove.title,
      );
      expect(parsed, isNotNull);
      expect(parsed!.questionId, 'career_move');
      expect(parsed.actionSteps, hasLength(2));
    });
  });

  group('ZejiPromptBuilder (v0.3.0)', () {
    test('renders candidate DSL, builds prompt, and parses recommendation', () {
      const candidates = [
        ZejiCandidateDay(
          solarDate: '2026-05-16',
          lunarText: '三月三十',
          weekdayText: '周六',
          ganZhiDay: '甲辰',
          zhiShen: '玉堂',
          jianChu: '成',
          chongSha: '冲狗 煞南',
          almanacScore: 86,
          luckyHours: ['巳时(09:00-10:59)', '午时(11:00-12:59)'],
          clashesUser: false,
          ziweiFlowDayPalace: '夫妻',
          ziweiFlowDayMutagens: ['禄:天同'],
        ),
        ZejiCandidateDay(
          solarDate: '2026-05-20',
          lunarText: '四月初四',
          weekdayText: '周三',
          ganZhiDay: '戊申',
          zhiShen: '司命',
          jianChu: '满',
          chongSha: '冲虎 煞南',
          almanacScore: 79,
          luckyHours: ['辰时(07:00-08:59)'],
          clashesUser: true,
        ),
      ];

      final prompt = ZejiPromptBuilder.buildRecommendPrompt(
        eventWord: '嫁娶',
        userAnimal: '猪',
        partnerAnimal: '兔',
        candidates: candidates,
      );

      expect(prompt.scene, ZiweiPromptScene.zeji);
      expect(prompt.systemPrompt, contains('严禁自行推算历法'));
      expect(prompt.userPrompt, contains('2026-05-16'));
      expect(prompt.userPrompt, contains('本人生肖:猪 | 伴侣/同行生肖:兔'));
      expect(prompt.cacheKey, endsWith(':zeji:v1'));

      const rawResp = '''
{
  "eventWord": "嫁娶",
  "headline": "首选 2026-05-16 周六玉堂成日，避开冲属虎日",
  "bestDate": "2026-05-16",
  "bestDateSummary": "该日玉堂值神配成日，且不冲双方生肖，适合周末安排礼仪流程。",
  "topPicks": [
    {
      "date": "2026-05-16",
      "reason": "黄历评分86且为玉堂成日，紫微流日照入夫妻位带天同禄。",
      "bestHours": "建议优先选择巳时(09:00-10:59)或午时(11:00-12:59)。",
      "caution": "注意当日煞方位在南，迎亲动线可稍微错峰避让。"
    }
  ],
  "preparationTips": ["提前一周确认司仪与物料清单", "预留天气雨天备选场地"]
}
''';
      final parsed = ZiweiLlmResponseParser.parseZejiRecommendation(
        rawResp,
        fallbackEventWord: '嫁娶',
      );
      expect(parsed, isNotNull);
      expect(parsed!.bestDate, '2026-05-16');
      expect(parsed.topPicks, hasLength(1));
      expect(parsed.preparationTips, hasLength(2));
    });
  });
}
