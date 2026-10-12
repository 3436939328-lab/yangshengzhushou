import { http } from '@kit.NetworkKit';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

interface ApiResponsePayload {
  success?: boolean;
  message?: string;
  data?: Object;
}

interface UserPayload {
  id?: number;
  username?: string;
  realName?: string;
  phone?: string;
  gender?: string;
  age?: number;
  status?: number;
}

export interface CreateAdminUserPayload {
  username: string;
  realName: string;
  phone: string;
  password: string;
  roleCode: string;
  status: number;
}

interface UpdateAdminUserPayload {
  id: number;
  realName: string;
  phone: string;
}

export interface AdminUserItem {
  id: string;
  username: string;
  realName: string;
  phone: string;
  gender: string;
  age: string;
  statusText: string;
}

function parseResponse(payload: string): ApiResponsePayload {
  return JSON.parse(payload) as ApiResponsePayload;
}

function requestJson(url: string, method: http.RequestMethod, body?: Object): Promise<string> {
  const config = getApiConfig();
  const request = http.createHttp();
  return request.request(url, {
    method,
    header: buildAuthorizedJsonHeaders(),
    extraData: body ? JSON.stringify(body) : undefined,
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

function ensureSuccess(payload: string, fallbackMessage: string): boolean {
  const response = parseResponse(payload);
  if (response.success === true) {
    return true;
  }
  const message = response.message ? response.message : fallbackMessage;
  throw new Error(message);
}

export function buildAdminUsersFromPayload(payload: string): AdminUserItem[] {
  const response = parseResponse(payload);
  if (response.success !== true) {
    throw new Error(response.message ? response.message : 'user list failed');
  }
  if (!Array.isArray(response.data)) {
    throw new Error('user list data invalid');
  }
  return (response.data as UserPayload[]).map((user: UserPayload) => {
    const item: AdminUserItem = {
      id: `${user.id ? user.id : ''}`,
      username: user.username ? user.username : '',
      realName: user.realName ? user.realName : '',
      phone: user.phone ? user.phone : '',
      gender: user.gender ? user.gender : '',
      age: user.age ? `${user.age}` : '',
      statusText: user.status === 0 ? '禁用' : '正常'
    };
    return item;
  }).filter((user: AdminUserItem) => user.id.length > 0);
}

export function fetchAdminUsers(): Promise<AdminUserItem[]> {
  return requestJson(buildApiUrl('/api/user/list'), http.RequestMethod.GET)
    .then((payload: string) => buildAdminUsersFromPayload(payload));
}

export function buildCreateAdminUserPayload(
  username: string,
  realName: string,
  phone: string,
  password: string,
  roleCode: string
): CreateAdminUserPayload {
  const body: CreateAdminUserPayload = {
    username: username.trim(),
    realName: realName.trim(),
    phone: phone.trim(),
    password: password.trim(),
    roleCode: roleCode.trim().length > 0 ? roleCode.trim().toUpperCase() : 'USER',
    status: 1
  };
  return body;
}

export function createAdminUser(
  username: string,
  realName: string,
  phone: string,
  password: string = '',
  roleCode: string = 'USER'
): Promise<boolean> {
  const body: CreateAdminUserPayload = buildCreateAdminUserPayload(username, realName, phone, password, roleCode);
  return requestJson(buildApiUrl('/api/user'), http.RequestMethod.POST, body)
    .then((payload: string) => ensureSuccess(payload, '新增人员失败'));
}

export function updateAdminUser(id: string, realName: string, phone: string): Promise<boolean> {
  const body: UpdateAdminUserPayload = {
    id: Number(id),
    realName,
    phone
  };
  return requestJson(buildApiUrl('/api/user/profile'), http.RequestMethod.PUT, body)
    .then((payload: string) => ensureSuccess(payload, '保存修改失败'));
}

export function deleteAdminUser(id: string): Promise<boolean> {
  return requestJson(buildApiUrl(`/api/user?id=${encodeURIComponent(id)}`), http.RequestMethod.DELETE)
    .then((payload: string) => ensureSuccess(payload, '删除人员失败'));
}
