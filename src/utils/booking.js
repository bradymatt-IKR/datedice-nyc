import { BLOCKED_DOMAINS } from './blockedDomains.js';

/** Validate a booking URL. Returns clean URL or empty string. */
function validateBookingUrl(raw) {
  if (!raw || typeof raw !== "string" || !raw.startsWith("http")) return "";
  try {
    const u = new URL(raw);
    const host = u.hostname.toLowerCase();

    // Block known spam / search engine domains
    if (BLOCKED_DOMAINS.some((d) => host.includes(d))) return "";

    // Block suspicious redirect/tracking params
    const params = u.search.toLowerCase();
    if (params.includes("oref=") || params.includes("psystem=")) return "";

    // Block obviously invalid TLDs or localhost
    if (host === "localhost" || host.endsWith(".local") || host.endsWith(".test")) return "";

    // Block IPs
    if (/^\d+\.\d+\.\d+\.\d+$/.test(host)) return "";

    return raw;
  } catch {
    return "";
  }
}

export function getBookingInfo(result) {
  const name = result.name || "";
  const platform = (result.bookingPlatform || "").toLowerCase();
  const modelUrl = validateBookingUrl(result.bookingUrl || "");
  const isRealUrl = modelUrl.startsWith("http") && modelUrl.length > 12;

  if (isRealUrl) {
    const label =
      platform === "resy" ? "Reserve on Resy" :
      platform === "opentable" ? "Reserve on OpenTable" :
      platform === "tock" ? "Reserve on Tock" :
      platform === "eventbrite" ? "Tickets on Eventbrite" :
      platform === "ticketmaster" ? "Tickets on Ticketmaster" :
      platform === "walkin" ? null :
      platform === "noreservation" ? null :
      "Book / Reserve";
    return label ? { url: modelUrl, label, platform } : null;
  }

  if (result.cat === "Food & Drink" || result.cat === "food") {
    const q = encodeURIComponent(name + " NYC");
    return {
      url: "https://www.opentable.com/s?term=" + q,
      label: "Find on OpenTable",
      platform: "opentable",
      isFallback: true,
    };
  }
  if (result.cat === "Activity" || result.cat === "Activities" || result.cat === "activity") {
    const q = encodeURIComponent(name + " NYC tickets");
    return {
      url: "https://www.google.com/search?q=" + q,
      label: "Find Tickets",
      platform: "google",
      isFallback: true,
    };
  }
  return null;
}
