import { P, sans } from '../data/constants.js';

const TABS = [
  { id: "roll", icon: "🎲", label: "Roll" },
  { id: "discover", icon: "🔍", label: "Discover" },
  { id: "calendar", icon: "📅", label: "My Dates" },
];

export default function NavBar({ tab, setTab, historyCount }) {
  return (
    <nav
      className="bottom-nav"
      role="navigation"
      aria-label="Main navigation"
      style={{ position: "fixed", bottom: 0, left: 0, right: 0, zIndex: 100, background: "linear-gradient(transparent, " + P.bg + " 20%)", paddingTop: "28px" }}
    >
      <div style={{ display: "flex", justifyContent: "center", gap: "4px", background: "rgba(15,15,28,0.92)", backdropFilter: "blur(20px)", borderTop: "1px solid " + P.border, padding: "8px 12px 12px", maxWidth: "480px", margin: "0 auto", borderRadius: "20px 20px 0 0" }}>
        {TABS.map((t) => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            aria-current={tab === t.id ? "page" : undefined}
            aria-label={t.label + (t.id === "calendar" && historyCount > 0 ? `, ${historyCount} upcoming` : "")}
            style={{ flex: 1, background: tab === t.id ? P.goldDim : "transparent", border: "none", borderRadius: "12px", padding: "8px 4px", cursor: "pointer", display: "flex", flexDirection: "column", alignItems: "center", gap: "2px" }}
          >
            <span style={{ fontSize: "20px", position: "relative" }} aria-hidden="true">
              {t.icon}
              {t.id === "calendar" && historyCount > 0 && (
                <span aria-hidden="true" style={{ position: "absolute", top: "-4px", right: "-8px", background: P.rose, color: "#fff", fontSize: "10px", fontWeight: "700", borderRadius: "50%", width: "16px", height: "16px", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: sans }}>{historyCount}</span>
              )}
            </span>
            <span style={{ fontSize: "11px", color: tab === t.id ? P.gold : P.textDim, fontFamily: sans, fontWeight: "600" }}>{t.label}</span>
          </button>
        ))}
      </div>
    </nav>
  );
}
