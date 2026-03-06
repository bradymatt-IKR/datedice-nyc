import { useState } from 'react';
import { P, sans, serif } from '../data/constants.js';

const MONTHS = ["January","February","March","April","May","June","July","August","September","October","November","December"];
const DAY_HEADERS = ["S","M","T","W","T","F","S"];

export default function MiniCalendar({ history }) {
  const [vd, setVd] = useState(new Date());
  const y = vd.getFullYear();
  const m = vd.getMonth();
  const fd = new Date(y, m, 1).getDay();
  const dim = new Date(y, m + 1, 0).getDate();
  const today = new Date();

  const dm = {};
  history.forEach((h) => {
    const d = new Date(h.lockedAt || h.completedAt);
    const k = d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate();
    if (!dm[k]) dm[k] = [];
    dm[k].push(h);
  });

  const cells = [];
  for (let i = 0; i < fd; i++) cells.push(<div key={"e" + i} />);
  for (let d = 1; d <= dim; d++) {
    const k = y + "-" + m + "-" + d;
    const entries = dm[k] || [];
    const isToday = today.getFullYear() === y && today.getMonth() === m && today.getDate() === d;
    const dateLabel = `${MONTHS[m]} ${d}${entries.length > 0 ? `, ${entries.length} date${entries.length > 1 ? 's' : ''} planned` : ''}`;
    cells.push(
      <div key={d} role="gridcell" aria-label={dateLabel} style={{ textAlign: "center", padding: "6px 2px", borderRadius: "10px", position: "relative", background: isToday ? P.goldDim : "transparent", color: entries.length > 0 ? P.gold : P.textDim, fontFamily: sans, fontSize: "13px" }}>
        {d}
        {entries.length > 0 && (
          <div style={{ position: "absolute", bottom: "2px", left: "50%", transform: "translateX(-50%)", display: "flex", gap: "2px" }}>
            {entries.map((_, i) => (
              <div key={i} style={{ width: "4px", height: "4px", borderRadius: "50%", background: _.status === "completed" ? P.green : P.gold }} />
            ))}
          </div>
        )}
      </div>
    );
  }

  return (
    <div role="grid" aria-label={`${MONTHS[m]} ${y} calendar`}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "12px" }}>
        <button onClick={() => setVd(new Date(y, m - 1, 1))} aria-label="Previous month" style={{ background: "none", border: "none", color: P.textDim, fontSize: "18px", cursor: "pointer", padding: "4px 8px" }}>‹</button>
        <span style={{ fontFamily: serif, fontSize: "16px", color: P.text }}>{MONTHS[m]} {y}</span>
        <button onClick={() => setVd(new Date(y, m + 1, 1))} aria-label="Next month" style={{ background: "none", border: "none", color: P.textDim, fontSize: "18px", cursor: "pointer", padding: "4px 8px" }}>›</button>
      </div>
      <div role="row" style={{ display: "grid", gridTemplateColumns: "repeat(7,1fr)", gap: "2px", marginBottom: "4px" }}>
        {DAY_HEADERS.map((d, i) => (
          <div key={i} role="columnheader" style={{ textAlign: "center", fontSize: "11px", color: P.textDim, fontFamily: sans, fontWeight: "700", padding: "4px" }}>{d}</div>
        ))}
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(7,1fr)", gap: "2px" }}>{cells}</div>
    </div>
  );
}
