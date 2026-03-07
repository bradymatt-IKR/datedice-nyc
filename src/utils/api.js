import { formatDate, getTimeOfDay, getSeason } from './date.js';

export const API_URL = window.DATEDICE_API_URL || "/api/search";
const STREAM_URL = window.DATEDICE_STREAM_URL || "/api/stream";

export function stripCites(str) {
  if (typeof str !== "string") return str;
  return str.replace(/<cite[^>]*>([\s\S]*?)<\/cite>/gi, "$1").replace(/<\/?cite[^>]*>/gi, "").trim();
}

export function cleanResult(obj) {
  if (!obj || typeof obj !== "object") return obj;
  const out = {};
  Object.keys(obj).forEach((k) => {
    out[k] = typeof obj[k] === "string" ? stripCites(obj[k]) : obj[k];
  });
  return out;
}

function buildPrompt(type, filters, usedNames) {
  const { timeOfDay, weather, vibe, budget, duration, neighborhood, cuisine, activityType } = filters;
  const season = getSeason();
  const today = formatDate(new Date());
  const avoidList = (usedNames || []).slice(-40).join(", ");
  const neighborhoodStr = Array.isArray(neighborhood) && neighborhood.length > 0 ? neighborhood.join(", ") : (neighborhood || "anywhere in NYC or nearby");
  const jsonNote = "\n\nRespond with ONLY a raw JSON object — no markdown, no backticks, no extra text.";

  if (type === "food") {
    const cuisineStr = cuisine || "any cuisine — surprise us";
    return "You are a NYC food expert with deep knowledge of every neighborhood's restaurant scene. Suggest ONE specific real, currently-operating restaurant, bar, café, or food experience matching:\n- Neighborhood: " + neighborhoodStr + "\n- Cuisine: " + cuisineStr + "\n- Time: " + (timeOfDay || "any") + "\n- Weather: " + (weather || "any") + " (cozy/indoor for cold/rain; outdoor/rooftop for warm/sunny)\n- Vibe: " + (vibe || "any") + "\n- Budget: " + (budget || "any") + " (Free=free events, Under $50=casual, $50-150=mid-range, $150-300=upscale, Splurge=$300+/person)\n- Duration: " + (duration || "any") + "\n- Season: " + season + " · Today: " + today + "\n" + (avoidList ? "Do NOT suggest: " + avoidList + "\n" : "") + "\n- For bookingUrl: ONLY use a URL that appeared in your web search results. Copy the exact URL from search results — do NOT guess, construct, or fabricate URLs. Use empty string if no relevant booking page appeared in results or if walk-in only." + jsonNote + '\n{"name":"...","desc":"One vivid sentence — what makes it special and what to order","area":"Neighborhood","address":"Full street address","cat":"Food & Drink","priceRange":"$/$$/$$$/$$$$","cuisine":"type","emoji":"🍽","tip":"One insider tip","bookingUrl":"exact URL from search results or empty string","bookingPlatform":"Resy|OpenTable|Tock|Website|WalkIn"}';
  }

  const actTypeStr = activityType || "any activity or experience";
  return "You are a NYC experiences expert with deep knowledge of museums, shows, parks, events, classes, and hidden gems. Suggest ONE specific real, currently-available experience matching:\n- Type: " + actTypeStr + "\n- Neighborhood: " + neighborhoodStr + "\n- Time: " + (timeOfDay || "any") + "\n- Weather: " + (weather || "any") + " (indoor for rain/cold; outdoor for sunny)\n- Vibe: " + (vibe || "any") + "\n- Budget: " + (budget || "any") + " (Free, Under $50, $50-150, $150-300, Splurge=$300+)\n- Duration: " + (duration || "any") + "\n- Season: " + season + " · Today: " + today + "\n" + (avoidList ? "Do NOT suggest: " + avoidList + "\n" : "") + "\n- For bookingUrl: ONLY use a URL that appeared in your web search results. Copy the exact URL from search results — do NOT guess, construct, or fabricate URLs. Use empty string if no relevant booking page appeared in results or if free/no-booking." + jsonNote + '\n{"name":"...","desc":"One vivid sentence — what makes it special and why it\'s great for a date","area":"Neighborhood or location","address":"Address or general area","cat":"Activity","emoji":"✨","tip":"One insider tip","bookingUrl":"exact URL from search results or empty string","bookingPlatform":"Eventbrite|Website|Ticketmaster|NoReservation"}';
}

function parseResponse(data) {
  if (data.error) {
    console.error("API error:", data.error);
    return null;
  }
  const raw = (data.content || []).map((b) => (b.type === "text" ? b.text : "")).join("");
  const clean = stripCites(raw).replace(/```json|```/g, "").trim();
  const m = clean.match(/\{[\s\S]*\}/);
  if (m) {
    try { return cleanResult(JSON.parse(m[0])); } catch { return null; }
  }
  console.warn("No JSON in response:", raw.slice(0, 200));
  return null;
}

// ── Streaming fetch ──
export async function fetchSuggestionStream(type, filters, usedNames, onText) {
  const prompt = buildPrompt(type, filters, usedNames);
  try {
    const resp = await fetch(STREAM_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 1000,
        tools: [{ type: "web_search_20250305", name: "web_search" }],
        messages: [{ role: "user", content: prompt }],
        stream: true,
      }),
    });

    if (!resp.ok) {
      console.error("Stream API", resp.status);
      return null;
    }

    const reader = resp.body.getReader();
    const decoder = new TextDecoder();
    let accumulated = "";
    let buffer = "";

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split("\n");
      buffer = lines.pop(); // Keep incomplete line in buffer

      for (const line of lines) {
        if (!line.startsWith("data: ")) continue;
        const payload = line.slice(6).trim();
        if (payload === "[DONE]") break;

        try {
          const event = JSON.parse(payload);
          if (event.type === "content_block_delta" && event.delta?.type === "text_delta") {
            accumulated += event.delta.text;
            if (onText) onText(accumulated);
          }
        } catch {
          // Skip malformed events
        }
      }
    }

    const clean = stripCites(accumulated).replace(/```json|```/g, "").trim();
    const m = clean.match(/\{[\s\S]*\}/);
    if (m) {
      try { return cleanResult(JSON.parse(m[0])); } catch { return null; }
    }
    return null;
  } catch (err) {
    console.error("fetchSuggestionStream:", err);
    return null;
  }
}

// ── Standard (non-streaming) fetch ──
export async function fetchSuggestion(type, filters, usedNames) {
  const prompt = buildPrompt(type, filters, usedNames);
  try {
    const resp = await fetch(API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 1000,
        tools: [{ type: "web_search_20250305", name: "web_search" }],
        messages: [{ role: "user", content: prompt }],
      }),
    });
    if (!resp.ok) {
      console.error("API", resp.status, await resp.text().catch(() => ""));
      return null;
    }
    const data = await resp.json();
    return parseResponse(data);
  } catch (err) {
    console.error("fetchSuggestion:", err);
    return null;
  }
}

