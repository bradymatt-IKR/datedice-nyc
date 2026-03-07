import { useState, useEffect, useRef } from 'react';
import { P, sans, serif, LOADING_MESSAGES } from '../data/constants.js';
import { API_URL, stripCites } from '../utils/api.js';
import { formatDate, getDateRangeLabel, getSeason } from '../utils/date.js';
import Btn from './Btn.jsx';
import { BLOCKED_DOMAINS } from '../utils/blockedDomains.js';

const TIMEFRAMES = ["tonight", "this week", "this weekend", "next week"];
const DISCOVER_EMOJI = ["🗽", "🎭", "🎶", "🎨", "🌃", "🎪", "🎷", "🏙"];

const CATEGORIES = [
  { id: "music", label: "Live Music", emoji: "🎶" },
  { id: "theater", label: "Theater & Shows", emoji: "🎭" },
  { id: "museum", label: "Museums & Art", emoji: "🎨" },
  { id: "food", label: "Food & Drink", emoji: "🍷" },
  { id: "comedy", label: "Comedy", emoji: "😂" },
  { id: "nightlife", label: "Nightlife", emoji: "🌃" },
  { id: "outdoor", label: "Outdoors", emoji: "🌳" },
  { id: "popup", label: "Pop-ups & Markets", emoji: "🛍" },
];

// Variety prompts — rotated each search to push for different results
const VARIETY_HINTS = [
  "Focus on lesser-known, off-the-beaten-path events — avoid the most obvious tourist picks.",
  "Prioritize unique, one-time-only events and limited-run experiences over permanent attractions.",
  "Lean toward neighborhood gems and local favorites rather than big-name Broadway or museum staples.",
  "Emphasize new openings, recently launched exhibits, and events that started in the last month.",
  "Highlight free or low-cost events, community gatherings, and hidden cultural experiences.",
  "Focus on immersive, interactive, or participatory events — not just things to watch.",
  "Search for events from independent venues, small galleries, community spaces, and local cultural orgs.",
  "Look for events at unconventional venues — rooftops, warehouses, parks, bookstores, bars with back rooms.",
  "Prioritize events from neighborhood blogs, local Instagram accounts, and community boards over major listing sites.",
  "Focus on NYC-specific seasonal events, block parties, street fairs, and cultural festivals happening right now.",
];

/** Validate and clean a URL from search results. Returns clean URL or empty string. */
function cleanEventUrl(raw) {
  if (!raw || typeof raw !== "string" || !raw.startsWith("http")) return "";
  try {
    const u = new URL(raw);
    const host = u.hostname.toLowerCase();

    // Block known spam / search engine domains
    if (BLOCKED_DOMAINS.some((d) => host.includes(d))) {
      // Try to recover a real domain from redirect params
      const domainParam = u.searchParams.get("domain") || u.searchParams.get("url") ||
        u.searchParams.get("redirect") || u.searchParams.get("goto") || u.searchParams.get("target");
      if (domainParam) {
        const recovered = domainParam.startsWith("http") ? domainParam : "https://" + domainParam;
        try { new URL(recovered); return recovered; } catch { /* ignore */ }
      }
      return "";
    }

    // Block URLs with suspicious redirect/tracking params
    const params = u.search.toLowerCase();
    if (params.includes("oref=") || params.includes("psystem=")) {
      const domainParam = u.searchParams.get("domain");
      if (domainParam) {
        const recovered = domainParam.startsWith("http") ? domainParam : "https://" + domainParam;
        try { new URL(recovered); return recovered; } catch { /* ignore */ }
      }
      return "";
    }

    return raw;
  } catch {
    return "";
  }
}

function SkeletonCard({ delay }) {
  return (
    <div className="skeleton-card" style={{ animationDelay: delay + "s" }}>
      <div style={{ display: "flex", alignItems: "flex-start", gap: "12px" }}>
        <div className="skeleton-line" style={{ width: 28, height: 28, borderRadius: "8px", flexShrink: 0 }} />
        <div style={{ flex: 1 }}>
          <div className="skeleton-line" style={{ width: "70%", marginBottom: "8px" }} />
          <div className="skeleton-line" style={{ width: "100%", marginBottom: "6px" }} />
          <div className="skeleton-line" style={{ width: "45%", marginBottom: "6px" }} />
          <div className="skeleton-line" style={{ width: "30%" }} />
        </div>
      </div>
    </div>
  );
}

export default function DiscoverScreen() {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState(null);
  const [query, setQuery] = useState("tonight");
  const [category, setCategory] = useState(null);
  const [loadingMsg, setLoadingMsg] = useState(LOADING_MESSAGES[0]);
  const [loadingEmoji, setLoadingEmoji] = useState(DISCOVER_EMOJI[0]);
  const searchCount = useRef(0);
  const shownNames = useRef([]);
  const msgInterval = useRef(null);
  const abortRef = useRef(null);

  // Abort in-flight fetch on unmount
  useEffect(() => {
    return () => { if (abortRef.current) abortRef.current.abort(); };
  }, []);

  useEffect(() => {
    if (loading) {
      let idx = 0;
      setLoadingMsg(LOADING_MESSAGES[0]);
      setLoadingEmoji(DISCOVER_EMOJI[0]);
      msgInterval.current = setInterval(() => {
        idx = (idx + 1) % LOADING_MESSAGES.length;
        setLoadingMsg(LOADING_MESSAGES[idx]);
        setLoadingEmoji(DISCOVER_EMOJI[idx % DISCOVER_EMOJI.length]);
      }, 2500);
    } else {
      if (msgInterval.current) clearInterval(msgInterval.current);
    }
    return () => { if (msgInterval.current) clearInterval(msgInterval.current); };
  }, [loading]);

  const searchEvents = async () => {
    if (abortRef.current) abortRef.current.abort();
    const controller = new AbortController();
    abortRef.current = controller;
    const timeout = setTimeout(() => controller.abort(), 45000);

    setLoading(true);
    setSearched(true);
    setError(null);

    // Rotate variety hint each search to bust cache and push for diverse results
    const varietyHint = VARIETY_HINTS[searchCount.current % VARIETY_HINTS.length];
    searchCount.current++;

    // Build category-aware prompt
    const catInfo = category ? CATEGORIES.find((c) => c.id === category) : null;
    const catClause = catInfo
      ? "Focus specifically on " + catInfo.label.toLowerCase() + " events. All 6 results should be " + catInfo.label.toLowerCase() + " or closely related."
      : "Include a diverse mix: theater/shows, museum exhibits, live music, food events, comedy, and seasonal events for " + getSeason() + ".";

    // Build avoid list from previously shown events
    const avoidClause = shownNames.current.length > 0
      ? "\n\nDo NOT suggest any of these previously shown events: " + shownNames.current.slice(-30).join(", ") + "."
      : "";

    // Timestamp makes each request unique to prevent server-side caching
    const prompt = "Today is " + formatDate(new Date()) + " (search ID: " + Date.now() + "). Search the web for NYC events happening " + query + " (" + getDateRangeLabel(query) + "). " + catClause + "\n\n" + varietyHint + "\n\nSEARCH STRATEGY: Do NOT just search \"NYC events\" — that only surfaces SEO-heavy aggregators. Instead, search for specific neighborhoods and venue types, e.g. \"Bushwick warehouse party\", \"East Village comedy tonight\", \"Williamsburg gallery opening\", \"Harlem jazz this week\". Mix broad and specific searches to find what a real New Yorker would actually go to — the kind of stuff you'd hear about from a friend, a neighborhood Instagram, or a Nonsense NYC email.\n\nSOURCE DIVERSITY: Do NOT pull most results from Time Out, Eventbrite, or any single aggregator. At most 1 of 6 from any one source. Search direct venue websites, neighborhood blogs (BKlyner, EV Grieve, Gothamist, The Infatuation, Nonsense NYC, Secret NYC), cultural org sites, and venue pages. Prefer the event's own website over a listing page." + avoidClause + "\n\nReturn exactly 6 items. Skip long-running tourist staples (Sleep No More, generic MoMA admission, etc.) unless something special is happening this specific timeframe. Include the url from your search results (event page, ticket page, or venue page) — empty string only if nothing appeared. Respond ONLY with a raw JSON array, no markdown: [{\"name\":\"...\",\"desc\":\"One sentence — what makes it worth going\",\"area\":\"Neighborhood\",\"cat\":\"Category\",\"cost\":\"Price or Free\",\"emoji\":\"...\",\"url\":\"https://... or empty string\"}]";

    try {
      const resp = await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        signal: controller.signal,
        body: JSON.stringify({
          model: "claude-haiku-4-5-20251001",
          max_tokens: 1800,
          system: "You are a hyper-local NYC events concierge — the friend who always knows what's happening. You read Nonsense NYC, follow venue Instagram stories, check community boards, and know the difference between tourist traps and actual local gems. You respond ONLY with a valid JSON array. Never explain, apologize, or add prose. If web search doesn't find specific events, draw on your knowledge of recurring NYC staples at specific venues (comedy at Union Hall, jazz at Smalls, DJs at Nowadays, readings at McNally Jackson, etc.). Always return exactly 6 items.",
          tools: [{ type: "web_search_20250305", name: "web_search" }],
          messages: [{ role: "user", content: prompt }],
        }),
      });
      clearTimeout(timeout);
      if (!resp.ok) {
        console.error("Discover API error", resp.status);
        setError("Search failed (status " + resp.status + "). Tap retry to try again.");
        setLoading(false);
        return;
      }
      const data = await resp.json();
      if (data.error) {
        setError(typeof data.error === "string" ? data.error : "Something went wrong. Tap retry.");
        setLoading(false);
        return;
      }
      const rawText = (data.content || []).map((b) => (b.type === "text" ? b.text : "")).join("");
      const cleaned = stripCites(rawText).replace(/```json|```/g, "").trim();
      const match = cleaned.match(/\[[\s\S]*\]/);
      if (match) {
        try {
          const parsed = JSON.parse(match[0]);
          const results = parsed.slice(0, 8).map((ev) => ({
            name: stripCites(ev.name || ""),
            desc: stripCites(ev.desc || ""),
            area: stripCites(ev.area || ""),
            cat: ev.cat || "Event",
            cost: ev.cost || "",
            emoji: ev.emoji || "🎉",
            url: cleanEventUrl(ev.url),
          })).filter((ev) => ev.name);
          setEvents(results);
          // Track shown names so next search avoids repeats
          shownNames.current = [...shownNames.current, ...results.map((ev) => ev.name)].slice(-60);
        } catch (e) {
          console.error("Discover JSON parse error:", e, match[0].slice(0, 300));
          setError("Couldn't read results. Tap retry.");
        }
      } else {
        console.warn("Discover: no JSON array in response. Raw:", rawText.slice(0, 300));
        setError("No results came back. Tap retry.");
      }
    } catch (err) {
      clearTimeout(timeout);
      if (err.name === "AbortError") {
        setError("Search timed out — slow connection? Tap retry.");
      } else {
        console.error("Discover fetch error:", err);
        setError("Connection failed. Check your signal and tap retry.");
      }
    }
    setLoading(false);
  };

  return (
    <div>
      <h2 style={{ fontSize: "24px", fontWeight: "400", margin: "0 0 4px", color: P.gold, fontFamily: serif }}>Discover NYC</h2>
      <p style={{ fontSize: "13px", color: P.textDim, margin: "0 0 6px", fontFamily: sans }}>Live events, shows & pop-ups</p>
      <p style={{ fontSize: "12px", color: P.accent, margin: "0 0 20px", fontFamily: sans }}>📅 {formatDate(new Date())}</p>
      <div role="listbox" aria-label="Timeframe" style={{ display: "flex", gap: "8px", marginBottom: "20px", flexWrap: "wrap" }}>
        {TIMEFRAMES.map((q) => (
          <button
            key={q}
            role="option"
            aria-selected={query === q}
            onClick={() => setQuery(q)}
            style={{ background: query === q ? P.goldDim : P.card, border: "1px solid " + (query === q ? "rgba(232,195,106,0.3)" : P.border), borderRadius: "20px", padding: "8px 14px", fontSize: "12px", fontFamily: sans, color: query === q ? P.gold : P.textDim, cursor: "pointer", textTransform: "capitalize" }}
          >
            {q}
          </button>
        ))}
      </div>
      {query && <p style={{ fontSize: "11px", color: P.textDim, margin: "-12px 0 16px", fontFamily: sans }}>{getDateRangeLabel(query)}</p>}
      <div style={{ marginBottom: "16px" }}>
        <p style={{ fontSize: "11px", color: P.textDim, fontFamily: sans, textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: "8px" }}>🎯 Category {category && <span style={{ color: P.gold, cursor: "pointer", textTransform: "none", letterSpacing: 0 }} onClick={() => setCategory(null)}>(clear)</span>}</p>
        <div style={{ display: "flex", gap: "6px", flexWrap: "wrap" }}>
          {CATEGORIES.map((c) => (
            <button
              key={c.id}
              onClick={() => setCategory(category === c.id ? null : c.id)}
              aria-pressed={category === c.id}
              style={{
                background: category === c.id ? P.goldDim : P.card,
                border: "1px solid " + (category === c.id ? "rgba(232,195,106,0.3)" : P.border),
                borderRadius: "20px", padding: "6px 12px", fontSize: "12px", fontFamily: sans,
                color: category === c.id ? P.gold : P.textDim, cursor: "pointer",
                transition: "all 0.15s ease",
              }}
            >
              {c.emoji} {c.label}
            </button>
          ))}
        </div>
      </div>
      <Btn primary onClick={searchEvents} disabled={loading} style={{ width: "100%", marginBottom: "20px" }}>{loading ? "Searching NYC..." : "🔍 Find Events"}</Btn>
      {loading && (
        <div>
          <div style={{ textAlign: "center", padding: "20px 0 24px" }} role="status" aria-label="Searching">
            <div style={{ fontSize: "32px", animation: "pulse 1s infinite", marginBottom: "10px", transition: "all 0.3s" }} aria-hidden="true">{loadingEmoji}</div>
            <p style={{ color: P.textDim, fontFamily: sans, fontSize: "14px", transition: "opacity 0.3s" }}>{loadingMsg}</p>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
            {[0, 0.1, 0.2, 0.3, 0.4, 0.5].map((d, i) => <SkeletonCard key={i} delay={d} />)}
          </div>
        </div>
      )}
      {!loading && error && (
        <div style={{ textAlign: "center", padding: "32px 20px", color: P.textDim, fontFamily: sans }}>
          <div style={{ fontSize: "28px", marginBottom: "12px" }} aria-hidden="true">😔</div>
          <p style={{ marginBottom: "16px", fontSize: "14px", lineHeight: 1.5 }}>{error}</p>
          <Btn primary onClick={searchEvents} style={{ padding: "12px 32px", fontSize: "14px" }}>🔄 Retry</Btn>
        </div>
      )}
      {!loading && !error && searched && events.length === 0 && (
        <div style={{ textAlign: "center", padding: "40px", color: P.textDim, fontFamily: sans }}>No events found — try another timeframe!</div>
      )}
      <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
        {events.map((ev, i) => {
          const hasUrl = ev.url && ev.url.startsWith("http");
          const openEvent = () => {
            if (hasUrl) {
              window.open(ev.url, "_blank", "noopener,noreferrer");
            } else {
              window.open("https://www.google.com/search?q=" + encodeURIComponent(ev.name + " NYC " + ev.area + " tickets"), "_blank", "noopener,noreferrer");
            }
          };
          const shareEvent = (e) => {
            e.stopPropagation();
            const lines = [
              (ev.emoji || "") + " " + ev.name + " — " + ev.area,
              ev.cost || "",
              ev.desc,
              hasUrl ? ev.url : "",
            ].filter(Boolean).join("\n");
            if (navigator.share) {
              navigator.share({ title: ev.name, text: lines, url: hasUrl ? ev.url : undefined }).catch(() => {});
            } else {
              navigator.clipboard.writeText(lines).then(() => {
                const btn = e.currentTarget;
                const orig = btn.textContent;
                btn.textContent = "✓ Copied";
                setTimeout(() => { btn.textContent = orig; }, 1500);
              }).catch(() => {});
            }
          };
          return (
            <div
              key={ev.name + '-' + i}
              onClick={openEvent}
              role="link"
              tabIndex={0}
              aria-label={`${ev.name} — ${ev.area}. ${hasUrl ? "Opens event website." : "Searches for event."}`}
              onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openEvent(); } }}
              style={{ background: P.card, border: "1px solid " + P.border, borderRadius: "16px", padding: "16px 18px", cursor: "pointer", transition: "all 0.2s", animation: `tabFadeIn 0.4s ease ${i * 0.06}s both` }}
            >
              <div style={{ display: "flex", alignItems: "flex-start", gap: "12px" }}>
                <span style={{ fontSize: "28px", flexShrink: 0 }} aria-hidden="true">{ev.emoji || "🎉"}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: sans, fontSize: "15px", color: P.text, fontWeight: "600", marginBottom: "4px" }}>{ev.name}</div>
                  <div style={{ fontFamily: sans, fontSize: "13px", color: P.textDim, lineHeight: 1.5, marginBottom: "6px" }}>{ev.desc}</div>
                  <div style={{ display: "flex", gap: "8px", flexWrap: "wrap", alignItems: "center" }}>
                    <span style={{ fontSize: "11px", fontFamily: sans, color: P.accent }}>📍 {ev.area}</span>
                    {ev.cost && <span style={{ fontSize: "11px", fontFamily: sans, color: P.textDim }}>💰 {ev.cost}</span>}
                    <span style={{ fontSize: "11px", fontFamily: sans, color: P.textDim }}>{ev.cat}</span>
                  </div>
                </div>
                <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: "8px", flexShrink: 0 }}>
                  <span style={{ fontSize: "12px", color: P.gold, fontFamily: sans }}>{hasUrl ? "View ↗" : "Search ↗"}</span>
                  <button
                    onClick={shareEvent}
                    aria-label={"Share " + ev.name}
                    style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px", padding: "4px 10px", fontSize: "11px", color: P.textDim, fontFamily: sans, cursor: "pointer", transition: "all 0.15s" }}
                  >📤 Share</button>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
