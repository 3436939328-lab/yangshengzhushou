import { notifySessionInvalidated } from './SessionInvalidationService';

interface BackendErrorPayload {
  success?: boolean;
  message?: string;
  error?: string;
}

function extractBackendErrorMessage(payload: string): string {
  const trimmed = payload.trim();
  if (trimmed.length === 0) {
    return '';
  }
  try {
    const response = JSON.parse(trimmed) as BackendErrorPayload;
    if (response.message && response.message.trim().length > 0) {
      return response.message.trim();
    }
    if (response.error && response.error.trim().length > 0) {
      return response.error.trim();
    }
  } catch (error) {
    return trimmed;
  }
  return trimmed;
}

export function buildHttpFailureText(statusCode: number, payload: string): string {
  const message = extractBackendErrorMessage(payload);
  if (statusCode === 401) {
    const failureText = '登录已过期，请重新登录。';
    notifySessionInvalidated(failureText);
    return failureText;
  }
  if (statusCode === 403) {
    return '当前账号没有权限执行该操作。';
  }
  if (statusCode === 402) {
    return '积分不足，请先到“我的”签到领取积分。';
  }
  if (statusCode === 409) {
    return message || '请求正在处理，请稍后查询结果。';
  }
  if (statusCode === 429) {
    return '请求较多，请稍后再试。';
  }
  if (statusCode === 503 || statusCode === 504 || statusCode === 502) {
    if (message.indexOf('no points charged') >= 0) return '模型暂时无法回答，本次不扣积分，请稍后重试。';
    if (message.indexOf('unavailable') >= 0) return '模型服务暂不可用，请检查后端模型配置后重试。';
    return message || '模型暂时无法回答，请稍后重试。';
  }
  if (statusCode >= 500) {
    return '后端服务异常，请稍后重试或检查 8181 后端日志。';
  }
  if (message.length > 0) {
    return message;
  }
  return `请求失败（${statusCode}），请稍后重试。`;
}

export function normalizeNetworkErrorMessage(errorMessage: string): string {
  const message = errorMessage.trim();
  const lowerMessage = message.toLowerCase();
  if (lowerMessage.indexOf('timeout') >= 0 || lowerMessage.indexOf('timed out') >= 0) {
    return '后端响应超时，请确认 8181 后端已启动并稍后重试。';
  }
  if (lowerMessage.indexOf('econnrefused') >= 0
    || lowerMessage.indexOf('connect') >= 0
    || lowerMessage.indexOf('network') >= 0
    || lowerMessage.indexOf('failed to fetch') >= 0
    || lowerMessage.indexOf('connection refused') >= 0) {
    return '无法连接后端，请确认 8181 后端已启动，且手机和电脑在同一网络。';
  }
  return message;
}
