# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-11-23

### Added
- `ChartCompactDsl.render(...)` and `FunctionalAstrolabe.toCompactDsl(...)` for token-efficient plain-text LLM chart serialization.
- Fixed anti-hallucination prompt builder (`ZiweiPromptBuilder`, `ZiweiLlmPrompt`, `ZiweiPromptScene`, `ZiweiDslFormat`) with convenience methods `buildHeroPrompt`, `buildPalacePrompt`, and `buildYearlyPrompt` on `FunctionalAstrolabe`.
- Structured reading payload models (`ZiweiHeroReadingPayload`, `ZiweiPalaceReadingPayload`, `ZiweiYearlyReadingPayload`) and fault-tolerant `ZiweiLlmResponseParser` handling `<think>` tags, markdown fences, and leaked reasoning prose.

## [0.1.0] - 2026-11-23

### Added
- Pure Dart Ziwei Doushu calculation engine ported from `SylarLong/iztro` (`v2.6.5`), with zero Flutter or `dart:io` dependencies in `lib/`.
- Pluggable calendar abstraction (`LunarCalendarAdapter` and `BaseLunarCalendarAdapter`) with `DefaultLunarAdapter` backed by `lunar`.
- True Solar Time calculator (`TrueSolarTimeCalculator`) and `Astro.byTrueSolarTime` supporting longitude offset, Equation of Time, China 1986–1991 historical DST, and configurable time-boundary warnings.
- Full `Astro` APIs (`bySolar`, `byLunar`, `byTrueSolarTime`, `withOptions`, `config`, `getConfig`, `resetConfig`, `setLanguage`, `getLanguage`, and date/major-star helpers), immutable per-chart config isolation, `default` & `zhongzhou` algorithms, `heaven` / `earth` / `human` rearrangement, and all 6 locales (`zh-CN`, `zh-TW`, `en-US`, `ja-JP`, `ko-KR`, `vi-VN`).
- Six-layer horoscope engine (`horoscope`, `decadalList`, `yearlyList`, `monthlyList`), chainable queries (`surroundedPalaces`, `flankingPalaces`, `fliesTo`, `selfMutaged`, `selfMutagedIn`, `palaceAtBranch`), and `FunctionalHoroscope` queries.
- LLM Chart DSL (`toLlmJson`) with deterministic 64-bit FNV-1a chart fingerprints and rule-based `PatternDetector`.
- Automated 870-case golden parity test suite verified against official `iztro@2.6.5`.
