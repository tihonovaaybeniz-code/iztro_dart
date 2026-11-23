/// Pure Dart Ziwei Doushu (Purple Star Astrology) calculation engine
/// ported from `SylarLong/iztro` (`v2.6.5`).
library;

export 'src/astro/astro.dart';
export 'src/astro/functional_astrolabe.dart';
export 'src/astro/functional_palace.dart';
export 'src/astro/palace_calc.dart';
export 'src/calendar/calendar_adapter.dart';
export 'src/calendar/day_boundary.dart';
export 'src/calendar/default_lunar_adapter.dart';
export 'src/calendar/true_solar_time.dart';
export 'src/core/config.dart';
export 'src/core/index_math.dart';
export 'src/core/types.dart';
export 'src/core/validation.dart';
export 'src/data/branches_table.dart';
export 'src/data/brightness_table.dart';
export 'src/data/locales/locale_registry.dart';
export 'src/data/stars_meta.dart';
export 'src/data/stems_table.dart';
export 'src/star/functional_star.dart';

/// Package semantic version baseline.
const String iztroDartVersion = '0.1.0';
