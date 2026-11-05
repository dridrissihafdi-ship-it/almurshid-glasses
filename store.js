/* small helpers around localStorage, which can be missing or throw */
export function load(key, fallback) {
  try {
    const v = localStorage.getItem(key);
    return v == null ? fallback : JSON.parse(v);
  } catch (e) {
    return fallback;
  }
}

export function store(key, value) {
  try { localStorage.setItem(key, JSON.stringify(value)); } catch (e) { /* storage unavailable */ }
}

export function today() {
  const d = new Date();
  return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
}

/* Fez, used until the glasses report a position */
const DEFAULT_LOC = { lat: 34.0331, lng: -5.0003, name: 'فاس', guess: true };

export function savedLoc() {
  return load('murshid-loc', DEFAULT_LOC);
}

/* ask for the position once; keep the last good one for next time */
export function refreshLoc(done) {
  try {
    if (!navigator.geolocation) { done(savedLoc()); return; }
    navigator.geolocation.getCurrentPosition(
      (p) => {
        const loc = { lat: p.coords.latitude, lng: p.coords.longitude, at: Date.now() };
        store('murshid-loc', loc);
        done(loc);
      },
      () => done(savedLoc()),
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 6 * 3600 * 1000 },
    );
  } catch (e) {
    done(savedLoc());
  }
}
