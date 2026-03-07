import { validateBody, sanitizeBody, getAllowedOrigin } from './_shared.js';

// Simple in-memory cache for warm function instances
const responseCache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

function getCacheKey(body) {
  const prompt = body.messages?.[0]?.content || '';
  return body.model + ':' + prompt.slice(0, 200) + ':' + prompt.slice(-60);
}

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

export default async function handler(req, res) {
  const origin = getAllowedOrigin(req);

  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    return res.status(200).end();
  }

  // Set CORS on ALL responses (not just success) so browsers don't swallow errors
  res.setHeader('Access-Control-Allow-Origin', origin);

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: 'ANTHROPIC_API_KEY not configured' });
  }

  // Validate input
  const validationError = validateBody(req.body);
  if (validationError) {
    return res.status(400).json({ error: validationError });
  }

  const cleanBody = sanitizeBody(req.body);

  // Check cache
  const cacheKey = getCacheKey(cleanBody);
  const cached = responseCache.get(cacheKey);
  if (cached && Date.now() - cached.ts < CACHE_TTL) {
    res.setHeader('X-Cache', 'HIT');
    return res.status(200).json(cached.data);
  }

  // Retry up to 3 times on 429 with exponential backoff
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify(cleanBody),
      });

      if (response.status === 429 && attempt < 2) {
        await sleep((attempt + 1) * 2000);
        continue;
      }

      const data = await response.json();

      // Cache successful responses
      if (response.status === 200) {
        responseCache.set(cacheKey, { data, ts: Date.now() });
        // Evict old entries
        if (responseCache.size > 100) {
          const oldest = responseCache.keys().next().value;
          responseCache.delete(oldest);
        }
      }

      return res.status(response.status).json(data);
    } catch (error) {
      if (attempt === 2) {
        return res.status(500).json({ error: 'Failed to reach Anthropic API' });
      }
      await sleep((attempt + 1) * 2000);
    }
  }

  return res.status(429).json({ error: 'Rate limited — please try again in a moment' });
}
