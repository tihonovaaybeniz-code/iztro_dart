import 'types.dart';

/// Wraps [index] into `[0, max)`.
///
/// Matches `iztro`'s `fixIndex(index, max = 12)`.
int fixIndex(int index, [int max = 12]) {
  if (max <= 0) {
    throw ArgumentError.value(max, 'max', 'Must be positive.');
  }
  final mod = index % max;
  return mod < 0 ? mod + max : mod;
}

/// Converts an [EarthlyBranch] to its 0-based palace index (`0 = 寅 .. 11 = 丑`).
int earthlyBranchToPalaceIndex(EarthlyBranch branch) {
  return fixIndex(branch.index - EarthlyBranch.yin.index);
}

/// Converts a 0-based palace index (`0 = 寅 .. 11 = 丑`) to its [EarthlyBranch].
EarthlyBranch palaceIndexToEarthlyBranch(int palaceIndex) {
  return EarthlyBranch.values[fixIndex(EarthlyBranch.yin.index + palaceIndex)];
}

/// Converts a wall-clock hour (`0..23`) into a Chinese time index (`0..12`).
///
/// - `0` -> `0` (早子时 00:00–00:59)
/// - `23` -> `12` (晚子时 23:00–23:59)
/// - `1..22` -> `(hour + 1) ~/ 2`
int timeToIndex(int hour) {
  if (hour < 0 || hour > 23) {
    throw RangeError.range(hour, 0, 23, 'hour');
  }
  if (hour == 0) {
    return 0;
  }
  if (hour == 23) {
    return 12;
  }
  return (hour + 1) ~/ 2;
}
