const { getLlmConfig } = require('./llmConfig');
const { buildRuleBasedAssistantReply } = require('./ruleAssistant');

const DEFAULT_DISCLAIMER = '本建议不能替代医生诊断，若症状持续或加重，请及时就医。';

function normalizeHeaderToken(value) {
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

function buildLlmRequestHeaders(config) {
  const headers = {
    'Content-Type': 'application/json'
  };
  const apiKey = normalizeHeaderToken(config && config.apiKey);
  if (apiKey.length > 0) {
    headers.Authorization = `Bearer ${apiKey}`;
  }
  return headers;
}

function buildWeatherSummary(weather) {
  if (!weather || typeof weather !== 'object') {
    return '当前天气：未获取';
  }
  const city = typeof weather.city === 'string' && weather.city.length > 0 ? weather.city : '当前位置';
  const condition = typeof weather.condition === 'string' && weather.condition.length > 0 ? weather.condition : '未知';
  const temperature = typeof weather.temperature === 'string' && weather.temperature.length > 0 ? weather.temperature : '--℃';
  const humidity = typeof weather.humidity === 'string' && weather.humidity.length > 0 ? weather.humidity : '--';
  const riskLevel = typeof weather.riskLevel === 'string' && weather.riskLevel.length > 0 ? weather.riskLevel : '天气未明';
  const sourceLabel = typeof weather.sourceLabel === 'string' && weather.sourceLabel.length > 0 ? weather.sourceLabel : '未知来源';
  return [
    `当前天气：${city}，${condition}，${temperature}，湿度${humidity}`,
    `天气风险：${riskLevel}`,
    `天气来源：${sourceLabel}`,
    '请结合当前温度、湿度和天气风险调整饮食、运动、睡眠和提醒建议。'
  ].join('\n');
}

function buildLlmPrompt(body) {
  const message = typeof body.message === 'string' && body.message.trim().length > 0
    ? body.message.trim()
    : '日常调理';
  const profile = body.profile || {};
  const memoryContext = body.memoryContext || {};
  const constitution = typeof memoryContext.constitutionName === 'string' && memoryContext.constitutionName.length > 0
    ? memoryContext.constitutionName
    : profile.constitution && typeof profile.constitution.name === 'string'
    ? profile.constitution.name
    : '平和质';
  const history = Array.isArray(body.history) ? body.history.slice(-6) : [];
  const historyLines = history.map((item) => {
    const role = item.role === 'assistant' ? '助手' : '用户';
    const content = typeof item.content === 'string' ? item.content : '';
    return `${role}：${content}`;
  }).filter((line) => line.trim().length > 3);
  const profileSummary = typeof memoryContext.profileSummary === 'string' && memoryContext.profileSummary.length > 0
    ? `健康档案摘要：\n${memoryContext.profileSummary}`
    : buildProfileSummary(profile);
  const historySummary = typeof memoryContext.historySummary === 'string' && memoryContext.historySummary.length > 0
    ? `最近对话：\n${memoryContext.historySummary}`
    : historyLines.length > 0 ? `最近对话：\n${historyLines.join('\n')}` : '最近对话：无';

  return [
    '你是一个谨慎的中医养生助手，只能提供日常养生建议，不能诊断疾病。',
    '请严格返回 JSON，不要返回 Markdown。',
    'JSON 字段必须包含 reply, source, riskLevel, suggestions, disclaimer。',
    'riskLevel 只能是 normal 或 urgent。',
    '如果用户提到胸痛、呼吸困难、晕倒、剧烈头痛等风险信号，riskLevel 必须为 urgent，并建议及时就医。',
    `用户体质倾向：${constitution}`,
    profileSummary,
    historySummary,
    buildWeatherSummary(body.weather),
    `用户问题：${message}`
  ].join('\n');
}

function buildProfileSummary(profile) {
  const lines = [];
  if (Array.isArray(profile.tongueNotes) && profile.tongueNotes.length > 0) {
    const note = profile.tongueNotes[0];
    lines.push(`最近舌象：${note.color || '未记录'}、${note.coating || '未记录'}、${note.dryness || '未记录'}`);
  } else {
    lines.push('最近舌象：未记录');
  }

  if (Array.isArray(profile.healthIndicators) && profile.healthIndicators.length > 0) {
    const indicator = profile.healthIndicators[0];
    lines.push(`最近指标：${indicator.name || '指标'} ${indicator.value || ''}${indicator.unit || ''}`);
  } else {
    lines.push('最近指标：未记录');
  }

  if (Array.isArray(profile.reminderPreferences) && profile.reminderPreferences.length > 0) {
    const enabledCount = profile.reminderPreferences.filter((item) => item.enabled).length;
    lines.push(`提醒开启：${enabledCount}/${profile.reminderPreferences.length}`);
  } else {
    lines.push('提醒开启：未记录');
  }

  return `健康档案摘要：\n${lines.join('\n')}`;
}

async function requestDeepSeekAssistantReply(body, env = process.env) {
  const config = getLlmConfig(env);
  if (!config.enabled) {
    return undefined;
  }

  const response = await fetch(config.baseUrl, {
    method: 'POST',
    headers: buildLlmRequestHeaders(config),
    body: JSON.stringify({
      model: config.model,
      messages: [
        {
          role: 'user',
          content: buildLlmPrompt(body)
        }
      ],
      temperature: 0.4
    })
  });

  if (!response.ok) {
    return undefined;
  }

  const data = await response.json();
  const content = data && data.choices && data.choices[0] && data.choices[0].message
    ? data.choices[0].message.content
    : '';
  if (typeof content !== 'string' || content.trim().length === 0) {
    return undefined;
  }

  const parsed = parseLlmJsonContent(content);
  return normalizeLlmReply(parsed, body);
}

function parseLlmJsonContent(content) {
  const trimmed = content.trim();
  if (trimmed.startsWith('```')) {
    const withoutFence = trimmed
      .replace(/^```json\s*/i, '')
      .replace(/^```\s*/i, '')
      .replace(/```$/i, '')
      .trim();
    return JSON.parse(withoutFence);
  }

  try {
    return JSON.parse(trimmed);
  } catch (error) {
    const start = trimmed.indexOf('{');
    const end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return JSON.parse(trimmed.slice(start, end + 1));
    }
    throw error;
  }
}

function normalizeLlmReply(parsed, body) {
  const fallback = buildRuleBasedAssistantReply(body);
  const suggestions = Array.isArray(parsed.suggestions) && parsed.suggestions.length > 0
    ? parsed.suggestions
    : fallback.suggestions;
  const riskLevel = fallback.riskLevel === 'urgent'
    ? 'urgent'
    : (parsed.riskLevel === 'urgent' ? 'urgent' : 'normal');
  const reply = typeof parsed.reply === 'string' && parsed.reply.trim().length > 0
    ? parsed.reply.trim()
    : fallback.reply;
  const disclaimer = typeof parsed.disclaimer === 'string' && parsed.disclaimer.trim().length > 0
    ? parsed.disclaimer.trim()
    : DEFAULT_DISCLAIMER;

  return {
    reply,
    source: 'DeepSeek',
    riskLevel,
    suggestions,
    disclaimer
  };
}

module.exports = {
  buildLlmRequestHeaders,
  buildLlmPrompt,
  buildProfileSummary,
  buildWeatherSummary,
  normalizeLlmReply,
  parseLlmJsonContent,
  requestDeepSeekAssistantReply
};
