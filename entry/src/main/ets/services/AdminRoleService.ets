import { http } from '@kit.NetworkKit';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';
import { normalizeRoleCode } from './RoleExperienceService';

interface ApiResponsePayload {
  success?: boolean;
  message?: string;
  data?: Object;
}

interface RolePayload {
  id?: number;
  roleName?: string;
  roleCode?: string;
}

interface UserRolePayload {
  id?: number;
  userId?: number;
  roleId?: number;
}

interface AssignAdminUserRolePayload {
  userId: number;
  roleId: number;
}

export interface AdminRoleItem {
  id: string;
  roleName: string;
  roleCode: string;
  normalizedRoleCode: string;
}

export interface AdminUserRoleItem {
  id: string;
  userId: string;
  roleId: string;
}

function parseResponse(payload: string): ApiResponsePayload {
  return JSON.parse(payload) as ApiResponsePayload;
}

function responseDataArray<T>(payload: string): T[] {
  const response = parseResponse(payload);
  if (response.success !== true) {
    throw new Error(response.message ? response.message : 'role data failed');
  }
  if (!Array.isArray(response.data)) {
    throw new Error('role data invalid');
  }
  return response.data as T[];
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

export function buildAdminRolesFromPayload(payload: string): AdminRoleItem[] {
  return responseDataArray<RolePayload>(payload).map((role: RolePayload) => {
    const rawRoleCode = role.roleCode ? role.roleCode.trim().toUpperCase() : '';
    const item: AdminRoleItem = {
      id: `${role.id ? role.id : ''}`,
      roleName: role.roleName ? role.roleName : '',
      roleCode: rawRoleCode,
      normalizedRoleCode: rawRoleCode.length > 0 ? normalizeRoleCode(rawRoleCode) : 'USER'
    };
    return item;
  }).filter((role: AdminRoleItem) => role.id.length > 0);
}

export function buildAdminUserRolesFromPayload(payload: string): AdminUserRoleItem[] {
  return responseDataArray<UserRolePayload>(payload).map((item: UserRolePayload) => {
    const binding: AdminUserRoleItem = {
      id: `${item.id ? item.id : ''}`,
      userId: `${item.userId ? item.userId : ''}`,
      roleId: `${item.roleId ? item.roleId : ''}`
    };
    return binding;
  }).filter((item: AdminUserRoleItem) => item.id.length > 0 && item.userId.length > 0 && item.roleId.length > 0);
}

export function fetchAdminRoles(): Promise<AdminRoleItem[]> {
  return requestJson(buildApiUrl('/api/role/list'), http.RequestMethod.GET)
    .then((payload: string) => buildAdminRolesFromPayload(payload));
}

export function fetchAdminUserRoles(): Promise<AdminUserRoleItem[]> {
  return requestJson(buildApiUrl('/api/user-role/list'), http.RequestMethod.GET)
    .then((payload: string) => buildAdminUserRolesFromPayload(payload));
}

export function assignAdminUserRole(userId: string, roleId: string): Promise<boolean> {
  const body: AssignAdminUserRolePayload = {
    userId: Number(userId),
    roleId: Number(roleId)
  };
  return requestJson(buildApiUrl('/api/user-role'), http.RequestMethod.POST, body)
    .then((payload: string) => ensureSuccess(payload, '角色绑定失败'));
}

export function deleteAdminUserRole(id: string): Promise<boolean> {
  return requestJson(buildApiUrl(`/api/user-role?id=${encodeURIComponent(id)}`), http.RequestMethod.DELETE)
    .then((payload: string) => ensureSuccess(payload, '角色移除失败'));
}
