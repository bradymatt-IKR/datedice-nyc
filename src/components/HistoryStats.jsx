import { useState, useMemo } from 'react';
import { P, sans, serif, NEIGHBORHOODS, BOROUGH_COLORS } from '../data/constants.js';

const PRICE_MAP = { "Free": 0, "$": 25, "$$": 75, "$$$": 175, "$$$$": 350, "Under $50": 25, "$50-150": 100, "$50–150": 100, "$150-300": 225, "$150–300": 225, "Splurge": 400 };

function areaToBoroughLookup() {
  const map = {};
  for (const [borough, areas] of Object.entries(NEIGHBORHOODS)) {
    for (const a of areas) map[a.toLowerCase()] = borough;
  }
  return map;
}
const AREA_BOROUGH = areaToBoroughLookup();

function areaToBorough(area) {
  if (!area) return null;
  const lower = area.toLowerCase();
  if (AREA_BOROUGH[lower]) return AREA_BOROUGH[lower];
  for (const [key, borough] of Object.entries(AREA_BOROUGH)) {
    if (lower.includes(key) || key.includes(lower)) return borough;
  }
  return null;
}

// ── Horizontal Bar Chart ──
function CuisineChart({ data }) {
  if (!data.length) return null;
  const max = Math.max(...data.map(d => d.count));
  return (
    <div>
      <h4 style={{ fontSize: "13px", color: P.gold, fontFamily: sans, margin: "0 0 12px", fontWeight: "600" }}>🍽 Cuisines Explored</h4>
      {data.slice(0, 8).map(d => (
        <div key={d.label} style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "7px" }}>
          <span style={{ width: "72px", fontSize: "11px", color: P.textDim, fontFamily: sans, textAlign: "right", flexShrink: 0, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{d.label}</span>
          <div style={{ flex: 1, height: "14px", background: "rgba(255,255,255,0.04)", borderRadius: "7px", overflow: "hidden" }}>
            <div style={{ width: (d.count / max * 100) + "%", height: "100%", background: P.grad, borderRadius: "7px", transition: "width 0.6s ease", minWidth: "8px" }} />
          </div>
          <span style={{ width: "18px", fontSize: "11px", color: P.gold, fontFamily: sans, textAlign: "right" }}>{d.count}</span>
        </div>
      ))}
    </div>
  );
}

// ── Donut Chart ──
function BoroughDonut({ data, total }) {
  if (!data.length) return null;
  const r = 44, cx = 60, cy = 60;
  const circumference = 2 * Math.PI * r;
  let offset = 0;

  return (
    <div>
      <h4 style={{ fontSize: "13px", color: P.gold, fontFamily: sans, margin: "0 0 12px", fontWeight: "600" }}>📍 Boroughs Covered</h4>
      <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
        <svg viewBox="0 0 120 120" width="110" height="110" style={{ flexShrink: 0 }}>
          {data.map(d => {
            const length = (d.count / total) * circumference;
            const seg = (
              <circle key={d.borough} cx={cx} cy={cy} r={r}
                fill="none" stroke={d.color} strokeWidth="14"
                strokeDasharray={length + " " + (circumference - length)}
                strokeDashoffset={-offset}
                transform={"rotate(-90 " + cx + " " + cy + ")"}
                strokeLinecap="round"
              />
            );
            offset += length;
            return seg;
          })}
          <text x={cx} y={cy - 4} textAnchor="middle" fill={P.text} fontSize="18" fontFamily={sans} fontWeight="700">{total}</text>
          <text x={cx} y={cy + 12} textAnchor="middle" fill={P.textDim} fontSize="9" fontFamily={sans}>dates</text>
        </svg>
        <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
          {data.map(d => (
            <div key={d.borough} style={{ display: "flex", alignItems: "center", gap: "6px" }}>
              <div style={{ width: "8px", height: "8px", borderRadius: "50%", background: d.color, flexShrink: 0 }} />
              <span style={{ fontSize: "11px", color: P.textDim, fontFamily: sans }}>{d.borough} ({d.count})</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ── Sparkline ──
function SpendingSparkline({ data }) {
  if (data.length < 2) return null;
  const maxVal = Math.max(...data.map(d => d.val), 1);
  const w = 260, h = 60, pad = 4;
  const points = data.map((d, i) => {
    const x = pad + (i / (data.length - 1)) * (w - pad * 2);
    const y = h - pad - ((d.val / maxVal) * (h - pad * 2));
    return x + "," + y;
  }).join(" ");

  return (
    <div>
      <h4 style={{ fontSize: "13px", color: P.gold, fontFamily: sans, margin: "0 0 12px", fontWeight: "600" }}>💰 Spending Trend</h4>
      <svg viewBox={"0 0 " + w + " " + h} width="100%" height={h} style={{ overflow: "visible" }}>
        <defs>
          <linearGradient id="sparkGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="rgba(232,195,106,0.3)" />
            <stop offset="100%" stopColor="rgba(232,195,106,0)" />
          </linearGradient>
        </defs>
        {/* area fill */}
        <polygon
          points={pad + "," + (h - pad) + " " + points + " " + (w - pad) + "," + (h - pad)}
          fill="url(#sparkGrad)"
        />
        {/* line */}
        <polyline
          points={points}
          fill="none" stroke={P.gold} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
        />
        {/* dots at ends */}
        {data.length > 0 && (() => {
          const last = data[data.length - 1];
          const lx = pad + ((data.length - 1) / (data.length - 1)) * (w - pad * 2);
          const ly = h - pad - ((last.val / maxVal) * (h - pad * 2));
          return <circle cx={lx} cy={ly} r="3" fill={P.gold} />;
        })()}
      </svg>
      <div style={{ display: "flex", justifyContent: "space-between", fontSize: "10px", color: P.textDim, fontFamily: sans, marginTop: "4px" }}>
        <span>Oldest</span>
        <span>Most recent</span>
      </div>
    </div>
  );
}

export default function HistoryStats({ history }) {
  const [open, setOpen] = useState(false);

  const { cuisineData, boroughData, boroughTotal, spendingData } = useMemo(() => {
    // Cuisine distribution
    const cuisineCounts = {};
    history.forEach(h => {
      if (h.cuisine && h.cuisine !== "type") {
        const c = h.cuisine.trim();
        cuisineCounts[c] = (cuisineCounts[c] || 0) + 1;
      }
    });
    const cuisineData = Object.entries(cuisineCounts)
      .map(([label, count]) => ({ label, count }))
      .sort((a, b) => b.count - a.count);

    // Borough distribution
    const boroughCounts = {};
    history.forEach(h => {
      const b = areaToBorough(h.area);
      if (b) boroughCounts[b] = (boroughCounts[b] || 0) + 1;
    });
    const boroughData = Object.entries(boroughCounts)
      .map(([borough, count]) => ({ borough, count, color: BOROUGH_COLORS[borough] || P.textDim }))
      .sort((a, b) => b.count - a.count);
    const boroughTotal = boroughData.reduce((s, d) => s + d.count, 0);

    // Spending sparkline (chronological, oldest first)
    const spendingData = history
      .filter(h => h.priceRange && PRICE_MAP[h.priceRange] !== undefined)
      .reverse()
      .slice(-20)
      .map(h => ({ val: PRICE_MAP[h.priceRange] || 0 }));

    return { cuisineData, boroughData, boroughTotal, spendingData };
  }, [history]);

  const hasData = cuisineData.length > 0 || boroughData.length > 0 || spendingData.length >= 2;
  if (!hasData) return null;

  return (
    <div style={{ marginBottom: "20px" }}>
      <button
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        style={{
          width: "100%", background: "rgba(255,255,255,0.03)", border: "1px solid " + P.border,
          borderRadius: "14px", padding: "12px 16px", cursor: "pointer",
          display: "flex", alignItems: "center", justifyContent: "space-between",
          color: P.gold, fontSize: "14px", fontFamily: sans, fontWeight: "600",
          transition: "all 0.2s",
        }}
      >
        <span>📊 Your Date Stats</span>
        <span style={{ fontSize: "12px", color: P.textDim, transition: "transform 0.2s", transform: open ? "rotate(180deg)" : "none" }}>▼</span>
      </button>
      {open && (
        <div style={{
          background: P.card, border: "1px solid " + P.border, borderTop: "none",
          borderRadius: "0 0 14px 14px", padding: "20px 16px",
          display: "flex", flexDirection: "column", gap: "24px",
          animation: "tabFadeIn 0.3s ease both",
        }}>
          {cuisineData.length > 0 && <CuisineChart data={cuisineData} />}
          {boroughData.length > 0 && <BoroughDonut data={boroughData} total={boroughTotal} />}
          {spendingData.length >= 2 && <SpendingSparkline data={spendingData} />}
        </div>
      )}
    </div>
  );
}
