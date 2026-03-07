// Borough bounding boxes (approximate lat/lng rectangles)
const BOROUGH_BOUNDS = {
  Manhattan: { latMin: 40.700, latMax: 40.882, lngMin: -74.020, lngMax: -73.907 },
  Brooklyn: { latMin: 40.570, latMax: 40.739, lngMin: -74.042, lngMax: -73.855 },
  Queens: { latMin: 40.541, latMax: 40.812, lngMin: -73.962, lngMax: -73.700 },
  Bronx: { latMin: 40.785, latMax: 40.917, lngMin: -73.933, lngMax: -73.765 },
  "Across the River": { latMin: 40.660, latMax: 40.760, lngMin: -74.100, lngMax: -74.020 },
};

export function detectBorough(lat, lng) {
  for (const [borough, b] of Object.entries(BOROUGH_BOUNDS)) {
    if (lat >= b.latMin && lat <= b.latMax && lng >= b.lngMin && lng <= b.lngMax) {
      return borough;
    }
  }
  return null;
}

const GEO_KEY = "datedice:geo";
const GEO_TTL = 30 * 60 * 1000; // 30 minutes

export function getCachedLocation() {
  try {
    const raw = localStorage.getItem(GEO_KEY);
    if (!raw) return null;
    const data = JSON.parse(raw);
    if (Date.now() - data.ts > GEO_TTL) {
      localStorage.removeItem(GEO_KEY);
      return null;
    }
    return data;
  } catch { return null; }
}

function cacheLocation(lat, lng, borough) {
  try {
    localStorage.setItem(GEO_KEY, JSON.stringify({ lat, lng, borough, ts: Date.now() }));
  } catch { /* quota exceeded — fine, just skip caching */ }
}

export function requestLocation() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error("Geolocation not supported"));
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        // Truncate to 3 decimals (~100m precision) for privacy
        const lat = Math.round(pos.coords.latitude * 1000) / 1000;
        const lng = Math.round(pos.coords.longitude * 1000) / 1000;
        const borough = detectBorough(lat, lng);
        cacheLocation(lat, lng, borough);
        resolve({ lat, lng, borough });
      },
      (err) => reject(err),
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 300000 }
    );
  });
}
