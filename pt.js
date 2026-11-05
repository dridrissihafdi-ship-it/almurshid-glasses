/* Prayer times — the same calculation as the Al-Murshid app:
   Fajr and Isha angles per method, Asr with shadow equal to height (Maliki / Shafi'i),
   and the Moroccan Ministry of Habous adjustments when in Morocco. */
const rad = (d) => (d * Math.PI) / 180;
const deg = (r) => (r * 180) / Math.PI;
const fix = (a, b) => { a = a - b * Math.floor(a / b); return a < 0 ? a + b : a; };

function sunPos(jd) {
  const D = jd - 2451545;
  const g = fix(357.529 + 0.98560028 * D, 360);
  const q = fix(280.459 + 0.98564736 * D, 360);
  const L = fix(q + 1.915 * Math.sin(rad(g)) + 0.02 * Math.sin(rad(2 * g)), 360);
  const e = 23.439 - 0.00000036 * D;
  const RA = fix(deg(Math.atan2(Math.cos(rad(e)) * Math.sin(rad(L)), Math.cos(rad(L)))) / 15, 24);
  const decl = deg(Math.asin(Math.sin(rad(e)) * Math.sin(rad(L))));
  return { decl, eqt: q / 15 - RA };
}

/* [Fajr angle, Isha angle — or minutes after Maghrib as a string] */
const METHODS = {
  ma: [19, 17], mwl: [18, 17], uqura: [18.5, '90'], egypt: [19.5, 17.5], isna: [15, 15],
};

export function inMorocco(lat, lng) { return lat >= 20.5 && lat <= 36.2 && lng >= -17.6 && lng <= -0.9; }

export function methodFor(lat, lng) {
  if (inMorocco(lat, lng)) return 'ma';
  if (lat > 22 && lat < 31.7 && lng > 24.7 && lng < 35) return 'egypt';
  if (lat > 16 && lat < 32.5 && lng >= 35 && lng < 55.7) return 'uqura';
  if (lng < -50 && lng > -170 && lat > 15) return 'isna';
  return 'mwl';
}

/* returns hours (0–24, local time) for fajr, sunrise, dhuhr, asr, maghrib, isha */
export function prayerTimes(date, lat, lng) {
  let y = date.getFullYear(), m = date.getMonth() + 1; const d = date.getDate();
  if (m <= 2) { y--; m += 12; }
  const A = Math.floor(y / 100), B = 2 - A + Math.floor(A / 4);
  const jd = Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + d + B - 1524.5 - lng / (15 * 24);
  const tz = -date.getTimezoneOffset() / 60;
  const noon = (t) => fix(12 - sunPos(jd + t).eqt, 24);
  const at = (angle, t, ccw) => {
    const s = sunPos(jd + t), n = noon(t);
    const T = deg(Math.acos((-Math.sin(rad(angle)) - Math.sin(rad(s.decl)) * Math.sin(rad(lat))) / (Math.cos(rad(s.decl)) * Math.cos(rad(lat))))) / 15;
    return n + (ccw ? -T : T);
  };
  const asrAngle = (t) => { const s = sunPos(jd + t); return -deg(Math.atan(1 / (1 + Math.tan(rad(Math.abs(lat - s.decl)))))); };
  const meth = methodFor(lat, lng), PM = METHODS[meth];
  const raw = { fajr: at(PM[0], 5 / 24, 1), sunrise: at(0.833, 6 / 24, 1), dhuhr: noon(12 / 24), asr: at(asrAngle(13 / 24), 13 / 24, 0), maghrib: at(0.833, 18 / 24, 0), isha: 0 };
  raw.isha = typeof PM[1] === 'string' ? raw.maghrib + Number(PM[1]) / 60 : at(PM[1], 18 / 24, 0);
  const night = 24 - (raw.maghrib - raw.sunrise);
  if (!isFinite(raw.fajr)) raw.fajr = raw.sunrise - night / 7;
  if (!isFinite(raw.isha)) raw.isha = raw.maghrib + night / 7;
  const out = {};
  for (const k in raw) out[k] = fix(raw[k] + tz - lng / 15, 24);
  if (meth === 'ma') { out.dhuhr += 5 / 60; out.maghrib += 5 / 60; out.asr += 0.5 / 60; }
  return out;
}

export const NAMES = { fajr: 'الصبح', sunrise: 'الشروق', dhuhr: 'الظهر', asr: 'العصر', maghrib: 'المغرب', isha: 'العشاء' };
export const FIVE = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

export function hm(h) {
  const t = Math.round(h * 60) % 1440;
  const H = Math.floor(t / 60), M = t % 60;
  return String(H).padStart(2, '0') + ':' + String(M).padStart(2, '0');
}

/* the next of the five prayers, with minutes left */
export function nextPrayer(now, lat, lng) {
  const pt = prayerTimes(now, lat, lng);
  const h = now.getHours() + now.getMinutes() / 60 + now.getSeconds() / 3600;
  for (const k of FIVE) if (pt[k] > h) return { k, name: NAMES[k], at: hm(pt[k]), left: Math.round((pt[k] - h) * 60), pt };
  const tomorrow = new Date(now.getTime() + 864e5);
  const p2 = prayerTimes(tomorrow, lat, lng);
  return { k: 'fajr', name: NAMES.fajr, at: hm(p2.fajr), left: Math.round((24 - h + p2.fajr) * 60), pt };
}

export function leftText(min) {
  if (min < 60) return 'بعد ' + min + ' د';
  return 'بعد ' + Math.floor(min / 60) + ':' + String(min % 60).padStart(2, '0');
}

/* which adhkar fit the hour: morning from Fajr until Dhuhr, evening from Asr until Isha */
export function adhkarNow(now, lat, lng) {
  const pt = prayerTimes(now, lat, lng), h = now.getHours() + now.getMinutes() / 60;
  if (h >= pt.fajr && h < pt.dhuhr) return 'sabah';
  if (h >= pt.asr && h < pt.isha + 1) return 'masa';
  return null;
}
