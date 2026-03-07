// ── Sky Phase Engine ──
// Drives dynamic time-of-day backgrounds using real sunrise/sunset from Open-Meteo.
// Four phases: night, sunrise, day, sunset — with 80-minute transition windows.

import { getSeason } from './date.js';

// ── Seasonal Fallback Sunrise/Sunset (minutes since midnight, NYC) ──
const SEASONAL_DEFAULTS = {
  Spring: { sunrise: 390, sunset: 1140 }, // ~6:30am, ~7:00pm
  Summer: { sunrise: 330, sunset: 1230 }, // ~5:30am, ~8:30pm
  Fall:   { sunrise: 420, sunset: 1080 }, // ~7:00am, ~6:00pm
  Winter: { sunrise: 430, sunset: 1010 }, // ~7:10am, ~4:50pm
};

export function getSeasonalFallback() {
  return SEASONAL_DEFAULTS[getSeason()] || SEASONAL_DEFAULTS.Winter;
}

// ── Phase Computation ──
// Returns { phase, blend, nextPhase }
// blend is 0-1 within the 80-minute transition window
export function computeSkyPhase(sunriseMin, sunsetMin) {
  const now = new Date();
  const currentMin = now.getHours() * 60 + now.getMinutes();
  const T = 40; // half-window in minutes

  const sunriseStart = sunriseMin - T;
  const sunriseEnd   = sunriseMin + T;
  const sunsetStart  = sunsetMin - T;
  const sunsetEnd    = sunsetMin + T;

  if (currentMin >= sunriseStart && currentMin < sunriseEnd) {
    const blend = (currentMin - sunriseStart) / (sunriseEnd - sunriseStart);
    return { phase: "sunrise", blend, nextPhase: "day" };
  }
  if (currentMin >= sunriseEnd && currentMin < sunsetStart) {
    return { phase: "day", blend: 0, nextPhase: "sunset" };
  }
  if (currentMin >= sunsetStart && currentMin < sunsetEnd) {
    const blend = (currentMin - sunsetStart) / (sunsetEnd - sunsetStart);
    return { phase: "sunset", blend, nextPhase: "night" };
  }
  // Night: after sunset+T or before sunrise-T
  return { phase: "night", blend: 0, nextPhase: "sunrise" };
}

// ── Phase-specific color palettes ──
const PALETTES = {
  night: {
    skyTop:     "rgba(12,12,24,0)",       // transparent — base bg shows through
    skyMid:     "rgba(12,12,24,0)",
    skyHorizon: "rgba(12,12,24,0)",
    starOpacity: 0.7,
    shootingStarOpacity: 1,
    windowOpacity: 1,
    glowColor1: null, // use seasonal default
    glowColor2: null,
  },
  sunrise: {
    skyTop:     "rgba(20,30,56,0.9)",      // deep navy
    skyMid:     "rgba(60,50,80,0.7)",      // purple-grey
    skyHorizon: "rgba(210,130,90,0.5)",    // warm rose-gold
    starOpacity: 0,
    shootingStarOpacity: 0,
    windowOpacity: 0.15,
    glowColor1: "rgba(220,140,100,0.35)",  // rose-gold
    glowColor2: "rgba(232,195,106,0.25)",  // gold
  },
  day: {
    skyTop:     "rgba(20,30,56,0.85)",     // deep blue-navy
    skyMid:     "rgba(42,63,107,0.65)",    // muted blue
    skyHorizon: "rgba(120,140,170,0.3)",   // soft haze
    starOpacity: 0,
    shootingStarOpacity: 0,
    windowOpacity: 0,
    glowColor1: "rgba(106,175,232,0.12)",  // subtle blue
    glowColor2: "rgba(140,170,210,0.08)",  // pale blue
  },
  sunset: {
    skyTop:     "rgba(30,25,60,0.9)",      // deep indigo
    skyMid:     "rgba(80,50,70,0.7)",      // warm purple
    skyHorizon: "rgba(200,120,60,0.55)",   // amber-orange
    starOpacity: 0.3,
    shootingStarOpacity: 0.5,
    windowOpacity: 0.6,
    glowColor1: "rgba(200,120,60,0.4)",    // amber
    glowColor2: "rgba(232,160,80,0.3)",    // warm gold
  },
};

// Lerp between two RGBA strings
function lerpRgba(a, b, t) {
  if (!a || !b) return b || a || "transparent";
  const parse = (s) => {
    const m = s.match(/[\d.]+/g);
    return m ? m.map(Number) : [0, 0, 0, 0];
  };
  const ca = parse(a), cb = parse(b);
  const r = ca[0] + (cb[0] - ca[0]) * t;
  const g = ca[1] + (cb[1] - ca[1]) * t;
  const bl = ca[2] + (cb[2] - ca[2]) * t;
  const al = (ca[3] ?? 0) + ((cb[3] ?? 0) - (ca[3] ?? 0)) * t;
  return `rgba(${Math.round(r)},${Math.round(g)},${Math.round(bl)},${al.toFixed(3)})`;
}

function lerpNum(a, b, t) {
  return a + (b - a) * t;
}

// ── Apply Sky Phase to DOM ──
// Sets CSS custom properties and data attribute for phase-aware styling.
export function applySkyPhase(sunriseMin, sunsetMin) {
  const info = computeSkyPhase(sunriseMin, sunsetMin);
  const root = document.documentElement;
  const stage = document.querySelector(".skyline-stage");

  const palette = PALETTES[info.phase];
  let colors = { ...palette };

  // Blend with next phase during transitions
  if (info.blend > 0 && PALETTES[info.nextPhase]) {
    const next = PALETTES[info.nextPhase];
    colors.skyTop     = lerpRgba(palette.skyTop, next.skyTop, info.blend);
    colors.skyMid     = lerpRgba(palette.skyMid, next.skyMid, info.blend);
    colors.skyHorizon = lerpRgba(palette.skyHorizon, next.skyHorizon, info.blend);
    colors.starOpacity = lerpNum(palette.starOpacity, next.starOpacity, info.blend);
    colors.shootingStarOpacity = lerpNum(palette.shootingStarOpacity, next.shootingStarOpacity, info.blend);
    colors.windowOpacity = lerpNum(palette.windowOpacity, next.windowOpacity, info.blend);
    if (palette.glowColor1 && next.glowColor1) {
      colors.glowColor1 = lerpRgba(palette.glowColor1, next.glowColor1, info.blend);
      colors.glowColor2 = lerpRgba(palette.glowColor2, next.glowColor2, info.blend);
    }
  }

  root.style.setProperty("--sky-top", colors.skyTop);
  root.style.setProperty("--sky-mid", colors.skyMid);
  root.style.setProperty("--sky-horizon", colors.skyHorizon);
  root.style.setProperty("--star-opacity", colors.starOpacity);
  root.style.setProperty("--shooting-star-opacity", colors.shootingStarOpacity);
  root.style.setProperty("--window-opacity", colors.windowOpacity);

  if (colors.glowColor1) {
    root.style.setProperty("--glow-color-1", colors.glowColor1);
    root.style.setProperty("--glow-color-2", colors.glowColor2);
  } else {
    root.style.removeProperty("--glow-color-1");
    root.style.removeProperty("--glow-color-2");
  }

  if (stage) stage.dataset.skyPhase = info.phase;

  return info;
}
