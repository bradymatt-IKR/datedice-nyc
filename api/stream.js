import { validateBody, sanitizeBody, getAllowedOrigin } from './_shared.js';

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

  const validationError = validateBody(req.body);
  if (validationError) {
    return res.status(400).json({ error: validationError });
  }

  const cleanBody = sanitizeBody(req.body, { stream: true });

  // Retry up to 3 times on 429/529 with exponential backoff
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

      if ((response.status === 429 || response.status === 529) && attempt < 2) {
        await sleep((attempt + 1) * 2000);
        continue;
      }

      if (!response.ok) {
        const errText = await response.text().catch(() => '');
        return res.status(response.status).json({ error: 'Anthropic API error: ' + response.status, detail: errText });
      }

      // Stream SSE to client
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');

      const reader = response.body.getReader();
      const decoder = new TextDecoder();

      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          const chunk = decoder.decode(value, { stream: true });
          res.write(chunk);
        }
      } catch (streamErr) {
        console.error('Stream read error:', streamErr);
      }

      res.end();
      return;
    } catch (error) {
      if (attempt === 2) {
        return res.status(500).json({ error: 'Failed to reach Anthropic API' });
      }
      await sleep((attempt + 1) * 2000);
    }
  }

  return res.status(429).json({ error: 'Rate limited — please try again in a moment' });
}
