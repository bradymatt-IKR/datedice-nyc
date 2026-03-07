import { P, sans, display } from '../data/constants.js';

const TABS = [
  { id: "roll", icon: "🎲", label: "Roll the Dice" },
  { id: "discover", icon: "🔍", label: "Discover" },
  { id: "calendar", icon: "📅", label: "My Dates" },
];

export default function SideNav({ tab, setTab, historyCount }) {
  return (
    <nav className="side-nav" role="navigation" aria-label="Main navigation">
      <svg className="side-nav-logo" width="56" height="42" viewBox="0 0 120 80" fill="none" xmlns="http://www.w3.org/2000/svg"
           style={{ filter: "drop-shadow(0 0 12px rgba(232,195,106,0.3))" }} aria-hidden="true">
        <defs>
          <linearGradient id="sn-dice-grad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#e8c36a" />
            <stop offset="100%" stopColor="#c97d4a" />
          </linearGradient>
        </defs>
        <g transform="translate(28, 40) rotate(-12)">
          <rect x="-24" y="-24" width="48" height="48" rx="8" fill="url(#sn-dice-grad)" opacity="0.9" />
          <circle cx="-10" cy="-10" r="3.5" fill="rgba(255,255,255,0.9)" />
          <circle cx="0" cy="0" r="3.5" fill="rgba(255,255,255,0.9)" />
          <circle cx="10" cy="10" r="3.5" fill="rgba(255,255,255,0.9)" />
        </g>
        <g transform="translate(80, 38) rotate(8)">
          <rect x="-24" y="-24" width="48" height="48" rx="8" fill="url(#sn-dice-grad)" />
          <circle cx="-10" cy="-10" r="3.5" fill="rgba(255,255,255,0.9)" />
          <circle cx="10" cy="-10" r="3.5" fill="rgba(255,255,255,0.9)" />
          <circle cx="0" cy="0" r="3.5" fill="rgba(255,255,255,0.9)" />
          <circle cx="-10" cy="10" r="3.5" fill="rgba(255,255,255,0.9)" />
          <circle cx="10" cy="10" r="3.5" fill="rgba(255,255,255,0.9)" />
        </g>
      </svg>
      <div className="side-nav-title" style={{ fontFamily: display, fontWeight: 700 }}>Date Dice</div>
      <div className="side-nav-sub">New York City</div>
      {TABS.map((t) => (
        <button
          key={t.id}
          className={"side-nav-btn" + (tab === t.id ? " active" : "")}
          onClick={() => setTab(t.id)}
          aria-current={tab === t.id ? "page" : undefined}
          aria-label={t.label + (t.id === "calendar" && historyCount > 0 ? `, ${historyCount} upcoming` : "")}
        >
          <span className="nav-icon" aria-hidden="true">{t.icon}</span>
          <span>{t.label}</span>
          {t.id === "calendar" && historyCount > 0 && (
            <span className="side-nav-badge" aria-hidden="true">{historyCount}</span>
          )}
        </button>
      ))}
      <div style={{ marginTop: "auto", padding: "16px 0 0" }}>
        <div style={{ fontSize: "11px", color: P.textDim, fontFamily: sans, lineHeight: 1.6 }}>
          Roll the dice.<br />Let NYC surprise you.
        </div>
      </div>
    </nav>
  );
}
