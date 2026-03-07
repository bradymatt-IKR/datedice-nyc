export const ALLOWED_MODELS = new Set([
  'claude-sonnet-4-6',
  'claude-sonnet-4-5-20241022',
  'claude-haiku-4-5-20251001',
]);

export function validateBody(body) {
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

export function sanitizeBody(body, { stream = false } = {}) {
  const clean = {
    model: body.model,
    max_tokens: Math.min(body.max_tokens, 2000),
    messages: body.messages.map((m) => ({ role: m.role, content: m.content })),
  };
  if (stream) clean.stream = true;
  if (body.tools) clean.tools = body.tools;
  if (body.system && typeof body.system === 'string') clean.system = body.system;
  return clean;
}

/** Return CORS origin — restrict to app domain + Vercel previews + localhost */
export function getAllowedOrigin(req) {
  const origin = req.headers?.origin || '';
  if (origin.endsWith('.vercel.app') || origin.includes('localhost') || origin.includes('127.0.0.1')) {
    return origin;
  }
  return 'https://datedice-nyc.vercel.app';
}
