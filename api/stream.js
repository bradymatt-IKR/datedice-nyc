const ALLOWED_MODELS = new Set([
  'claude-sonnet-4-6',
  'claude-sonnet-4-5-20241022',
  'claude-haiku-4-5-20251001',
]);

function validateBody(body) {
  if (!body || typeof body !== 'object') return 'Request body must be a JSON object';
  if (typeof body.model !== 'string' || !ALLOWED_MODELS.has(body.model)) return 'Invalid model';
  if (typeof body.max_tokens !== 'number' || body.max_tokens < 1 || body.max_tokens > 2000) return 'max_tokens must be 1-2000';
  if (!Array.isArray(body.messages) || body.messages.length === 0) return 'messages must be a non-empty array';
  for (const msg of body.messages) {
    if (!msg || typeof msg.role !== 'string' || !msg.content) return 'Each message must have role and content';
    if (!['user', 'assistant'].includes(msg.role)) return 'Invalid message role';
  }
  if (body.tools && !Array.isArray(body.tools)) return 'tools must be an array';
  return null;
}

function sanitizeBody(body) {
  const clean = {
    model: body.model,
    max_tokens: Math.min(body.max_tokens, 2000),
    messages: body.messages.map((m) => ({ role: m.role, content: m.content })),
    stream: true,
  };
  if (body.tools) clean.tools = body.tools;
  if (body.system && typeof body.system === 'string') clean.system = body.system;
  return clean;
}

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    return res.status(200).end();
  }

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

  const cleanBody = sanitizeBody(req.body);

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

    if (!response.ok) {
      const errText = await response.text().catch(() => '');
      return res.status(response.status).json({ error: 'Anthropic API error: ' + response.status, detail: errText });
    }

    // Stream SSE to client
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('Access-Control-Allow-Origin', '*');

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
  } catch (error) {
    return res.status(500).json({ error: 'Failed to reach Anthropic API' });
  }
}
