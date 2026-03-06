import { useState, useEffect, useRef } from 'react';
import { P, sans, serif, LOADING_MESSAGES } from '../data/constants.js';
import { API_URL, stripCites } from '../utils/api.js';
import { formatDate, getDateRangeLabel, getSeason } from '../utils/date.js';
import Btn from './Btn.jsx';

const TIMEFRAMES = ["tonight", "this week", "this weekend", "next week"];
const DISCOVER_EMOJI = ["🗽", "🎭", "🎶", "🎨", "🌃", "🎪", "🎷", "🏙"];

// Blocked spam/SEO/redirect domains that appear in web search results
const BLOCKED_DOMAINS = [
  "searchhounds.com", "addoor.co", "clicktracker.com", "trovit.com",
  "startpage.com", "searchencrypt.com", "duckduckgo.com", "google.com",
  "bing.com", "yahoo.com", "baidu.com", "yandex.com",
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
  const [loadingMsg, setLoadingMsg] = useState(LOADING_MESSAGES[0]);
  const [loadingEmoji, setLoadingEmoji] = useState(DISCOVER_EMOJI[0]);
  const msgInterval = useRef(null);
  const abortRef = useRef(null);

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
    try {
      const resp = await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        signal: controller.signal,
        body: JSON.stringify({
          model: "claude-haiku-4-5-20251001",
          max_tokens: 1500,
          tools: [{ type: "web_search_20250305", name: "web_search" }],
          messages: [{
            role: "user",
            content: "Today is " + formatDate(new Date()) + ". Search the web for NYC events and list exactly 5 specific events, shows, exhibits, performances, or experiences happening " + query + " (" + getDateRangeLabel(query) + "). Include a mix: theater/shows, museum exhibits, live music, and seasonal events for " + getSeason() + ". You MUST return exactly 5 items. For each event, include the url field with the best matching webpage from your search results (event page, ticket page, or venue page). Use empty string ONLY if no relevant page appeared in results. Respond ONLY with a raw JSON array, no markdown, no backticks: [{\"name\":\"...\",\"desc\":\"One sentence description\",\"area\":\"Neighborhood\",\"cat\":\"Category\",\"cost\":\"Price or Free\",\"emoji\":\"...\",\"url\":\"https://... or empty string\"}]",
          }],
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
          setEvents(parsed.slice(0, 6).map((ev) => ({
            name: stripCites(ev.name || ""),
            desc: stripCites(ev.desc || ""),
            area: stripCites(ev.area || ""),
            cat: ev.cat || "Event",
            cost: ev.cost || "",
            emoji: ev.emoji || "🎉",
            url: cleanEventUrl(ev.url),
          })).filter((ev) => ev.name));
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
      <Btn primary onClick={searchEvents} disabled={loading} style={{ width: "100%", marginBottom: "20px" }}>{loading ? "Searching NYC..." : "🔍 Find Events"}</Btn>
      {loading && (
        <div>
          <div style={{ textAlign: "center", padding: "20px 0 24px" }} role="status" aria-label="Searching">
            <div style={{ fontSize: "32px", animation: "pulse 1s infinite", marginBottom: "10px", transition: "all 0.3s" }} aria-hidden="true">{loadingEmoji}</div>
            <p style={{ color: P.textDim, fontFamily: sans, fontSize: "14px", transition: "opacity 0.3s" }}>{loadingMsg}</p>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
            {[0, 0.1, 0.2, 0.3, 0.4].map((d, i) => <SkeletonCard key={i} delay={d} />)}
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
              window.open(ev.url, "_blank", "noopener");
            } else {
              window.open("https://www.google.com/search?q=" + encodeURIComponent(ev.name + " NYC " + ev.area + " tickets"), "_blank", "noopener");
            }
          };
          return (
            <div
              key={i}
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
                  <div style={{ display: "flex", gap: "8px", flexWrap: "wrap" }}>
                    <span style={{ fontSize: "11px", fontFamily: sans, color: P.accent }}>📍 {ev.area}</span>
                    {ev.cost && <span style={{ fontSize: "11px", fontFamily: sans, color: P.textDim }}>💰 {ev.cost}</span>}
                    <span style={{ fontSize: "11px", fontFamily: sans, color: P.textDim }}>{ev.cat}</span>
                  </div>
                </div>
                <span style={{ fontSize: "12px", color: P.gold, fontFamily: sans, flexShrink: 0 }}>{hasUrl ? "View ↗" : "Search ↗"}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
