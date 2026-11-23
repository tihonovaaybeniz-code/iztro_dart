# iztro_dart

Pure Dart Ziwei Doushu (紫微斗数) astrology calculation engine ported from [`SylarLong/iztro`](https://github.com/SylarLong/iztro) (`v2.6.5`), designed for all Dart & Flutter targets (Android, iOS, macOS, Windows, Linux, Web, and Dart VM) with zero Flutter or `dart:io` dependencies.

## Features (In Progress)

- **100% Pure Dart**: Zero Flutter SDK dependencies and zero `dart:io` imports inside `lib/`.
- **Pluggable Calendar Layer**: Ships with a pure Dart `DefaultLunarAdapter` (via `lunar`) and an abstract `LunarCalendarAdapter` interface for injecting custom calendar engines.
- **True Solar Time**: Longitude offset, Equation of Time (EoT), China 1986–1991 historical DST rules, and time-boundary warning detection.
- **Full `iztro@2.6.5` Parity**: Natal chart, `heaven` / `earth` / `human` astrolabe rearrangement, `default` & `zhongzhou` algorithms, 6-layer horoscopes, chainable queries, and 6 locales (`zh-CN`, `zh-TW`, `en-US`, `ja-JP`, `ko-KR`, `vi-VN`).
- **LLM Chart DSL**: Deterministic chart fingerprint hash, classical pattern detector, and compact `toLlmJson()` output.

## License & Attribution

MIT License — see [LICENSE](LICENSE) and [NOTICE](NOTICE).
Algorithm and terminology ported from [@SylarLong/iztro](https://github.com/SylarLong/iztro) (`v2.6.5`, MIT).
