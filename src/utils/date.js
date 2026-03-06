export function formatDate(d) {
  return d.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", year: "numeric" });
}

export function getTimeOfDay() {
  const h = new Date().getHours();
  if (h < 6) return "Late Night";
  if (h < 12) return "Morning";
  if (h < 17) return "Afternoon";
  if (h < 21) return "Evening";
  return "Late Night";
}

export function getSeason() {
  const m = new Date().getMonth();
  if (m >= 2 && m <= 4) return "Spring";
  if (m >= 5 && m <= 7) return "Summer";
  if (m >= 8 && m <= 10) return "Fall";
  return "Winter";
}

export function getDateRangeLabel(q) {
  const now = new Date();
  const day = now.getDay();
  const fmt = (d) => d.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" });

  if (q === "tonight") return "Tonight, " + fmt(now);
  if (q === "this week") {
    const e = new Date(now);
    e.setDate(e.getDate() + (7 - day));
    return fmt(now) + " – " + fmt(e);
  }
  if (q === "this weekend") {
    const s = new Date(now);
    s.setDate(s.getDate() + (6 - day));
    const su = new Date(s);
    su.setDate(su.getDate() + 1);
    return fmt(s) + " – " + fmt(su);
  }
  if (q === "next week") {
    const m2 = new Date(now);
    m2.setDate(m2.getDate() + (8 - day));
    const su = new Date(m2);
    su.setDate(su.getDate() + 6);
    return fmt(m2) + " – " + fmt(su);
  }
  return "";
}
