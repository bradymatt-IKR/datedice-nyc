import { useState, useEffect, useRef, useCallback } from 'react';
import { P, sans, serif, NEIGHBORHOODS, CUISINES, ACTIVITY_TYPES, FILTERS_MAIN, BOROUGH_COLORS, LOADING_MESSAGES, LOADING_EMOJI, FILTER_PRESETS } from './data/constants.js';
import { formatDate, getTimeOfDay, getSeason } from './utils/date.js';
import { WMO, classifyWeather, weatherToFilter } from './utils/weather.js';
import { loadData, saveData } from './utils/storage.js';
import { fetchSuggestion, fetchSuggestionStream } from './utils/api.js';

import Btn from './components/Btn.jsx';
import Chip from './components/Chip.jsx';
import Dice3D from './components/Dice3D.jsx';
import SideNav from './components/SideNav.jsx';
import NavBar from './components/NavBar.jsx';
import WeatherBadge from './components/WeatherBadge.jsx';
import MiniCalendar from './components/MiniCalendar.jsx';
import ResultCard from './components/ResultCard.jsx';
import DiscoverScreen from './components/DiscoverScreen.jsx';
import Confetti from './components/Confetti.jsx';

// ── Time-of-day tint overlays ──
function getTimeTint() {
  const h = new Date().getHours();
  if (h >= 6 && h < 12) return "rgba(232,195,106,0.03)"; // morning warm
  if (h >= 12 && h < 17) return "rgba(106,175,232,0.02)"; // afternoon neutral-blue
  if (h >= 17 && h < 21) return "rgba(201,125,74,0.06)"; // evening amber
  return "rgba(106,130,232,0.05)"; // late night cool blue
}

export default function App() {
  const [screen, setScreen] = useState("home");
  const [tab, setTab] = useState("roll");
  const [subScreen, setSubScreen] = useState("filters");
  const [filters, setFilters] = useState({});
  const [rolling, setRolling] = useState(false);
  const [altsLoading, setAltsLoading] = useState(false);
  const [diceVals, setDiceVals] = useState([3, 5]);
  const [result, setResult] = useState(null);
  const [altResults, setAltResults] = useState([]);
  const [showAlts, setShowAlts] = useState(false);
  const [history, setHistory] = useState([]);
  const [weather, setWeather] = useState(null);
  const [weatherLoading, setWeatherLoading] = useState(true);
  const [locked, setLocked] = useState(false);
  const [toast, setToast] = useState(null);
  const [usedNames, setUsedNames] = useState([]);
  const [showNeighborhoods, setShowNeighborhoods] = useState(false);
  const [showCuisines, setShowCuisines] = useState(false);
  const [showActivityTypes, setShowActivityTypes] = useState(false);
  const [streamText, setStreamText] = useState("");
  const [showConfetti, setShowConfetti] = useState(false);
  const [loadingMsg, setLoadingMsg] = useState(LOADING_MESSAGES[0]);
  const [loadingEmoji, setLoadingEmoji] = useState("🎲");
  const [tabKey, setTabKey] = useState(0);
  const diceInterval = useRef(null);
  const rollCount = useRef(0);
  const filtersRef = useRef(filters);
  const usedNamesRef = useRef(usedNames);
  const loadingInterval = useRef(null);

  useEffect(() => { filtersRef.current = filters; }, [filters]);
  useEffect(() => { usedNamesRef.current = usedNames; }, [usedNames]);

  useEffect(() => {
    setHistory(loadData("datedice:history", []));
    setUsedNames(loadData("datedice:used", []));
  }, []);

  useEffect(() => {
    (async () => {
      try {
        const r = await fetch("https://api.open-meteo.com/v1/forecast?latitude=40.6782&longitude=-73.9442&current=temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,wind_speed_10m,uv_index&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=America/New_York");
        const d = await r.json();
        const c = d.current;
        const wmo = WMO[c.weather_code] || WMO[0];
        const classification = classifyWeather(c.temperature_2m, c.weather_code, c.relative_humidity_2m, c.wind_speed_10m);
        const autoFilter = weatherToFilter(classification);
        setWeather({ tempF: Math.round(c.temperature_2m), feelsF: Math.round(c.apparent_temperature), humidity: Math.round(c.relative_humidity_2m), windMph: Math.round(c.wind_speed_10m), wmoLabel: wmo.l, wmoIcon: wmo.i, classification, autoFilter });
        setFilters((f) => ({ ...f, weather: autoFilter, timeOfDay: getTimeOfDay() }));
      } catch (e) { console.error(e); }
      setWeatherLoading(false);
    })();
  }, []);

  useEffect(() => {
    return () => { if (diceInterval.current) clearInterval(diceInterval.current); };
  }, []);

  // ── Shake to roll (mobile) ──
  useEffect(() => {
    if (screen !== "app" || tab !== "roll") return;
    let lastShake = 0;
    const threshold = 25;
    let lastX = 0, lastY = 0, lastZ = 0;

    function onMotion(e) {
      const a = e.accelerationIncludingGravity;
      if (!a) return;
      const dx = Math.abs(a.x - lastX);
      const dy = Math.abs(a.y - lastY);
      const dz = Math.abs(a.z - lastZ);
      lastX = a.x; lastY = a.y; lastZ = a.z;
      if ((dx + dy + dz) > threshold && Date.now() - lastShake > 2000) {
        lastShake = Date.now();
        if (subScreen === "filters") {
          setSubScreen("rolling");
          doRoll();
        }
      }
    }

    window.addEventListener("devicemotion", onMotion);
    return () => window.removeEventListener("devicemotion", onMotion);
  }, [screen, tab, subScreen]);

  // ── Rotating loading messages ──
  useEffect(() => {
    if (rolling) {
      const cat = filtersRef.current.category || "Surprise Me";
      const emojiSet = cat === "Food & Drink" ? LOADING_EMOJI.food : cat === "Activities" ? LOADING_EMOJI.activity : LOADING_EMOJI.default;
      let idx = 0;
      setLoadingMsg(LOADING_MESSAGES[0]);
      setLoadingEmoji(emojiSet[0]);
      loadingInterval.current = setInterval(() => {
        idx = (idx + 1) % LOADING_MESSAGES.length;
        setLoadingMsg(LOADING_MESSAGES[idx]);
        setLoadingEmoji(emojiSet[idx % emojiSet.length]);
      }, 2200);
    } else {
      if (loadingInterval.current) clearInterval(loadingInterval.current);
    }
    return () => { if (loadingInterval.current) clearInterval(loadingInterval.current); };
  }, [rolling]);

  const showToast = (msg) => { setToast(msg); setTimeout(() => setToast(null), 2500); };

  const doRoll = useCallback(async () => {
    rollCount.current += 1;
    const myRoll = rollCount.current;
    const currentFilters = filtersRef.current;
    const currentUsed = [...usedNamesRef.current];

    if (diceInterval.current) { clearInterval(diceInterval.current); diceInterval.current = null; }
    setRolling(true); setResult(null); setAltResults([]); setShowAlts(false); setLocked(false); setAltsLoading(false); setStreamText(""); setShowConfetti(false);

    diceInterval.current = setInterval(() => {
      setDiceVals([Math.ceil(Math.random() * 6), Math.ceil(Math.random() * 6)]);
    }, 100);

    function stopDice() {
      if (diceInterval.current) { clearInterval(diceInterval.current); diceInterval.current = null; }
      setDiceVals([Math.ceil(Math.random() * 6), Math.ceil(Math.random() * 6)]);
    }

    const cat = currentFilters.category || "Surprise Me";
    const type = cat === "Food & Drink" ? "food" : cat === "Activities" ? "activity" : Math.random() > 0.45 ? "food" : "activity";

    let res = null;
    try {
      res = await fetchSuggestionStream(type, currentFilters, currentUsed, (text) => {
        if (rollCount.current === myRoll) setStreamText(text);
      });
      if (!res) {
        res = await fetchSuggestion(type, currentFilters, currentUsed);
      }
      if (!res) {
        await new Promise((r) => setTimeout(r, 1000));
        if (rollCount.current !== myRoll) return;
        res = await fetchSuggestion(type, currentFilters, currentUsed);
      }
    } catch (err) {
      console.error("doRoll:", err);
    }

    if (rollCount.current !== myRoll) return;
    stopDice();
    setRolling(false);
    setStreamText("");

    if (res && res.name) {
      const newUsed = currentUsed.concat([res.name]);
      usedNamesRef.current = newUsed;
      setUsedNames(newUsed);
      saveData("datedice:used", newUsed.slice(-200));
      setResult(res);
      setShowConfetti(true);
      setTimeout(() => setShowConfetti(false), 2500);
    } else {
      setResult({ name: "Nothing came back", desc: "The search didn't return a result — tap Re-roll to try again!", emoji: "🎲", cat: "Try Again", area: "NYC" });
    }
  }, []);

  const loadAlt = useCallback(async () => {
    if (rolling) return;
    const currentFilters = filtersRef.current;
    const allUsed = [...usedNamesRef.current];
    const thisRoll = rollCount.current;
    const cat = currentFilters.category || "Surprise Me";
    let type;
    if (cat === "Food & Drink") type = "food";
    else if (cat === "Activities") type = "activity";
    else type = Math.random() > 0.45 ? "food" : "activity";
    setAltsLoading(true);
    try {
      const [alt1, alt2] = await Promise.all([
        fetchSuggestion(type, currentFilters, allUsed),
        fetchSuggestion(type, currentFilters, allUsed),
      ]);
      if (rollCount.current !== thisRoll) { setAltsLoading(false); return; }
      const newAlts = [];
      const seen = new Set(allUsed.map((n) => n.toLowerCase()));
      [alt1, alt2].forEach((alt) => {
        if (alt && alt.name && !seen.has(alt.name.toLowerCase())) {
          seen.add(alt.name.toLowerCase());
          newAlts.push(alt);
        }
      });
      if (newAlts.length > 0) {
        const newNames = allUsed.concat(newAlts.map((a) => a.name));
        usedNamesRef.current = newNames;
        setUsedNames(newNames);
        saveData("datedice:used", newNames.slice(-200));
        setAltResults((prev) => prev.concat(newAlts));
      }
    } catch (e) { if (e && e.name !== "AbortError") console.error("loadAlt:", e); }
    setAltsLoading(false);
  }, [rolling]);

  const lockIn = (item) => {
    const entry = { ...item, id: Date.now().toString(), status: "locked", lockedAt: new Date().toISOString(), rating: null };
    const next = [entry].concat(history);
    setHistory(next); saveData("datedice:history", next); setLocked(true);
    showToast("🔒 Locked in! It's a date.");
  };
  const markComplete = (id, rating) => {
    const next = history.map((h) => h.id === id ? { ...h, status: "completed", completedAt: new Date().toISOString(), rating } : h);
    setHistory(next); saveData("datedice:history", next); showToast("✓ Date completed!");
  };
  const removeEntry = (id) => {
    const next = history.filter((h) => h.id !== id);
    setHistory(next); saveData("datedice:history", next); showToast("Removed.");
  };

  // ── Native share with clipboard fallback ──
  const sharePlan = (item) => {
    const text = "🎲 Date Dice picked:\n\n" + (item.emoji || "🎲") + " " + item.name + "\n📍 " + item.area + (item.address && item.address !== item.area ? "\n📫 " + item.address : "") + "\n\n" + item.desc + (item.tip ? "\n\n💡 " + item.tip : "") + "\n\nLet's do this! 💛";
    if (navigator.share) {
      navigator.share({ title: "Date Dice: " + item.name, text }).catch(() => {});
    } else {
      navigator.clipboard.writeText(text).then(() => showToast("📋 Copied to clipboard!")).catch(() => showToast("Couldn't copy — try long-press"));
    }
  };

  const handleTabChange = (t) => { setTab(t); setTabKey((k) => k + 1); if (t === "roll") setSubScreen("filters"); };

  const applyPreset = (preset) => {
    setFilters((f) => ({ ...f, ...preset.filters }));
    showToast(preset.emoji + " " + preset.label + " loaded!");
  };

  const timeTint = getTimeTint();
  const pageStyle = { minHeight: "100vh", background: `radial-gradient(ellipse at 20% 0%,${timeTint} 0%,transparent 50%),radial-gradient(ellipse at 80% 100%,rgba(201,125,74,0.05) 0%,transparent 50%)`, color: P.text, fontFamily: serif, position: "relative" };

  // ── Home Screen ──
  if (screen === "home") {
    return (
      <div style={pageStyle}>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", minHeight: "100vh", padding: "40px 20px", textAlign: "center", position: "relative", overflow: "hidden" }}>
          <div style={{ fontSize: "72px", marginBottom: "16px", filter: "drop-shadow(0 0 24px rgba(232,195,106,0.3))" }} aria-hidden="true">🎲</div>
          <h1 style={{ fontSize: "clamp(38px, 8vw, 58px)", fontWeight: "400", letterSpacing: "0.04em", margin: "0 0 8px", background: P.grad, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>Date Dice</h1>
          <p style={{ fontSize: "14px", color: P.textDim, letterSpacing: "0.18em", textTransform: "uppercase", margin: "0 0 8px", fontFamily: sans }}>New York City Edition</p>
          <p style={{ fontSize: "13px", color: P.accent, margin: "0 0 8px", fontFamily: sans }}>📅 {formatDate(new Date())} · {getSeason()}</p>
          {weather && <p style={{ fontSize: "13px", color: P.textDim, margin: "0 0 6px", fontFamily: sans }}>{weather.wmoIcon} {weather.tempF}°F · {weather.classification} in Brooklyn</p>}
          {history.length > 0 && <p style={{ fontSize: "13px", color: P.textDim, margin: "0 0 6px", fontFamily: sans }}>{history.filter((h) => h.status === "completed").length} dates completed · {history.filter((h) => h.status === "locked").length} upcoming</p>}
          <div style={{ height: "24px" }} />
          <p style={{ fontSize: "17px", lineHeight: 1.7, maxWidth: "400px", color: "rgba(240,236,226,0.6)", margin: "0 0 12px" }}>Set your mood. Roll the dice.<br />Let the city surprise you.</p>
          <p style={{ fontSize: "13px", color: P.textDim, margin: "0 0 40px", fontFamily: sans, maxWidth: "360px" }}>Every roll searches live for real restaurants, activities & experiences across 50+ NYC neighborhoods</p>
          <Btn primary onClick={() => setScreen("app")} style={{ padding: "16px 56px", fontSize: "16px", boxShadow: "0 4px 28px rgba(232,195,106,0.3)" }}>Let's Go</Btn>
        </div>
      </div>
    );
  }

  // ── App Screen ──
  const activeFilterCount = Object.values(filters).filter(Boolean).length;

  return (
    <div style={pageStyle}>
      <Confetti active={showConfetti} />
      {toast && (
        <div role="status" aria-live="polite" style={{ position: "fixed", top: "16px", left: "50%", transform: "translateX(-50%)", zIndex: 200, background: "rgba(15,15,28,0.95)", border: "1px solid " + P.goldDim, borderRadius: "14px", padding: "12px 24px", fontFamily: sans, fontSize: "14px", color: P.gold, boxShadow: "0 8px 32px rgba(0,0,0,0.4)", animation: "fadeUp 0.3s ease", backdropFilter: "blur(12px)" }}>{toast}</div>
      )}

      <div className="app-shell">
        <SideNav tab={tab} setTab={handleTabChange} historyCount={history.filter((h) => h.status === "locked").length} />

        <main className="main-content">
          <div key={tabKey} className="tab-content-enter">

          {/* ── Roll Tab: Filters ── */}
          {tab === "roll" && subScreen === "filters" && (
            <div>
              <h2 style={{ fontSize: "26px", fontWeight: "400", margin: "0 0 4px", color: P.gold }}>Set the Scene</h2>
              <p style={{ fontSize: "13px", color: P.textDim, margin: "0 0 16px", fontFamily: sans }}>Pick what matters — skip what doesn't</p>

              {/* Quick Filter Presets */}
              <div style={{ display: "flex", gap: "8px", marginBottom: "20px", flexWrap: "wrap" }}>
                {FILTER_PRESETS.map((preset) => (
                  <button
                    key={preset.label}
                    onClick={() => applyPreset(preset)}
                    style={{
                      background: "linear-gradient(135deg, rgba(232,195,106,0.08), rgba(201,125,74,0.08))",
                      border: "1px solid rgba(232,195,106,0.15)",
                      borderRadius: "20px",
                      padding: "8px 14px",
                      fontSize: "12px",
                      fontFamily: sans,
                      color: P.gold,
                      cursor: "pointer",
                      transition: "all 0.2s",
                      display: "flex",
                      alignItems: "center",
                      gap: "5px",
                    }}
                    aria-label={`Apply ${preset.label} preset`}
                  >
                    <span aria-hidden="true">{preset.emoji}</span> {preset.label}
                  </button>
                ))}
              </div>

              <WeatherBadge weather={weather} loading={weatherLoading} />
              {Object.entries(FILTERS_MAIN).map(([key, cfg]) => (
                <div key={key} style={{ marginBottom: "22px" }} role="group" aria-labelledby={"filter-" + key}>
                  <div id={"filter-" + key} style={{ fontSize: "12px", color: "rgba(240,236,226,0.7)", textTransform: "uppercase", letterSpacing: "0.15em", marginBottom: "8px", fontFamily: sans }}>
                    <span aria-hidden="true">{cfg.icon}</span> {cfg.label}
                    {key === "budget" && <span style={{ color: P.accent, marginLeft: "6px", textTransform: "none", letterSpacing: "0", fontSize: "11px" }}>($150–300 = upscale · Splurge = $300+)</span>}
                  </div>
                  <div style={{ display: "flex", flexWrap: "wrap", gap: "8px" }} role="listbox" aria-label={cfg.label}>
                    {cfg.options.map((opt) => (
                      <Chip key={opt} active={filters[key] === opt} onClick={() => setFilters((f) => { const n = { ...f }; if (n[key] === opt) delete n[key]; else n[key] = opt; return n; })}>{opt}</Chip>
                    ))}
                  </div>
                </div>
              ))}

              {/* Neighborhood with borough-colored dots */}
              <div style={{ marginBottom: "22px" }}>
                <button onClick={() => setShowNeighborhoods(!showNeighborhoods)} aria-expanded={showNeighborhoods} aria-controls="neighborhood-list" style={{ background: "none", border: "none", padding: 0, cursor: "pointer", display: "flex", alignItems: "center", gap: "6px", marginBottom: "8px", width: "100%" }}>
                  <span style={{ fontSize: "12px", color: "rgba(240,236,226,0.7)", textTransform: "uppercase", letterSpacing: "0.15em", fontFamily: sans }}>📍 Neighborhood</span>
                  {filters.neighborhood?.length > 0 && <span style={{ fontSize: "12px", color: P.gold, fontFamily: sans }}>· {filters.neighborhood.length === 1 ? filters.neighborhood[0] : filters.neighborhood.length + " selected"}</span>}
                  <span style={{ fontSize: "10px", color: P.textDim, marginLeft: "auto" }} aria-hidden="true">{showNeighborhoods ? "▴" : "▾"}</span>
                </button>
                {showNeighborhoods && (
                  <div id="neighborhood-list">
                    {filters.neighborhood?.length > 0 && <div style={{ marginBottom: "8px" }}><Chip small active onClick={() => setFilters((f) => { const n = { ...f }; delete n.neighborhood; return n; })}>✕ Clear All ({filters.neighborhood.length})</Chip></div>}
                    {Object.entries(NEIGHBORHOODS).map(([borough, hoods]) => (
                      <div key={borough} style={{ marginTop: "10px" }}>
                        <div style={{ fontSize: "11px", color: BOROUGH_COLORS[borough] || P.accent, fontFamily: sans, fontWeight: "700", marginBottom: "6px", display: "flex", alignItems: "center", gap: "6px" }}>
                          <span style={{ width: "8px", height: "8px", borderRadius: "50%", background: BOROUGH_COLORS[borough] || P.accent, display: "inline-block", flexShrink: 0 }} aria-hidden="true" />
                          {borough}
                        </div>
                        <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
                          {hoods.map((h) => <Chip key={h} small active={(filters.neighborhood || []).includes(h)} onClick={() => setFilters((f) => { const prev = f.neighborhood || []; const next = prev.includes(h) ? prev.filter((x) => x !== h) : [...prev, h]; const n = { ...f }; if (next.length === 0) delete n.neighborhood; else n.neighborhood = next; return n; })}>{h}</Chip>)}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Cuisine */}
              {(filters.category === "Food & Drink" || !filters.category || filters.category === "Surprise Me") && (
                <div style={{ marginBottom: "22px" }}>
                  <button onClick={() => setShowCuisines(!showCuisines)} aria-expanded={showCuisines} aria-controls="cuisine-list" style={{ background: "none", border: "none", padding: 0, cursor: "pointer", display: "flex", alignItems: "center", gap: "6px", marginBottom: "8px", width: "100%" }}>
                    <span style={{ fontSize: "12px", color: "rgba(240,236,226,0.7)", textTransform: "uppercase", letterSpacing: "0.15em", fontFamily: sans }}>🍽 Cuisine</span>
                    {filters.cuisine && <span style={{ fontSize: "12px", color: P.gold, fontFamily: sans }}>· {filters.cuisine}</span>}
                    <span style={{ fontSize: "10px", color: P.textDim, marginLeft: "auto" }} aria-hidden="true">{showCuisines ? "▴" : "▾"}</span>
                  </button>
                  {showCuisines && (
                    <div id="cuisine-list">
                      {filters.cuisine && <div style={{ marginBottom: "8px" }}><Chip small active onClick={() => setFilters((f) => { const n = { ...f }; delete n.cuisine; return n; })}>✕ Clear</Chip></div>}
                      <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
                        {CUISINES.map((c) => <Chip key={c} small active={filters.cuisine === c} onClick={() => setFilters((f) => { const n = { ...f }; if (n.cuisine === c) delete n.cuisine; else n.cuisine = c; return n; })}>{c}</Chip>)}
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* Activity Type */}
              {(filters.category === "Activities" || !filters.category || filters.category === "Surprise Me") && (
                <div style={{ marginBottom: "22px" }}>
                  <button onClick={() => setShowActivityTypes(!showActivityTypes)} aria-expanded={showActivityTypes} aria-controls="activity-type-list" style={{ background: "none", border: "none", padding: 0, cursor: "pointer", display: "flex", alignItems: "center", gap: "6px", marginBottom: "8px", width: "100%" }}>
                    <span style={{ fontSize: "12px", color: "rgba(240,236,226,0.7)", textTransform: "uppercase", letterSpacing: "0.15em", fontFamily: sans }}>🎯 Activity Type</span>
                    {filters.activityType && <span style={{ fontSize: "12px", color: P.gold, fontFamily: sans }}>· {filters.activityType}</span>}
                    <span style={{ fontSize: "10px", color: P.textDim, marginLeft: "auto" }} aria-hidden="true">{showActivityTypes ? "▴" : "▾"}</span>
                  </button>
                  {showActivityTypes && (
                    <div id="activity-type-list">
                      {filters.activityType && <div style={{ marginBottom: "8px" }}><Chip small active onClick={() => setFilters((f) => { const n = { ...f }; delete n.activityType; return n; })}>✕ Clear</Chip></div>}
                      <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
                        {ACTIVITY_TYPES.map((a) => <Chip key={a} small active={filters.activityType === a} onClick={() => setFilters((f) => { const n = { ...f }; if (n.activityType === a) delete n.activityType; else n.activityType = a; return n; })}>{a}</Chip>)}
                      </div>
                    </div>
                  )}
                </div>
              )}

              {activeFilterCount === 0 && !weatherLoading && (
                <div style={{ background: "rgba(232,195,106,0.06)", border: "1px dashed rgba(232,195,106,0.25)", borderRadius: "12px", padding: "12px 16px", marginBottom: "12px", fontFamily: sans, fontSize: "13px", color: P.textDim, textAlign: "center" }}>
                  💡 No filters set — we'll surprise you completely. Or pick a few above to guide the roll!
                </div>
              )}
              <Btn primary onClick={() => { setSubScreen("rolling"); doRoll(); }} style={{ width: "100%", padding: "16px", fontSize: "16px", boxShadow: "0 4px 24px rgba(232,195,106,0.3)", marginTop: "8px" }}>
                🎲 Roll the Dice {activeFilterCount > 0 ? "(" + activeFilterCount + " set)" : "— Totally Random"}
              </Btn>
              <p style={{ textAlign: "center", fontSize: "11px", color: P.textDim, fontFamily: sans, marginTop: "8px", opacity: 0.5 }}>📱 On mobile? Shake your phone to roll!</p>
            </div>
          )}

          {/* ── Roll Tab: Rolling ── */}
          {tab === "roll" && subScreen === "rolling" && (
            <div>
              <button onClick={() => {
                if (diceInterval.current) { clearInterval(diceInterval.current); diceInterval.current = null; }
                setSubScreen("filters"); setResult(null); setRolling(false); setAltsLoading(false); setStreamText("");
              }} aria-label="Go back to filters" style={{ display: "inline-flex", alignItems: "center", gap: "6px", background: "rgba(255,255,255,0.05)", border: "1px solid " + P.border, borderRadius: "20px", padding: "8px 16px", color: P.textDim, fontSize: "13px", fontFamily: sans, cursor: "pointer", marginBottom: "28px", transition: "all 0.2s" }}>
                ← Change Filters {activeFilterCount > 0 && <span style={{ background: P.goldDim, color: P.gold, borderRadius: "10px", padding: "1px 7px", fontSize: "11px", fontWeight: "700" }}>{activeFilterCount} set</span>}
              </button>
              <div style={{ display: "flex", justifyContent: "center", gap: "32px", marginBottom: "40px", opacity: result ? 0.2 : 1, transition: "opacity 0.7s" }}>
                <Dice3D value={diceVals[0]} rolling={rolling} size={82} />
                <Dice3D value={diceVals[1]} rolling={rolling} size={82} />
              </div>
              {rolling && (
                <div style={{ textAlign: "center" }} role="status" aria-label="Finding your perfect spot">
                  <div style={{ fontSize: "28px", marginBottom: "8px", transition: "all 0.3s" }} aria-hidden="true">{loadingEmoji}</div>
                  <p style={{ color: P.goldBright, fontSize: "15px", fontStyle: "italic", animation: "pulse 1s infinite", transition: "opacity 0.3s" }}>{loadingMsg}</p>
                  <p style={{ color: P.textDim, fontSize: "12px", fontFamily: sans, marginTop: "4px" }}>
                    {filters.neighborhood?.length > 0 ? "In " + (filters.neighborhood.length === 1 ? filters.neighborhood[0] : filters.neighborhood.length + " neighborhoods") : "All of NYC"}
                    {filters.cuisine ? " · " + filters.cuisine : ""}
                    {filters.activityType ? " · " + filters.activityType : ""}
                  </p>
                  {streamText && (
                    <p style={{ color: P.textDim, fontSize: "11px", fontFamily: sans, marginTop: "12px", maxWidth: "400px", margin: "12px auto 0", opacity: 0.6, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                      {streamText.slice(-80)}...
                    </p>
                  )}
                </div>
              )}
              {result && !rolling && (
                <div>
                  <ResultCard
                    result={result} locked={locked} rolling={rolling} altsLoading={altsLoading}
                    onReroll={() => { setLocked(false); setAltResults([]); setShowAlts(false); doRoll(); }}
                    onLoadAlt={loadAlt}
                    onLockIn={() => lockIn(result)}
                    onShare={() => sharePlan(result)}
                    onTweakFilters={() => { setSubScreen("filters"); setResult(null); setRolling(false); setAltsLoading(false); setStreamText(""); if (diceInterval.current) { clearInterval(diceInterval.current); diceInterval.current = null; } }}
                  />
                  {altResults.length > 0 && (
                    <div style={{ marginTop: "16px" }}>
                      <button onClick={() => setShowAlts(!showAlts)} aria-expanded={showAlts} style={{ background: "none", border: "none", color: P.textDim, fontSize: "12px", cursor: "pointer", fontFamily: sans, letterSpacing: "0.1em", textTransform: "uppercase", width: "100%", textAlign: "center", padding: "8px 0" }}>
                        {showAlts ? "Hide" : "Show"} other picks ▾
                      </button>
                      {showAlts && altResults.map((alt, i) => (
                        <div key={i} onClick={() => { setResult(alt); setShowAlts(false); setLocked(false); }} role="button" tabIndex={0} onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); setResult(alt); setShowAlts(false); setLocked(false); } }} aria-label={`Switch to ${alt.name}`} style={{ background: P.card, border: "1px solid " + P.border, borderRadius: "14px", padding: "14px 18px", cursor: "pointer", marginTop: "8px", display: "flex", alignItems: "center", gap: "12px" }}>
                          <span style={{ fontSize: "26px" }} aria-hidden="true">{alt.emoji || "🎲"}</span>
                          <div>
                            <div style={{ color: P.text, fontSize: "14px", fontWeight: "500", fontFamily: sans }}>{alt.name}</div>
                            <div style={{ color: P.textDim, fontSize: "12px", fontFamily: sans }}>{alt.cuisine || alt.cat} · {alt.area}</div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {/* ── Discover Tab ── */}
          {tab === "discover" && (
            <DiscoverScreen />
          )}

          {/* ── Calendar Tab ── */}
          {tab === "calendar" && (
            <div>
              <h2 style={{ fontSize: "24px", fontWeight: "400", margin: "0 0 4px", color: P.gold }}>My Dates</h2>
              <p style={{ fontSize: "13px", color: P.textDim, margin: "0 0 20px", fontFamily: sans }}>Your date history & upcoming plans</p>
              <div style={{ background: P.card, border: "1px solid " + P.border, borderRadius: "16px", padding: "20px", marginBottom: "24px" }}>
                <MiniCalendar history={history} />
              </div>
              {history.length > 0 && (
                <div style={{ display: "flex", gap: "8px", marginBottom: "24px" }}>
                  {[
                    { n: history.filter((h) => h.status === "locked").length, l: "Upcoming", c: P.gold },
                    { n: history.filter((h) => h.status === "completed").length, l: "Completed", c: P.green },
                    { n: history.length, l: "Total", c: P.blue },
                  ].map((s, i) => (
                    <div key={i} style={{ flex: 1, background: P.card, border: "1px solid " + P.border, borderRadius: "14px", padding: "14px", textAlign: "center" }}>
                      <div style={{ fontSize: "24px", fontWeight: "700", color: s.c, fontFamily: sans }}>{s.n}</div>
                      <div style={{ fontSize: "11px", color: P.textDim, fontFamily: sans, textTransform: "uppercase", letterSpacing: "0.1em" }}>{s.l}</div>
                    </div>
                  ))}
                </div>
              )}
              {history.length === 0 && (
                <div style={{ textAlign: "center", padding: "40px 20px", color: P.textDim, fontFamily: sans }}>
                  <div style={{ fontSize: "32px", marginBottom: "12px" }} aria-hidden="true">🎲</div>
                  <p>No dates yet! Roll the dice to get started.</p>
                </div>
              )}
              <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
                {history.map((h) => (
                  <div key={h.id} style={{ background: P.card, border: "1px solid " + P.border, borderRadius: "16px", padding: "16px 18px" }}>
                    <div style={{ display: "flex", alignItems: "flex-start", gap: "12px" }}>
                      <span style={{ fontSize: "28px" }} aria-hidden="true">{h.emoji || "🎉"}</span>
                      <div style={{ flex: 1 }}>
                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: "8px" }}>
                          <div style={{ fontFamily: sans, fontSize: "15px", color: P.text, fontWeight: "600" }}>{h.name}</div>
                          <span style={{ fontSize: "10px", fontFamily: sans, fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.1em", color: h.status === "completed" ? P.green : P.gold, background: h.status === "completed" ? "rgba(110,207,148,0.1)" : P.goldDim, padding: "4px 10px", borderRadius: "20px", flexShrink: 0 }}>
                            {h.status === "completed" ? "Done" : "Upcoming"}
                          </span>
                        </div>
                        <div style={{ fontSize: "12px", color: P.textDim, fontFamily: sans, margin: "4px 0" }}>
                          📍 {h.area}{h.address && h.address !== h.area ? " — " + h.address : ""} · {new Date(h.lockedAt || h.completedAt).toLocaleDateString()}
                        </div>
                        {h.rating && <div style={{ fontSize: "13px", marginTop: "4px" }} aria-label={`Rated ${h.rating} stars`}>{"⭐".repeat(h.rating)}</div>}
                        <div style={{ display: "flex", gap: "6px", marginTop: "10px", flexWrap: "wrap", alignItems: "center" }}>
                          {h.status === "locked" && (
                            <div style={{ display: "flex", gap: "4px", alignItems: "center" }}>
                              <span style={{ fontSize: "11px", color: P.textDim, fontFamily: sans, marginRight: "2px" }}>Rate:</span>
                              {[1, 2, 3, 4, 5].map((r) => (
                                <button key={r} onClick={() => markComplete(h.id, r)} aria-label={`Rate ${r} star${r > 1 ? 's' : ''}`} style={{ background: "none", border: "1px solid " + P.border, borderRadius: "6px", padding: "3px 6px", cursor: "pointer", fontSize: "11px", lineHeight: 1 }}>
                                  {"★".repeat(r)}
                                </button>
                              ))}
                            </div>
                          )}
                          <button onClick={() => removeEntry(h.id)} aria-label={`Remove ${h.name}`} style={{ background: "none", border: "none", color: P.textDim, fontSize: "12px", cursor: "pointer", fontFamily: sans, marginLeft: "auto" }}>Remove</button>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          </div>
        </main>
      </div>

      <NavBar tab={tab} setTab={handleTabChange} historyCount={history.filter((h) => h.status === "locked").length} />
    </div>
  );
}
