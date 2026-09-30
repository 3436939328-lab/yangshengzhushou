import { http } from '@kit.NetworkKit';
import {
  buildAiApiUrl,
  buildApiUrlWithBase,
  getApiConfig,
  setRuntimeAiBaseUrl,
  uniqueCandidateAiBaseUrls
} from './ApiConfig';

export interface BackendStatus {
  available: boolean;
  mode: string;
  healthUrl: string;
}

interface HealthPayload {
  code?: number;
  success?: boolean;
  data?: string;
  status?: string;
  service?: string;
}

export function getBackendStatus(): BackendStatus {
  return {
    available: false,
    mode: '后端未连接',
    healthUrl: buildAiApiUrl(getApiConfig().healthPath)
  };
}

export function buildBackendStatusFromHealthPayload(payload: string): BackendStatus {
  const healthUrl = buildAiApiUrl(getApiConfig().healthPath);
  return buildBackendStatusFromHealthPayloadWithUrl(payload, healthUrl);
}

export function buildBackendStatusFromHealthPayloadWithUrl(payload: string, healthUrl: string): BackendStatus {
  let data: HealthPayload = {};
  try {
    data = JSON.parse(payload) as HealthPayload;
  } catch (error) {
    data = {};
  }
  const isNodeHealth = data.status === 'ok' && data.service === 'yangshengzhushou_db';
  const isSpringHealth = (data.success === true || data.code === 200) && data.data === 'ok';
  if (isNodeHealth || isSpringHealth) {
    return {
      available: true,
      mode: '后端可用',
      healthUrl
    };
  }
  return {
    available: false,
    mode: '后端未连接',
    healthUrl
  };
}

function requestBackendHealthAt(healthUrl: string): Promise<BackendStatus> {
  const config = getApiConfig();
  const request = http.createHttp();
  return request.request(healthUrl, {
    method: http.RequestMethod.GET,
    connectTimeout: config.timeoutMs,
    readTimeout: config.timeoutMs
  }).then((response: http.HttpResponse) => {
    request.destroy();
    if (response.responseCode < 200 || response.responseCode >= 300) {
      return getBackendStatus();
    }
    return buildBackendStatusFromHealthPayloadWithUrl(`${response.result}`, healthUrl);
  }).catch(() => {
    request.destroy();
    const fallbackStatus: BackendStatus = {
      available: false,
      mode: '后端未连接',
      healthUrl
    };
    return fallbackStatus;
  });
}

function checkCandidateBackendHealth(baseUrls: string[], index: number): Promise<BackendStatus> {
  if (index >= baseUrls.length) {
    return Promise.resolve(getBackendStatus());
  }
  const config = getApiConfig();
  const baseUrl = baseUrls[index];
  const healthUrl = buildApiUrlWithBase(baseUrl, config.healthPath);
  return requestBackendHealthAt(healthUrl).then((status: BackendStatus) => {
    if (status.available) {
      setRuntimeAiBaseUrl(baseUrl);
      return status;
    }
    return checkCandidateBackendHealth(baseUrls, index + 1);
  });
}

export function checkBackendHealth(): Promise<BackendStatus> {
  const config = getApiConfig();
  return requestBackendHealthAt(buildApiUrlWithBase(config.baseUrl, config.healthPath));
}
