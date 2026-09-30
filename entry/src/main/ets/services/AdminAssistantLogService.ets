import { http } from '@kit.NetworkKit';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

interface ApiResponsePayload {
  success?: boolean;
  message?: string;
  data?: Object;
}

interface HealthQuestionPayload {
  id?: number;
  userId?: number;
  question?: string;
  answer?: string;
  status?: number;
  createTime?: string;
}

export interface AdminAssistantLogItem {
  id: string;
  userId: string;
  question: string;
  answer: string;
  status: number;
  statusText: string;
  createTime: string;
}

export interface AdminAssistantLogGroup {
  userId: string;
  totalCount: number;
  answeredCount: number;
  latestQuestion: string;
  latestTime: string;
  logs: AdminAssistantLogItem[];
}

function isNewerLog(candidate: AdminAssistantLogItem, currentQuestion: string, currentTime: string): boolean {
  if (currentQuestion.length === 0 && currentTime.length === 0) {
    return true;
  }
  if (candidate.createTime.length > 0 && currentTime.length > 0 && candidate.createTime !== currentTime) {
    return candidate.createTime > currentTime;
  }
  if (candidate.createTime.length > 0 && currentTime.length === 0) {
    return true;
  }
  return false;
}

function parseResponse(payload: string): ApiResponsePayload {
  return JSON.parse(payload) as ApiResponsePayload;
}

function requestJson(url: string, method: http.RequestMethod): Promise<string> {
  const config = getApiConfig();
  const request = http.createHttp();
  return request.request(url, {
    method,
    header: buildAuthorizedJsonHeaders(),
    connectTimeout: config.timeoutMs,
    readTimeout: config.timeoutMs
  }).then((response: http.HttpResponse) => {
    request.destroy();
    if (response.responseCode < 200 || response.responseCode >= 300) {
      return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
    }
    return `${response.result}`;
  }).catch((error: Error) => {
    request.destroy();
    return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
  });
}

function statusText(status: number, answer: string): string {
  if (status === 1 || answer.trim().length > 0) {
    return '已回答';
  }
  return '待回答';
}

export function buildAdminAssistantLogsFromPayload(payload: string): AdminAssistantLogItem[] {
  const response = parseResponse(payload);
  if (response.success !== true) {
    throw new Error(response.message ? response.message : 'assistant logs failed');
  }
  if (!Array.isArray(response.data)) {
    throw new Error('assistant logs data invalid');
  }
  return (response.data as HealthQuestionPayload[]).map((item: HealthQuestionPayload) => {
    const answer = item.answer ? item.answer : '';
    const status = item.status === 1 || answer.trim().length > 0 ? 1 : 0;
    const log: AdminAssistantLogItem = {
      id: `${item.id ? item.id : ''}`,
      userId: `${item.userId ? item.userId : ''}`,
      question: item.question ? item.question : '',
      answer,
      status,
      statusText: statusText(status, answer),
      createTime: item.createTime ? item.createTime : ''
    };
    return log;
  }).filter((item: AdminAssistantLogItem) => item.id.length > 0 && item.userId.length > 0);
}

export function buildAdminAssistantLogGroups(logs: AdminAssistantLogItem[]): AdminAssistantLogGroup[] {
  const groups: AdminAssistantLogGroup[] = [];
  logs.forEach((log: AdminAssistantLogItem) => {
    let groupIndex = -1;
    for (let index = 0; index < groups.length; index++) {
      if (groups[index].userId === log.userId) {
        groupIndex = index;
        break;
      }
    }
    if (groupIndex < 0) {
      const group: AdminAssistantLogGroup = {
        userId: log.userId,
        totalCount: 0,
        answeredCount: 0,
        latestQuestion: '',
        latestTime: '',
        logs: []
      };
      groups.push(group);
      groupIndex = groups.length - 1;
    }
    groups[groupIndex].logs.push(log);
    groups[groupIndex].totalCount = groups[groupIndex].logs.length;
    groups[groupIndex].answeredCount = groups[groupIndex].logs.filter((item: AdminAssistantLogItem) => item.status === 1).length;
    if (isNewerLog(log, groups[groupIndex].latestQuestion, groups[groupIndex].latestTime)) {
      groups[groupIndex].latestQuestion = log.question;
      groups[groupIndex].latestTime = log.createTime;
    }
  });
  return groups;
}

export function fetchAdminAssistantLogs(): Promise<AdminAssistantLogItem[]> {
  return requestJson(buildApiUrl('/api/health-question/list'), http.RequestMethod.GET)
    .then((payload: string) => buildAdminAssistantLogsFromPayload(payload));
}
