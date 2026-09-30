import { http } from '@kit.NetworkKit';
import { buildAiApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';

interface NodeAiStatusPayload {
  provider?: string;
  model?: string;
  configured?: boolean;
  status?: string;
  nodeAvailable?: boolean;
  mode?: string;
  nodeStatus?: string;
  nodeBaseUrl?: string;
  message?: string;
}

export interface NodeAiStatus {
  available: boolean;
  mode: string;
  nodeStatus: string;
  nodeBaseUrl: string;
  badgeText: string;
  statusText: string;
  detail: string;
}

export function createDefaultNodeAiStatus(): NodeAiStatus {
  const status: NodeAiStatus = {
    available: false,
    mode: 'unknown',
    nodeStatus: 'unknown',
    nodeBaseUrl: '',
    badgeText: '未检测',
    statusText: 'AI 引擎：未检测',
    detail: '暂未获取 Spring Boot AI 状态。'
  };
  return status;
}

export function buildNodeAiStatusFromPayload(payload: string): NodeAiStatus {
  try {
    const data = JSON.parse(payload) as NodeAiStatusPayload;
    if (data.provider) {
      const available = data.status === 'available';
      const label = data.provider === 'deepseek' ? 'DeepSeek' : '本地模型';
      return {
        available,
        mode: data.provider,
        nodeStatus: data.status || 'not_checked',
        nodeBaseUrl: '',
        badgeText: available ? `${label} 在线` : data.configured ? '等待模型验证' : '模型未配置',
        statusText: `AI 引擎：${label} · ${data.model || ''}`,
        detail: data.message || (data.configured ? '已配置，等待实际请求验证' : '请配置后端模型密钥')
      };
    }
    const nodeBaseUrl = data.nodeBaseUrl ? data.nodeBaseUrl : '';
    if (data.nodeAvailable === true) {
      const onlineStatus: NodeAiStatus = {
        available: true,
        mode: data.mode ? data.mode : 'node-ai',
        nodeStatus: data.nodeStatus ? data.nodeStatus : 'ok',
        nodeBaseUrl,
        badgeText: 'Node AI 在线',
        statusText: 'AI 引擎：Node LangGraph',
        detail: `LLM / Prompt / LangGraph 由 Node 内部服务提供，地址 ${nodeBaseUrl}`
      };
      return onlineStatus;
    }
    const fallbackStatus: NodeAiStatus = {
      available: false,
      mode: data.mode ? data.mode : 'springboot-fallback',
      nodeStatus: data.nodeStatus ? data.nodeStatus : 'unavailable',
      nodeBaseUrl,
      badgeText: '兜底中',
      statusText: 'AI 引擎：Spring Boot 兜底',
      detail: `Node AI 未在线，当前由 Spring Boot 规则兜底。配置地址 ${nodeBaseUrl}`
    };
    return fallbackStatus;
  } catch (err) {
    return createDefaultNodeAiStatus();
  }
}

export function fetchNodeAiStatus(): Promise<NodeAiStatus> {
  const config = getApiConfig();
  const request = http.createHttp();
  return request.request(buildAiApiUrl(config.aiStatusPath), {
    method: http.RequestMethod.GET,
    header: buildAuthorizedJsonHeaders(),
    connectTimeout: config.timeoutMs,
    readTimeout: config.timeoutMs
  }).then((response: http.HttpResponse) => {
    request.destroy();
    if (response.responseCode < 200 || response.responseCode >= 300) {
      return createDefaultNodeAiStatus();
    }
    return buildNodeAiStatusFromPayload(`${response.result}`);
  }).catch(() => {
    request.destroy();
    return createDefaultNodeAiStatus();
  });
}
