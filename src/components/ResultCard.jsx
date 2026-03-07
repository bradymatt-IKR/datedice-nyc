import { P, sans, serif } from '../data/constants.js';
import { getBookingInfo } from '../utils/booking.js';
import Btn from './Btn.jsx';

export default function ResultCard({ result, onReroll, onLockIn, onShare, onTweakFilters, onLoadAlt, locked, rolling: isRolling, altsLoading }) {
  const booking = getBookingInfo(result);
  return (
    <div style={{ animation: "cardDeal 0.55s cubic-bezier(0.22,0.61,0.36,1) both" }} role="article" aria-label={`Suggestion: ${result.name}`}>
      <div style={{ background: "linear-gradient(135deg, rgba(232,195,106,0.08), rgba(201,125,74,0.08))", border: "1px solid rgba(232,195,106,0.2)", borderRadius: "20px", padding: "28px 24px", marginBottom: "16px" }}>
        <div style={{ fontSize: "44px", marginBottom: "10px" }} aria-hidden="true">{result.emoji || "🎲"}</div>
        <div style={{ fontSize: "11px", textTransform: "uppercase", letterSpacing: "0.2em", color: P.accent, marginBottom: "6px", fontFamily: sans }}>
          {result.cat}{result.cuisine ? " · " + result.cuisine : ""}{result.priceRange ? " · " + result.priceRange : ""}
        </div>
        <h3 style={{ fontSize: "24px", fontWeight: "400", margin: "0 0 6px", color: P.goldBright, fontFamily: serif }}>{result.name}</h3>
        <div style={{ fontSize: "13px", color: P.textDim, marginBottom: "4px", fontFamily: sans }}>📍 {result.area}{result.address && result.address !== result.area ? " — " + result.address : ""}</div>
        <p style={{ fontSize: "15px", lineHeight: 1.7, color: "rgba(240,236,226,0.8)", margin: "12px 0 0", fontFamily: serif }}>{result.desc}</p>
        {result.tip && <p style={{ fontSize: "13px", lineHeight: 1.6, color: P.accent, margin: "10px 0 0", fontFamily: sans }}>💡 {result.tip}</p>}
      </div>

      {booking && (
        <div style={{ marginBottom: "8px" }}>
          <button onClick={() => window.open(booking.url, "_blank", "noopener,noreferrer")} aria-label={booking.label + " for " + result.name} style={{
            width: "100%", display: "flex", alignItems: "center", justifyContent: "center", gap: "8px",
            background: "linear-gradient(135deg, rgba(110,207,148,0.15), rgba(106,175,232,0.15))",
            border: "1px solid rgba(110,207,148,0.35)", borderRadius: "14px", padding: "14px 20px",
            color: "#6ecf94", fontSize: "15px", fontWeight: "600", fontFamily: sans, cursor: "pointer", transition: "all 0.2s",
          }}>
            <span style={{ fontSize: "18px" }} aria-hidden="true">🗓</span>
            {booking.label}
            {booking.isFallback && <span style={{ fontSize: "11px", opacity: 0.6, fontWeight: "400" }}>(search)</span>}
          </button>
          {!booking.isFallback && (
            <button onClick={() => window.open("https://www.google.com/search?q=" + encodeURIComponent(result.name + " " + (result.address || "NYC") + " book reserve tickets"), "_blank", "noopener,noreferrer")} style={{
              width: "100%", background: "none", border: "none", padding: "6px 0 0",
              color: P.textDim, fontSize: "11px", fontFamily: sans, cursor: "pointer", opacity: 0.5,
              transition: "opacity 0.2s",
            }} onMouseEnter={e => e.currentTarget.style.opacity = "0.8"} onMouseLeave={e => e.currentTarget.style.opacity = "0.5"}>
              Link not working? Search instead ↗
            </button>
          )}
        </div>
      )}

      <div style={{ display: "flex", gap: "8px", marginBottom: "8px" }}>
        <Btn onClick={onReroll} disabled={isRolling} style={{ flex: 1 }}>{isRolling ? "Finding..." : "🎲 Re-roll"}</Btn>
        <Btn primary onClick={locked ? undefined : onLockIn} style={{ flex: 1, opacity: locked ? 0.6 : 1, cursor: locked ? "default" : "pointer", animation: locked ? "none" : "lockGlow 2s ease-in-out infinite", borderRadius: "50px" }}>{locked ? "✓ Locked In" : "🔒 Lock It In"}</Btn>
      </div>
      <div style={{ display: "flex", gap: "8px", flexWrap: "wrap", marginBottom: "8px" }}>
        <Btn small onClick={onShare} style={{ flex: "1 1 auto", fontSize: "12px" }} aria-label="Share this suggestion">📤 Share</Btn>
        <Btn small onClick={() => {
          const dest = encodeURIComponent((result.address || result.name) + ", New York, NY");
          window.open("https://www.google.com/maps/dir/?api=1&destination=" + dest + "&travelmode=walking", "_blank", "noopener,noreferrer");
        }} style={{ flex: "1 1 auto", fontSize: "12px" }} aria-label="Get walking directions">🚶 Directions</Btn>
        <Btn small onClick={() => window.open("https://www.google.com/search?q=" + encodeURIComponent(result.name + (result.address ? " " + result.address : " NYC")), "_blank", "noopener,noreferrer")} style={{ flex: "1 1 auto", fontSize: "12px" }} aria-label="Look up on Google">🔎 Look Up</Btn>
        <Btn small onClick={() => {
          const now = new Date(), s = new Date(now), e = new Date(now);
          s.setHours(19, 0, 0, 0); e.setHours(22, 0, 0, 0);
          const fmt = (d) => d.toISOString().replace(/[-:]/g, "").replace(/\.\d+/, "");
          window.open("https://calendar.google.com/calendar/render?action=TEMPLATE&text=" + encodeURIComponent("Date Night: " + result.name) + "&dates=" + fmt(s) + "/" + fmt(e) + "&details=" + encodeURIComponent(result.desc + (result.tip ? "\n\nTip: " + result.tip : "")) + "&location=" + encodeURIComponent((result.address || result.area) + ", New York, NY"), "_blank", "noopener,noreferrer");
        }} style={{ flex: "1 1 auto", fontSize: "12px" }} aria-label="Add to Google Calendar">📅 Google Cal</Btn>
      </div>
      <button onClick={onTweakFilters} aria-label="Change filters and roll again" style={{ width: "100%", background: "rgba(255,255,255,0.03)", border: "1px solid " + P.border, borderRadius: "12px", padding: "10px", color: "rgba(240,236,226,0.7)", fontSize: "13px", fontFamily: sans, cursor: "pointer", transition: "all 0.2s", display: "flex", alignItems: "center", justifyContent: "center", gap: "6px" }}>
        ← Change Filters & Roll Again
      </button>
      {onLoadAlt && (
        <button onClick={onLoadAlt} disabled={isRolling || altsLoading} aria-label={altsLoading ? "Finding another option" : "Load another option"} style={{
          width: "100%", marginTop: "8px",
          background: "rgba(255,255,255,0.03)",
          border: "1px dashed rgba(255,255,255,0.1)",
          borderRadius: "12px", padding: "10px",
          color: altsLoading ? P.gold : "rgba(240,236,226,0.7)",
          fontSize: "13px", fontFamily: sans,
          cursor: altsLoading ? "wait" : "pointer",
          display: "flex", alignItems: "center", justifyContent: "center", gap: "6px",
          transition: "all 0.2s",
        }}>
          {altsLoading
            ? <span><span style={{ animation: "spin 1s linear infinite", display: "inline-block", marginRight: "6px" }}>⟳</span> Finding another option...</span>
            : <span>✦ Load another option</span>}
        </button>
      )}
    </div>
  );
}
