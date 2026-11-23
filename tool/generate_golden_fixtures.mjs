import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { astro } from 'iztro';
import { Lunar, LunarYear, Solar } from 'lunar-typescript';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.resolve(__dirname, '../test/fixtures');
fs.mkdirSync(outDir, { recursive: true });

// Deterministic seeded PRNG (Mulberry32).
function createRng(seed) {
  let a = seed >>> 0;
  return function next() {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const rng = createRng(20260501);
const randInt = (min, max) => Math.floor(rng() * (max - min + 1)) + min;
const pick = (arr) => arr[randInt(0, arr.length - 1)];

const LOCALES = ['zh-CN', 'zh-TW', 'en-US', 'ja-JP', 'ko-KR', 'vi-VN'];

function randomSolarDate(minYear = 1920, maxYear = 2050) {
  const year = randInt(minYear, maxYear);
  const month = randInt(1, 12);
  const isLeap = (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
  const maxDay = [31, isLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
  const day = randInt(1, maxDay);
  return `${year}-${month}-${day}`;
}

function buildCaseRecord(input, includeHoroscope = null) {
  astro.resetConfig();
  const options = {
    type: input.type ?? 'solar',
    dateStr: input.dateStr,
    timeIndex: input.timeIndex,
    gender: input.gender === 'male' ? '男' : '女',
    isLeapMonth: input.isLeapMonth ?? false,
    fixLeap: input.fixLeap ?? true,
    language: input.language ?? 'zh-CN',
    astroType: input.astroType ?? 'heaven',
    config: input.config ?? {},
  };

  const chart = astro.withOptions(options);
  const record = {
    input,
    expected: chart.toJSON(),
  };

  if (includeHoroscope) {
    const h = chart.horoscope(includeHoroscope.targetDate, includeHoroscope.targetTimeIndex);
    record.horoscopeQuery = includeHoroscope;
    record.expectedHoroscope = h.toJSON();
    record.expectedDecadalList = chart.decadalList().map((d) => ({
      ...d,
      stars: d.stars ? d.stars.map((list) => list.map((s) => s.toJSON())) : undefined,
    }));
    record.expectedYearlyList = chart.yearlyList(includeHoroscope.yearlyDecadalIndex).map((y) => ({
      ...y,
      stars: y.stars ? y.stars.map((list) => list.map((s) => s.toJSON())) : undefined,
    }));
    record.expectedMonthlyList = chart
      .monthlyList(includeHoroscope.monthlyYear, includeHoroscope.monthlyFixLeap)
      .map((m) => ({
        ...m,
        stars: m.stars ? m.stars.map((list) => list.map((s) => s.toJSON())) : undefined,
      }));
    record.expectedFlanking0 = chart.flankingPalaces(0).toJSON();
  }

  return record;
}

// 1. Regular 400 cases (1920..2050 x 0..12 x male/female)
const regularCases = [];
for (let i = 0; i < 400; i++) {
  regularCases.push(
    buildCaseRecord({
      id: `reg_${i}`,
      type: 'solar',
      dateStr: randomSolarDate(1920, 2050),
      timeIndex: randInt(0, 12),
      gender: i % 2 === 0 ? 'male' : 'female',
      fixLeap: true,
    }),
  );
}
fs.writeFileSync(path.join(outDir, 'regular_400.json'), JSON.stringify(regularCases));

// 2. Leap month 100 cases (days 1, 15, 16, lastDay; fixLeap true/false; lunar & solar)
const leapMonths = [];
for (let y = 1950; y <= 2040; y++) {
  const ly = LunarYear.fromYear(y);
  const lm = ly.getLeapMonth();
  if (lm > 0) {
    const monthObj = ly.getMonth(-lm);
    leapMonths.push({ year: y, month: lm, dayCount: monthObj.getDayCount() });
  }
}

const leapCases = [];
for (let i = 0; i < 100; i++) {
  const lm = leapMonths[i % leapMonths.length];
  const dayChoices = [1, 15, 16, lm.dayCount];
  const day = dayChoices[i % dayChoices.length];
  const fixLeap = i % 2 === 0;
  const asSolar = i % 3 === 0;
  if (asSolar) {
    const s = Lunar.fromYmd(lm.year, -lm.month, day).getSolar();
    leapCases.push(
      buildCaseRecord({
        id: `leap_${i}`,
        type: 'solar',
        dateStr: `${s.getYear()}-${s.getMonth()}-${s.getDay()}`,
        timeIndex: randInt(0, 12),
        gender: i % 2 === 0 ? 'male' : 'female',
        fixLeap,
      }),
    );
  } else {
    leapCases.push(
      buildCaseRecord({
        id: `leap_${i}`,
        type: 'lunar',
        dateStr: `${lm.year}-${lm.month}-${day}`,
        timeIndex: randInt(0, 12),
        gender: i % 2 === 0 ? 'male' : 'female',
        isLeapMonth: true,
        fixLeap,
      }),
    );
  }
}
fs.writeFileSync(path.join(outDir, 'leap_100.json'), JSON.stringify(leapCases));

// 3. Boundary 100 cases: timeIndex 0/12, dayDivide, Lunar NY, Lichun yearDivide/horoscopeDivide
const boundaryCases = [];
for (let i = 0; i < 100; i++) {
  const mode = i % 4;
  if (mode === 0) {
    // Late Rat / Early Rat around leap Feb 28/29 or Dec 31
    const dates = ['2024-2-28', '2024-2-29', '2023-12-31', '2000-2-29', '1999-12-31'];
    boundaryCases.push(
      buildCaseRecord({
        id: `bnd_${i}`,
        type: 'solar',
        dateStr: dates[i % dates.length],
        timeIndex: i % 2 === 0 ? 12 : 0,
        gender: i % 3 === 0 ? 'male' : 'female',
        config: {
          dayDivide: i % 8 < 4 ? 'forward' : 'current',
        },
      }),
    );
  } else if (mode === 1) {
    // Lichun boundary (Feb 3, 4, 5) with combinations of yearDivide & horoscopeDivide
    const yr = 1980 + (i % 60);
    const febDay = [3, 4, 5][i % 3];
    boundaryCases.push(
      buildCaseRecord({
        id: `bnd_${i}`,
        type: 'solar',
        dateStr: `${yr}-2-${febDay}`,
        timeIndex: [0, 8, 9, 12][i % 4],
        gender: i % 2 === 0 ? 'male' : 'female',
        config: {
          yearDivide: i % 8 < 4 ? 'normal' : 'exact',
          horoscopeDivide: i % 16 < 8 ? 'normal' : 'exact',
          dayDivide: i % 3 === 0 ? 'current' : 'forward',
        },
      }),
    );
  } else if (mode === 2) {
    // Lunar New Year's Eve (腊月廿九/三十) & 正月初一
    const yr = 1975 + (i % 50);
    const sNewYear = Lunar.fromYmd(yr, 1, 1).getSolar();
    const sDate = i % 2 === 0 ? sNewYear : sNewYear.next(-1);
    boundaryCases.push(
      buildCaseRecord({
        id: `bnd_${i}`,
        type: 'solar',
        dateStr: `${sDate.getYear()}-${sDate.getMonth()}-${sDate.getDay()}`,
        timeIndex: i % 4 === 0 ? 12 : randInt(0, 11),
        gender: i % 2 === 0 ? 'male' : 'female',
        config: {
          yearDivide: i % 2 === 0 ? 'normal' : 'exact',
          horoscopeDivide: i % 3 === 0 ? 'exact' : 'normal',
          dayDivide: i % 2 === 0 ? 'forward' : 'current',
        },
      }),
    );
  } else {
    // Solar term monthly boundary (around 5th..8th of various months)
    const yr = 1985 + (i % 45);
    const mo = (i % 12) + 1;
    const da = 4 + (i % 5);
    boundaryCases.push(
      buildCaseRecord({
        id: `bnd_${i}`,
        type: 'solar',
        dateStr: `${yr}-${mo}-${da}`,
        timeIndex: randInt(0, 12),
        gender: i % 2 === 0 ? 'male' : 'female',
        config: {
          horoscopeDivide: 'exact',
          yearDivide: i % 2 === 0 ? 'exact' : 'normal',
        },
      }),
    );
  }
}
fs.writeFileSync(path.join(outDir, 'boundary_100.json'), JSON.stringify(boundaryCases));

// 4. Algorithm, AstroType, Custom Overrides, and All 6 Locales (120 cases)
const algoCases = [];
for (let i = 0; i < 120; i++) {
  const locale = LOCALES[i % LOCALES.length];
  const astroType = ['heaven', 'earth', 'human'][i % 3];
  const algorithm = i % 2 === 0 ? 'zhongzhou' : 'default';
  const customOverrides =
    i % 10 === 0
      ? {
          mutagens: {
            庚: ['太阳', '武曲', '天府', '天同'],
          },
          brightness: {
            紫微: ['庙', '庙', '庙', '旺', '旺', '得', '得', '利', '利', '平', '不', '陷'],
          },
        }
      : {};

  algoCases.push(
    buildCaseRecord({
      id: `algo_${i}`,
      type: 'solar',
      dateStr: randomSolarDate(1950, 2035),
      timeIndex: randInt(0, 12),
      gender: i % 2 === 0 ? 'male' : 'female',
      language: locale,
      astroType,
      config: {
        algorithm,
        ageDivide: i % 4 === 0 ? 'birthday' : 'normal',
        ...customOverrides,
      },
    }),
  );
}
fs.writeFileSync(
  path.join(outDir, 'algorithm_astrotype_locale_120.json'),
  JSON.stringify(algoCases),
);

// 5. Dynamic Horoscope + Lists + Flanking Palaces (150 cases)
const horoscopeCases = [];
for (let i = 0; i < 150; i++) {
  const birthDate = randomSolarDate(1955, 2022);
  const [by] = birthDate.split('-').map(Number);
  const ageOffset = i % 5 === 0 ? randInt(0, 5) : randInt(6, 75);
  const targetYear = Math.min(2050, by + ageOffset);

  let targetDate;
  const futureLeaps = leapMonths.filter((m) => m.year > by);
  if (i % 7 === 0 && futureLeaps.length > 0) {
    // Target date falling inside a leap month after birth year
    const lm = futureLeaps[i % futureLeaps.length];
    const d = i % 2 === 0 ? 10 : 20;
    const s = Lunar.fromYmd(lm.year, -lm.month, d).getSolar();
    targetDate = `${s.getYear()}-${s.getMonth()}-${s.getDay()}`;
  } else {
    targetDate = randomSolarDate(Math.max(by, 1955), Math.max(targetYear, by));
    const [ty, tm, td] = targetDate.split('-').map(Number);
    const [, bm, bd] = birthDate.split('-').map(Number);
    if (ty === by && (tm < bm || (tm === bm && td < bd))) {
      targetDate = birthDate;
    }
  }

  const targetHour = i % 6 === 0 ? 12 : randInt(0, 11);
  const locale = i % 15 === 0 ? LOCALES[i % LOCALES.length] : 'zh-CN';
  const monthlyYear = leapMonths[i % leapMonths.length].year;

  horoscopeCases.push(
    buildCaseRecord(
      {
        id: `horo_${i}`,
        type: 'solar',
        dateStr: birthDate,
        timeIndex: randInt(0, 12),
        gender: i % 2 === 0 ? 'male' : 'female',
        language: locale,
        astroType: i % 9 === 0 ? 'earth' : 'heaven',
        config: {
          algorithm: i % 4 === 0 ? 'zhongzhou' : 'default',
          ageDivide: i % 3 === 0 ? 'birthday' : 'normal',
          horoscopeDivide: i % 5 === 0 ? 'exact' : 'normal',
          dayDivide: i % 8 === 0 ? 'current' : 'forward',
        },
      },
      {
        targetDate,
        targetTimeIndex: targetHour,
        yearlyDecadalIndex: i % 12,
        monthlyYear,
        monthlyFixLeap: i % 2 === 0,
      },
    ),
  );
}
fs.writeFileSync(path.join(outDir, 'horoscope_150.json'), JSON.stringify(horoscopeCases));

console.log(
  `Generated fixtures: regular=${regularCases.length}, leap=${leapCases.length}, ` +
    `boundary=${boundaryCases.length}, algo=${algoCases.length}, horoscope=${horoscopeCases.length}, ` +
    `total=${regularCases.length + leapCases.length + boundaryCases.length + algoCases.length + horoscopeCases.length}`,
);
