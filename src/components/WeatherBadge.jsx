import { P, sans } from '../data/constants.js';
import { getSeason, getTimeOfDay } from '../utils/date.js';

export default function WeatherBadge({ weather, loading }) {
  if (loading) {
    return (
      <div style={{ display: "flex", alignItems: "center", gap: "8px", padding: "12px 16px", borderRadius: "14px", background: P.card, border: "1px solid " + P.border, marginBottom: "20px" }} role="status">
        <span style={{ fontSize: "20px", animation: "pulse 1s infinite" }} aria-hidden="true">🌐</span>
        <span style={{ fontFamily: sans, fontSize: "13px", color: P.textDim }}>Fetching live NYC weather...</span>
      </div>
    );
  }
  if (!weather) return null;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: "10px", padding: "14px 16px", borderRadius: "14px", background: "linear-gradient(135deg, rgba(232,195,106,0.06), rgba(201,125,74,0.06))", border: "1px solid " + P.goldDim, marginBottom: "20px" }} aria-label={`Current weather: ${weather.tempF}°F, ${weather.classification}`}>
      <span style={{ fontSize: "32px" }} aria-hidden="true">{weather.wmoIcon}</span>
      <div style={{ flex: 1 }}>
        <div style={{ fontFamily: sans, fontSize: "14px", color: P.text, fontWeight: "600" }}>{weather.tempF}°F · {weather.classification}</div>
        <div style={{ fontFamily: sans, fontSize: "12px", color: P.textDim, marginTop: "2px" }}>{weather.wmoLabel} · Feels {weather.feelsF}°F · 💨 {weather.windMph}mph · 💧{weather.humidity}%</div>
        <div style={{ fontFamily: sans, fontSize: "11px", color: P.accent, marginTop: "3px" }}>🗓 {getSeason()} · Auto → {weather.autoFilter} · {getTimeOfDay()}</div>
      </div>
    </div>
  );
}
