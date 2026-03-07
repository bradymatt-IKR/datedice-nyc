import { P, sans } from '../data/constants.js';
import { getSeason, getTimeOfDay } from '../utils/date.js';

function AnimatedWeatherIcon({ classification }) {
  const container = { width: 36, height: 36, position: 'relative', flexShrink: 0, overflow: 'hidden' };

  if (['Sunny', 'Hot', 'Mild'].includes(classification)) {
    return (
      <div style={container} aria-hidden="true">
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          width: 16, height: 16, borderRadius: '50%',
          background: 'radial-gradient(circle, #ffd93d, #e8c36a)',
          transform: 'translate(-50%,-50%)',
          animation: 'weatherSunPulse 3s ease-in-out infinite',
          boxShadow: '0 0 8px rgba(232,195,106,0.5)',
        }} />
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          width: 32, height: 32,
          transform: 'translate(-50%,-50%)',
          animation: 'weatherSunRays 12s linear infinite',
        }}>
          {[0, 45, 90, 135].map(deg => (
            <div key={deg} style={{
              position: 'absolute', top: '50%', left: '50%',
              width: 2, height: 32,
              background: 'linear-gradient(to bottom, transparent 0%, rgba(232,195,106,0.4) 20%, transparent 40%, transparent 60%, rgba(232,195,106,0.4) 80%, transparent 100%)',
              transform: `translate(-50%,-50%) rotate(${deg}deg)`,
            }} />
          ))}
        </div>
      </div>
    );
  }

  if (['Rainy', 'Stormy'].includes(classification)) {
    return (
      <div style={container} aria-hidden="true">
        <div style={{ position: 'absolute', top: 2, left: 4, width: 24, height: 10, borderRadius: 10, background: 'rgba(180,190,220,0.5)' }} />
        {[0, 1, 2].map(i => (
          <div key={i} style={{
            position: 'absolute', left: 8 + i * 10, top: 10,
            width: 2, height: 8, borderRadius: '0 0 2px 2px',
            background: 'linear-gradient(to bottom, rgba(106,175,232,0.3), rgba(106,175,232,0.9))',
            animation: `weatherRainDrop ${0.6 + i * 0.15}s ease-in ${i * 0.2}s infinite`,
          }} />
        ))}
      </div>
    );
  }

  if (['Snowy', 'Frigid'].includes(classification)) {
    return (
      <div style={container} aria-hidden="true">
        <div style={{ position: 'absolute', top: 2, left: 4, width: 24, height: 10, borderRadius: 10, background: 'rgba(180,190,220,0.4)' }} />
        {[0, 1, 2].map(i => (
          <div key={i} style={{
            position: 'absolute', left: 6 + i * 11, top: 10,
            width: 4, height: 4, borderRadius: '50%',
            background: 'rgba(220,230,255,0.9)',
            animation: `weatherSnowFall ${1.2 + i * 0.3}s ease-in-out ${i * 0.35}s infinite`,
          }} />
        ))}
      </div>
    );
  }

  if (['Cloudy', 'Partly Cloudy', 'Foggy', 'Windy'].includes(classification)) {
    return (
      <div style={container} aria-hidden="true">
        <div style={{
          position: 'absolute', top: 8, left: 2,
          width: 26, height: 12, borderRadius: 12,
          background: 'rgba(180,190,220,0.6)',
          animation: 'weatherCloudDrift 4s ease-in-out infinite',
        }} />
        <div style={{
          position: 'absolute', top: 14, left: 8,
          width: 20, height: 10, borderRadius: 10,
          background: 'rgba(160,175,210,0.4)',
          animation: 'weatherCloudDrift 5s ease-in-out 0.5s infinite',
        }} />
      </div>
    );
  }

  if (classification === 'Cold') {
    return <span style={{ fontSize: 32 }} aria-hidden="true">❄️</span>;
  }

  return <span style={{ fontSize: 32 }} aria-hidden="true">🌤</span>;
}

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
      <AnimatedWeatherIcon classification={weather.classification} />
      <div style={{ flex: 1 }}>
        <div style={{ fontFamily: sans, fontSize: "14px", color: P.text, fontWeight: "600" }}>{weather.tempF}°F · {weather.classification}</div>
        <div style={{ fontFamily: sans, fontSize: "12px", color: P.textDim, marginTop: "2px" }}>{weather.wmoLabel} · Feels {weather.feelsF}°F · 💨 {weather.windMph}mph · 💧{weather.humidity}%</div>
        <div style={{ fontFamily: sans, fontSize: "11px", color: P.accent, marginTop: "3px" }}>🗓 {getSeason()} · Auto → {weather.autoFilter} · {getTimeOfDay()}</div>
      </div>
    </div>
  );
}
