import { http } from '@kit.NetworkKit';
import { HealthProfile } from '../model/ProfileModels';
import { ChatMessage, WeatherWellness, WellnessPlanItem } from '../model/WellnessModels';
import { buildAiApiUrl, getApiConfig } from './ApiConfig';
import { checkBackendHealth, getBackendStatus } from './BackendStatusService';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';
import { newRequestId, rewardRequest } from './RewardsService';

export interface AssistantReplyResult {
  content: string;
  source: string;
  riskLevel: string;
  suggestions: string[];
  plan: WellnessPlanItem[];
  disclaimer: string;
  targetUrl: string;
  healthUrl: string;
}

export interface BackendChatPayload {
  reply?: string;
  source?: string;
  riskLevel?: string;
  suggestions?: string[];
  plan?: WellnessPlanItem[];
  disclaimer?: string;
}

export interface ChatRecovery {
  requestId: string;
  status: string;
  reply?: BackendChatPayload;
  error?: string;
}

export function recoverChatReply(requestId: string): Promise<ChatRecovery> {
  return rewardRequest<ChatRecovery>(`/api/ai/chat/${encodeURIComponent(requestId)}`);
}

interface BackendChatHistoryItem {
  role: string;
  content: string;
}

export function buildBackendHistory(messages: ChatMessage[]): BackendChatHistoryItem[] {
  const history: BackendChatHistoryItem[] = [];
  const startIndex = messages.length > 6 ? messages.length - 6 : 0;
  for (let index = startIndex; index < messages.length; index++) {
    history.push({
      role: messages[index].role,
      content: messages[index].content
    });
  }
  return history;
}

export function buildAssistantRequestPayload(
  question: string,
  profile: HealthProfile,
  messages: ChatMessage[] = [],
  weather?: WeatherWellness,
  requestId: string = newRequestId()
): string {
  return JSON.stringify({
    message: question,
    requestId,
    profile,
    weather,
    history: buildBackendHistory(messages)
  });
}

export function buildUnavailableAssistantReply(question: string): AssistantReplyResult {
  const config = getApiConfig();
  const backendStatus = getBackendStatus();
  return {
    content: '暂未收到回答，请检查网络后重试。',
    source: '大模型未连接',
    riskLevel: 'unavailable',
    suggestions: [],
    plan: [],
    disclaimer: '',
    targetUrl: buildAiApiUrl(config.aiChatPath),
    healthUrl: backendStatus.healthUrl
  };
}

export function requestAssistantReply(question: string, profile: HealthProfile): AssistantReplyResult {
  return buildUnavailableAssistantReply(question);
}

export function buildAssistantReplyFromBackendPayload(payload: string): AssistantReplyResult {
  const config = getApiConfig();
  const backendStatus = getBackendStatus();
  const data = JSON.parse(payload) as BackendChatPayload;
  return {
    content: data.reply ? data.reply : '',
    source: data.source ? data.source : '后端',
    riskLevel: data.riskLevel ? data.riskLevel : 'normal',
    suggestions: data.suggestions ? data.suggestions : [],
    plan: data.plan ? data.plan : [],
    disclaimer: data.disclaimer ? data.disclaimer : '',
    targetUrl: buildAiApiUrl(config.aiChatPath),
    healthUrl: backendStatus.healthUrl
  };
}

export function requestAssistantReplyRemoteFirst(
  question: string,
  profile: HealthProfile,
  messages: ChatMessage[] = [],
  weather?: WeatherWellness,
  requestId: string = newRequestId()
): Promise<AssistantReplyResult> {
    const config = getApiConfig();
    const request = http.createHttp();
    const body = buildAssistantRequestPayload(question, profile, messages, weather, requestId);

    return request.request(buildAiApiUrl(config.aiChatPath), {
      method: http.RequestMethod.POST,
      header: buildAuthorizedJsonHeaders(),
      extraData: body,
      connectTimeout: config.timeoutMs,
      readTimeout: config.aiTimeoutMs
    }).then((response: http.HttpResponse) => {
      request.destroy();
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
      }
      return buildAssistantReplyFromBackendPayload(`${response.result}`);
    }).catch((error: Error) => {
      request.destroy();
      return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
    });
}
