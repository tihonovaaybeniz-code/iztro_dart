import 'dart:convert';

/// Structured hero overview reading matching host UI `ZiweiHeroReading` cards.
class ZiweiHeroReadingPayload {
  const ZiweiHeroReadingPayload({
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.overview,
    required this.yearlyTheme,
  });

  /// Archetype headline, e.g. `紫府同宫 · 稳重掌局型`.
  final String title;

  /// One-line positioning summary.
  final String subtitle;

  /// 3 concise personality/pattern tags.
  final List<String> tags;

  /// Plain-language overall natal chart interpretation.
  final String overview;

  /// Active flow-year theme summary.
  final String yearlyTheme;

  factory ZiweiHeroReadingPayload.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .take(5)
            .toList(growable: false)
        : const <String>[];

    return ZiweiHeroReadingPayload(
      title: (json['title'] ?? '').toString().trim(),
      subtitle: (json['subtitle'] ?? '').toString().trim(),
      tags: tags,
      overview: (json['overview'] ?? '').toString().trim(),
      yearlyTheme: (json['yearlyTheme'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'subtitle': subtitle,
        'tags': tags,
        'overview': overview,
        'yearlyTheme': yearlyTheme,
      };
}

/// Structured single-palace reading matching host UI `ZiweiPalaceReading` cards.
class ZiweiPalaceReadingPayload {
  const ZiweiPalaceReadingPayload({
    required this.palaceName,
    required this.corePattern,
    required this.flowYearFocus,
    required this.modifierAnalysis,
    required this.actionAdvice,
  });

  final String palaceName;
  final String corePattern;
  final String flowYearFocus;
  final String modifierAnalysis;
  final String actionAdvice;

  factory ZiweiPalaceReadingPayload.fromJson(
    Map<String, dynamic> json, {
    String fallbackPalaceName = '',
  }) {
    final rawName = (json['palaceName'] ?? '').toString().trim();
    return ZiweiPalaceReadingPayload(
      palaceName: rawName.isEmpty ? fallbackPalaceName : rawName,
      corePattern: (json['corePattern'] ?? '').toString().trim(),
      flowYearFocus: (json['flowYearFocus'] ?? '').toString().trim(),
      modifierAnalysis: (json['modifierAnalysis'] ?? '').toString().trim(),
      actionAdvice: (json['actionAdvice'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'palaceName': palaceName,
        'corePattern': corePattern,
        'flowYearFocus': flowYearFocus,
        'modifierAnalysis': modifierAnalysis,
        'actionAdvice': actionAdvice,
      };
}

/// Structured yearly fortune reading payload.
class ZiweiYearlyReadingPayload {
  const ZiweiYearlyReadingPayload({
    required this.year,
    required this.yearGanZhi,
    required this.headline,
    required this.opportunities,
    required this.risks,
    required this.keyMonths,
    required this.actionChecklist,
  });

  final int year;
  final String yearGanZhi;
  final String headline;
  final String opportunities;
  final String risks;
  final List<String> keyMonths;
  final List<String> actionChecklist;

  factory ZiweiYearlyReadingPayload.fromJson(
    Map<String, dynamic> json, {
    required int fallbackYear,
    required String fallbackYearGanZhi,
  }) {
    final rawMonths = json['keyMonths'];
    final keyMonths = rawMonths is List
        ? rawMonths
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    final rawChecklist = json['actionChecklist'];
    final checklist = rawChecklist is List
        ? rawChecklist
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    final parsedYear = json['year'] is num
        ? (json['year'] as num).toInt()
        : int.tryParse((json['year'] ?? '').toString()) ?? fallbackYear;
    final parsedGanZhi = (json['yearGanZhi'] ?? '').toString().trim();

    return ZiweiYearlyReadingPayload(
      year: parsedYear,
      yearGanZhi: parsedGanZhi.isEmpty ? fallbackYearGanZhi : parsedGanZhi,
      headline: (json['headline'] ?? '').toString().trim(),
      opportunities: (json['opportunities'] ?? '').toString().trim(),
      risks: (json['risks'] ?? '').toString().trim(),
      keyMonths: keyMonths,
      actionChecklist: checklist,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'year': year,
        'yearGanZhi': yearGanZhi,
        'headline': headline,
        'opportunities': opportunities,
        'risks': risks,
        'keyMonths': keyMonths,
        'actionChecklist': actionChecklist,
      };
}

/// Fault-tolerant parser extracting strict JSON payloads from LLM responses
/// (handling `<think>` tags, markdown fences, and leaked reasoning prose).
abstract final class ZiweiLlmResponseParser {
  static final RegExp _thinkBlockPattern = RegExp(
    r'<think>[\s\S]*?</think>',
    caseSensitive: false,
  );
  static final RegExp _fencePattern = RegExp(
    r'```(?:json)?\s*([\s\S]*?)```',
    caseSensitive: false,
  );

  /// Extracts a JSON object `Map<String, dynamic>` from raw LLM output [raw].
  ///
  /// Prefers the **last** valid JSON object containing all [requiredKeys],
  /// making it resilient when reasoning models leak draft JSON fragments before
  /// the final answer.
  static Map<String, dynamic>? extractJsonObject(
    String raw, {
    List<String> requiredKeys = const [],
  }) {
    final cleaned = raw.replaceAll(_thinkBlockPattern, '').trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final direct = _tryDecodeMap(cleaned);
    if (direct != null && _hasKeys(direct, requiredKeys)) {
      return direct;
    }

    final candidates = <Map<String, dynamic>>[];

    for (final match in _fencePattern.allMatches(cleaned)) {
      final inner = match.group(1)?.trim();
      if (inner != null && inner.isNotEmpty) {
        final decoded = _tryDecodeMap(inner);
        if (decoded != null) {
          candidates.add(decoded);
        }
      }
    }

    for (final slice in _extractBalancedBraceSlices(cleaned)) {
      final decoded = _tryDecodeMap(slice);
      if (decoded != null) {
        candidates.add(decoded);
      }
    }

    if (candidates.isEmpty) {
      return direct;
    }

    for (var i = candidates.length - 1; i >= 0; i--) {
      if (_hasKeys(candidates[i], requiredKeys)) {
        return candidates[i];
      }
    }
    return candidates.last;
  }

  /// Parses raw LLM text into a [ZiweiHeroReadingPayload], or `null` if invalid
  /// or missing essential text fields (`title` & `overview`).
  static ZiweiHeroReadingPayload? parseHeroReading(String raw) {
    final map = extractJsonObject(
      raw,
      requiredKeys: const ['title', 'subtitle', 'tags', 'overview'],
    );
    if (map == null) {
      return null;
    }
    final payload = ZiweiHeroReadingPayload.fromJson(map);
    if (payload.title.isEmpty || payload.overview.isEmpty) {
      return null;
    }
    return payload;
  }

  /// Parses raw LLM text into a [ZiweiPalaceReadingPayload], or `null` if
  /// missing core reading sections.
  static ZiweiPalaceReadingPayload? parsePalaceReading(
    String raw, {
    String fallbackPalaceName = '',
  }) {
    final map = extractJsonObject(
      raw,
      requiredKeys: const [
        'corePattern',
        'flowYearFocus',
        'modifierAnalysis',
        'actionAdvice',
      ],
    );
    if (map == null) {
      return null;
    }
    final payload = ZiweiPalaceReadingPayload.fromJson(
      map,
      fallbackPalaceName: fallbackPalaceName,
    );
    if (payload.corePattern.isEmpty && payload.actionAdvice.isEmpty) {
      return null;
    }
    return payload;
  }

  /// Parses raw LLM text into a [ZiweiYearlyReadingPayload], or `null` if
  /// invalid.
  static ZiweiYearlyReadingPayload? parseYearlyReading(
    String raw, {
    required int year,
    required String yearGanZhi,
  }) {
    final map = extractJsonObject(
      raw,
      requiredKeys: const ['headline', 'opportunities', 'risks'],
    );
    if (map == null) {
      return null;
    }
    final payload = ZiweiYearlyReadingPayload.fromJson(
      map,
      fallbackYear: year,
      fallbackYearGanZhi: yearGanZhi,
    );
    if (payload.headline.isEmpty || payload.opportunities.isEmpty) {
      return null;
    }
    return payload;
  }

  static Map<String, dynamic>? _tryDecodeMap(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static bool _hasKeys(Map<String, dynamic> map, List<String> requiredKeys) {
    for (final key in requiredKeys) {
      if (!map.containsKey(key)) {
        return false;
      }
    }
    return true;
  }

  static List<String> _extractBalancedBraceSlices(String text) {
    final slices = <String>[];
    final starts = <int>[];
    var inString = false;
    var escaped = false;

    for (var i = 0; i < text.length; i++) {
      final ch = text.codeUnitAt(i);
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == 0x5C /* \ */) {
          escaped = true;
        } else if (ch == 0x22 /* " */) {
          inString = false;
        }
        continue;
      }

      if (ch == 0x22 /* " */) {
        inString = true;
      } else if (ch == 0x7B /* { */) {
        starts.add(i);
      } else if (ch == 0x7D /* } */ && starts.isNotEmpty) {
        final start = starts.removeLast();
        slices.add(text.substring(start, i + 1));
      }
    }
    return slices;
  }
}
