export interface ApiConfig {
  baseUrl: string;
  authBaseUrl: string;
  aiBaseUrl: string;
  suggestionsBaseUrl: string;
  aiChatPath: string;
  aiStatusPath: string;
  authLoginPath: string;
  authRegisterPath: string;
  authSmsCodePath: string;
  authSmsLoginPath: string;
  authPasswordResetIdentifyPath: string;
  authPasswordResetPath: string;
  authMePath: string;
  suggestionsPath: string;
  weatherPath: string;
  healthArchiveCurrentPath: string;
  healthDetailCurrentPath: string;
  healthDetailQuestionnairePath: string;
  healthDetailIndicatorPath: string;
  healthDetailTonguePath: string;
  healthPath: string;
  timeoutMs: number;
  aiTimeoutMs: number;
  candidateBaseUrls: string[];
  candidateAiBaseUrls: string[];
}

const DEFAULT_API_BASE_URL: string = 'http://127.0.0.1:8181';
const DEFAULT_AI_BASE_URL: string = DEFAULT_API_BASE_URL;
let runtimeBaseUrl: string = DEFAULT_API_BASE_URL;
let runtimeAiBaseUrl: string = DEFAULT_AI_BASE_URL;

export function getApiConfig(): ApiConfig {
  return {
    baseUrl: runtimeBaseUrl,
    authBaseUrl: runtimeBaseUrl,
    aiBaseUrl: runtimeAiBaseUrl,
    suggestionsBaseUrl: runtimeAiBaseUrl,
    aiChatPath: '/api/ai/chat',
    aiStatusPath: '/api/ai/status',
    authLoginPath: '/api/auth/login',
    authRegisterPath: '/api/auth/register',
    authSmsCodePath: '/api/auth/sms-code',
    authSmsLoginPath: '/api/auth/sms-login',
    authPasswordResetIdentifyPath: '/api/auth/password-reset/identify',
    authPasswordResetPath: '/api/auth/password-reset',
    authMePath: '/api/auth/me',
    suggestionsPath: '/api/ai/suggestions',
    weatherPath: '/api/weather/current',
    healthArchiveCurrentPath: '/api/health-archive/current',
    healthDetailCurrentPath: '/api/health-detail/current',
    healthDetailQuestionnairePath: '/api/health-detail/questionnaire',
    healthDetailIndicatorPath: '/api/health-detail/indicator',
    healthDetailTonguePath: '/api/health-detail/tongue',
    healthPath: '/api/health',
    timeoutMs: 6000,
    aiTimeoutMs: 90000,
    candidateBaseUrls: [
      runtimeBaseUrl,
      DEFAULT_API_BASE_URL,
      'http://10.0.2.2:8181',
      'http://10.0.3.2:8181',
      'http://127.0.0.1:8181'
    ],
    candidateAiBaseUrls: [
      runtimeAiBaseUrl,
      DEFAULT_AI_BASE_URL,
      'http://10.0.2.2:8181',
      'http://10.0.3.2:8181',
      'http://127.0.0.1:8181'
    ]
  };
}

export function buildApiUrl(path: string): string {
  return `${getApiConfig().baseUrl}${path}`;
}

export function buildAuthApiUrl(path: string): string {
  return `${getApiConfig().authBaseUrl}${path}`;
}

export function buildAiApiUrl(path: string): string {
  return `${getApiConfig().aiBaseUrl}${path}`;
}

export function buildSuggestionApiUrl(path: string): string {
  return `${getApiConfig().suggestionsBaseUrl}${path}`;
}

export function buildApiUrlWithBase(baseUrl: string, path: string): string {
  return `${baseUrl}${path}`;
}

export function normalizeApiBaseUrl(baseUrl: string): string {
  let normalized = baseUrl.trim();
  if (!(normalized.indexOf('http://') === 0 || normalized.indexOf('https://') === 0)) {
    return '';
  }
  while (normalized.length > 0 && normalized.charAt(normalized.length - 1) === '/') {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

export function setRuntimeBaseUrl(baseUrl: string): void {
  const normalized = normalizeApiBaseUrl(baseUrl);
  if (normalized.length > 0) {
    runtimeBaseUrl = normalized;
    runtimeAiBaseUrl = normalized;
  }
}

export function setRuntimeAiBaseUrl(baseUrl: string): void {
  const normalized = normalizeApiBaseUrl(baseUrl);
  if (normalized.length > 0) {
    setRuntimeBaseUrl(normalized);
  }
}

export function uniqueCandidateBaseUrls(config: ApiConfig): string[] {
  const values: string[] = [];
  for (let index = 0; index < config.candidateBaseUrls.length; index++) {
    const item = config.candidateBaseUrls[index];
    if (values.indexOf(item) < 0) {
      values.push(item);
    }
  }
  return values;
}

export function uniqueCandidateAiBaseUrls(config: ApiConfig): string[] {
  const values: string[] = [];
  for (let index = 0; index < config.candidateAiBaseUrls.length; index++) {
    const item = config.candidateAiBaseUrls[index];
    if (values.indexOf(item) < 0) {
      values.push(item);
    }
  }
  return values;
}
