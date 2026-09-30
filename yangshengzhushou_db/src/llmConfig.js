function getLlmConfig(env = process.env) {
  const defaultDeepSeekBaseUrl = 'https://api.deepseek.com/chat/completions';
  const apiKey = normalizeEnvValue(env.DEEPSEEK_API_KEY || env.LOCAL_LLM_API_KEY || env.LLM_API_KEY || '');
  const localBaseUrl = normalizeEnvValue(env.LOCAL_LLM_BASE_URL || '');
  const configuredBaseUrl = normalizeEnvValue(env.DEEPSEEK_BASE_URL || env.LLM_BASE_URL || '');
  const baseUrl = localBaseUrl || configuredBaseUrl || defaultDeepSeekBaseUrl;
  const isExplicitLocal = localBaseUrl.length > 0;
  const hasCustomBaseUrl = configuredBaseUrl.length > 0 && configuredBaseUrl !== defaultDeepSeekBaseUrl;
  return {
    enabled: apiKey.length > 0 || isExplicitLocal || hasCustomBaseUrl,
    provider: isExplicitLocal || (hasCustomBaseUrl && apiKey.length === 0) ? 'local-openai-compatible' : 'deepseek',
    model: normalizeEnvValue(env.LOCAL_LLM_MODEL || env.DEEPSEEK_MODEL || env.LLM_MODEL || 'deepseek-chat'),
    apiKey,
    baseUrl
  };
}

function normalizeEnvValue(value) {
  const normalized = String(value || '').trim();
  if (normalized.length >= 2) {
    const first = normalized.charAt(0);
    const last = normalized.charAt(normalized.length - 1);
    if ((first === '"' && last === '"') || (first === "'" && last === "'")) {
      return normalized.substring(1, normalized.length - 1).trim();
    }
  }
  return normalized;
}

module.exports = {
  getLlmConfig,
  normalizeEnvValue
};
