import { P, sans } from '../data/constants.js';

const TABS = [
  { id: "roll", icon: "🎲", label: "Roll the Dice" },
  { id: "discover", icon: "🔍", label: "Discover" },
  { id: "calendar", icon: "📅", label: "My Dates" },
];

export default function SideNav({ tab, setTab, historyCount }) {
  return (
    <nav className="side-nav" role="navigation" aria-label="Main navigation">
      <div className="side-nav-logo" aria-hidden="true">🎲</div>
      <div className="side-nav-title">Date Dice</div>
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
