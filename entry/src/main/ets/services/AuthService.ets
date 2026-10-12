import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { http } from '@kit.NetworkKit';
import { buildAuthApiUrl, getApiConfig } from './ApiConfig';
import { normalizeRoleList, resolvePrimaryRole } from './RoleExperienceService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

const AUTH_SESSION_KEY: string = 'auth_session';

export interface AuthUser {
  id: string;
  phone: string;
  realName: string;
  createdAt: string;
  roles: string[];
  primaryRole: string;
}

export interface AuthSession {
  token: string;
  user: AuthUser;
}

export interface AuthRequestPayload {
  phone: string;
  password: string;
  roleCode?: string;
  code?: string;
}

export interface SmsCodeRequestPayload {
  phone: string;
  purpose: string;
}

export interface SmsCodeResult {
  message: string;
  devCode: string;
}

export interface PasswordResetIdentifyPayload {
  account: string;
}

export interface PasswordResetTarget {
  phone: string;
  maskedPhone: string;
}

export interface PasswordResetRequestPayload {
  phone: string;
  code: string;
  newPassword: string;
}

interface BackendAuthUserPayload {
  id?: string | number;
  phone?: string;
  realName?: string;
  createdAt?: string;
  createTime?: string;
  roles?: string[];
  roleCode?: string;
}

interface BackendAuthPayload {
  token?: string;
  user?: BackendAuthUserPayload;
  error?: string;
}

interface SpringBootAuthPayload {
  success?: boolean;
  message?: string;
  data?: BackendAuthPayload;
}

interface BackendCurrentUserDataPayload {
  user?: BackendAuthUserPayload;
}

interface SpringBootCurrentUserPayload {
  success?: boolean;
  message?: string;
  data?: BackendCurrentUserDataPayload;
}

interface BackendAuthActionDataPayload {
  devCode?: string;
  phone?: string;
}

interface SpringBootAuthActionPayload {
  success?: boolean;
  message?: string;
  data?: BackendAuthActionDataPayload;
}

export interface AuthStorageAdapter {
  read(key: string): Promise<string>;
  write(key: string, value: string): Promise<void>;
  remove(key: string): Promise<void>;
}

export class MemoryAuthStorageAdapter implements AuthStorageAdapter {
  private values: Map<string, string> = new Map<string, string>();

  async read(key: string): Promise<string> {
    return this.values.get(key) || '';
  }

  async write(key: string, value: string): Promise<void> {
    this.values.set(key, value);
  }

  async remove(key: string): Promise<void> {
    this.values.delete(key);
  }
}

export class PreferencesAuthStorageAdapter implements AuthStorageAdapter {
  private context: common.UIAbilityContext;
  private storeName: string;

  constructor(context: common.UIAbilityContext, storeName: string = 'wellness_auth') {
    this.context = context;
    this.storeName = storeName;
  }

  async read(key: string): Promise<string> {
    try {
      const store = await preferences.getPreferences(this.context, { name: this.storeName });
      const value = store.getSync(key, '');
      return typeof value === 'string' ? value : '';
    } catch (error) {
      return '';
    }
  }

  async write(key: string, value: string): Promise<void> {
    try {
      const store = await preferences.getPreferences(this.context, { name: this.storeName });
      store.putSync(key, value);
      await store.flush();
    } catch (error) {
    }
  }

  async remove(key: string): Promise<void> {
    try {
      const store = await preferences.getPreferences(this.context, { name: this.storeName });
      store.deleteSync(key);
      await store.flush();
    } catch (error) {
    }
  }
}

export function buildAuthRequestPayload(phone: string, password: string, roleCode?: string, code?: string): AuthRequestPayload {
  const payload: AuthRequestPayload = {
    phone: phone.trim(),
    password
  };
  if (roleCode !== undefined) {
    const normalizedRole = roleCode.trim().toUpperCase();
    payload.roleCode = normalizedRole.length > 0 ? normalizedRole : 'USER';
  }
  if (code !== undefined) {
    const normalizedCode = code.trim();
    if (normalizedCode.length > 0) {
      payload.code = normalizedCode;
    }
  }
  return payload;
}

export function buildSmsCodeRequestPayload(phone: string, purpose: string): SmsCodeRequestPayload {
  return {
    phone: phone.trim(),
    purpose: purpose.trim().toUpperCase()
  };
}

export function buildPasswordResetIdentifyPayload(account: string): PasswordResetIdentifyPayload {
  return {
    account: account.trim()
  };
}

export function buildPasswordResetRequestPayload(phone: string, code: string, newPassword: string): PasswordResetRequestPayload {
  return {
    phone: phone.trim(),
    code: code.trim(),
    newPassword
  };
}

function parseAuthActionPayload(payload: string): SpringBootAuthActionPayload {
  const raw = JSON.parse(payload) as SpringBootAuthActionPayload;
  if (raw.success === false) {
    throw new Error(raw.message ? raw.message : 'AUTH_RESPONSE_INVALID');
  }
  return raw;
}

export function buildSmsCodeResultFromBackendPayload(payload: string): SmsCodeResult {
  const raw = parseAuthActionPayload(payload);
  return {
    message: raw.message ? raw.message : '',
    devCode: ''
  };
}

export function buildPasswordResetTargetFromBackendPayload(payload: string): PasswordResetTarget {
  const raw = parseAuthActionPayload(payload);
  const emptyData: BackendAuthActionDataPayload = {};
  const data: BackendAuthActionDataPayload = raw.data ? raw.data : emptyData;
  if (!data.phone) {
    throw new Error(raw.message ? raw.message : 'AUTH_RESPONSE_INVALID');
  }
  return {
    phone: data.phone ? data.phone : '',
    maskedPhone: data.phone ? data.phone : ''
  };
}

export function buildAuthFailureText(isRegisterMode: boolean, errorMessage: string): string {
  const message = errorMessage.trim();
  if (message.indexOf('verification code error') >= 0) {
    return '验证码错误或已过期，请重新获取。';
  }
  if (message.indexOf('phone not found') >= 0) {
    return '手机号不存在，请检查后重试。';
  }
  if (message.indexOf('account not found') >= 0) {
    return '账号不存在，请检查后重试。';
  }
  if (message.indexOf('phone or password error') >= 0) {
    return '手机号或密码错误，请重新输入。';
  }
  if (message.indexOf('user disabled') >= 0) {
    return '该账号已被禁用，请联系管理员。';
  }
  if (message.indexOf('phone already exists') >= 0) {
    return '该手机号已注册，请直接登录。';
  }
  if (message.indexOf('password length') >= 0) {
    return '密码至少需要 6 位。';
  }
  if (message.indexOf('phone and password are required') >= 0) {
    return '请填写手机号和密码。';
  }
  if (message.length > 0 && message !== 'AUTH_RESPONSE_INVALID') {
    return message;
  }
  return isRegisterMode ? '注册失败，请检查手机号是否已注册。' : '登录失败，请检查手机号和密码。';
}

let runtimeAuthToken: string = '';

export function setRuntimeAuthToken(token: string): void {
  runtimeAuthToken = token.trim();
}

export function buildAuthorizedJsonHeaders(): Record<string, string> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json'
  };
  if (runtimeAuthToken.length > 0) {
    headers['Authorization'] = `Bearer ${runtimeAuthToken}`;
  }
  return headers;
}

export function buildAuthorizedHeaders(): Record<string, string> {
  const headers: Record<string, string> = {};
  if (runtimeAuthToken.length > 0) {
    headers['Authorization'] = `Bearer ${runtimeAuthToken}`;
  }
  return headers;
}

function buildBearerHeaders(token: string): Record<string, string> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json'
  };
  const trimmedToken = token.trim();
  if (trimmedToken.length > 0) {
    headers['Authorization'] = `Bearer ${trimmedToken}`;
  }
  return headers;
}

export function isValidPhone(phone: string): boolean {
  return /^1\d{10}$/.test(phone.trim());
}

export function isValidPassword(password: string): boolean {
  if (password.length < 6 || password.length > 64) {
    return false;
  }
  let hasLetter = false;
  let hasDigit = false;
  for (let i = 0; i < password.length; i++) {
    const ch = password.charAt(i);
    if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')) {
      hasLetter = true;
    } else if (ch >= '0' && ch <= '9') {
      hasDigit = true;
    }
  }
  return hasLetter && hasDigit;
}

export function serializeAuthSession(session: AuthSession): string {
  return JSON.stringify(session);
}

function isValidSession(session: AuthSession): boolean {
  return !!session
    && session.token.length > 0
    && !!session.user
    && session.user.id.length > 0
    && session.user.phone.length > 0;
}

export function deserializeAuthSession(value: string): AuthSession | null {
  try {
    const parsed = JSON.parse(value) as AuthSession;
    if (isValidSession(parsed)) {
      if (!parsed.user.roles || parsed.user.roles.length === 0) {
        parsed.user.roles = ['USER'];
      }
      parsed.user.roles = normalizeRoleList(parsed.user.roles);
      parsed.user.primaryRole = parsed.user.primaryRole ? resolvePrimaryRole([parsed.user.primaryRole]) : resolvePrimaryRole(parsed.user.roles);
      if (!parsed.user.realName) {
        parsed.user.realName = '';
      }
      return parsed;
    }
  } catch (error) {
    return null;
  }
  return null;
}

export function buildAuthSessionFromBackendPayload(payload: string): AuthSession {
  const raw = JSON.parse(payload) as SpringBootAuthPayload;
  const data: BackendAuthPayload = raw.data ? raw.data : (raw as BackendAuthPayload);
  if (!data.token || !data.user || !data.user.id || !data.user.phone) {
    throw new Error(data.error ? data.error : raw.message ? raw.message : 'AUTH_RESPONSE_INVALID');
  }
  const createdAt = data.user.createdAt ? data.user.createdAt : data.user.createTime ? data.user.createTime : '';
  const backendRoles = data.user.roles ? data.user.roles : data.user.roleCode ? [data.user.roleCode] : ['USER'];
  const roles = normalizeRoleList(backendRoles);
  const user: AuthUser = {
    id: `${data.user.id}`,
    phone: data.user.phone,
    realName: data.user.realName ? data.user.realName : '',
    createdAt,
    roles,
    primaryRole: resolvePrimaryRole(roles)
  };
  const session: AuthSession = {
    token: data.token,
    user
  };
  return session;
}

function buildAuthUserFromBackendPayload(userPayload: BackendAuthUserPayload): AuthUser {
  if (!userPayload.id || !userPayload.phone) {
    throw new Error('AUTH_RESPONSE_INVALID');
  }
  const createdAt = userPayload.createdAt ? userPayload.createdAt : userPayload.createTime ? userPayload.createTime : '';
  const backendRoles = userPayload.roles ? userPayload.roles : userPayload.roleCode ? [userPayload.roleCode] : ['USER'];
  const roles = normalizeRoleList(backendRoles);
  const user: AuthUser = {
    id: `${userPayload.id}`,
    phone: userPayload.phone,
    realName: userPayload.realName ? userPayload.realName : '',
    createdAt,
    roles,
    primaryRole: resolvePrimaryRole(roles)
  };
  return user;
}

export function buildAuthSessionFromCurrentUserPayload(token: string, payload: string): AuthSession {
  const raw = JSON.parse(payload) as SpringBootCurrentUserPayload;
  if (raw.success === false) {
    throw new Error(raw.message ? raw.message : 'AUTH_SESSION_INVALID');
  }
  const emptyData: BackendCurrentUserDataPayload = {};
  const data: BackendCurrentUserDataPayload = raw.data ? raw.data : emptyData;
  if (!data.user) {
    throw new Error(raw.message ? raw.message : 'AUTH_RESPONSE_INVALID');
  }
  const session: AuthSession = {
    token,
    user: buildAuthUserFromBackendPayload(data.user)
  };
  return session;
}

export class AuthSessionRepository {
  private storage: AuthStorageAdapter;

  constructor(storage: AuthStorageAdapter) {
    this.storage = storage;
  }

  async loadSession(): Promise<AuthSession | null> {
    const stored = await this.storage.read(AUTH_SESSION_KEY);
    if (stored.length === 0) {
      return null;
    }
    return deserializeAuthSession(stored);
  }

  async saveSession(session: AuthSession): Promise<AuthSession> {
    await this.storage.write(AUTH_SESSION_KEY, serializeAuthSession(session));
    return session;
  }

  async clearSession(): Promise<void> {
    await this.storage.remove(AUTH_SESSION_KEY);
  }
}

export function createPreferencesAuthSessionRepository(context: common.UIAbilityContext): AuthSessionRepository {
  return new AuthSessionRepository(new PreferencesAuthStorageAdapter(context));
}

type AuthPostPayload = AuthRequestPayload | SmsCodeRequestPayload | PasswordResetIdentifyPayload | PasswordResetRequestPayload;

function requestAuthPost(path: string, payload: AuthPostPayload): Promise<string> {
  const config = getApiConfig();
  const request = http.createHttp();
  return request.request(buildAuthApiUrl(path), {
    method: http.RequestMethod.POST,
    header: {
      'Content-Type': 'application/json'
    },
    extraData: JSON.stringify(payload),
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

function requestAuth(path: string, payload: AuthPostPayload): Promise<AuthSession> {
  return requestAuthPost(path, payload).then((payloadText: string) => buildAuthSessionFromBackendPayload(payloadText));
}

function requestSmsCode(path: string, payload: SmsCodeRequestPayload): Promise<SmsCodeResult> {
  return requestAuthPost(path, payload).then((payloadText: string) => buildSmsCodeResultFromBackendPayload(payloadText));
}

function requestPasswordResetTarget(path: string, payload: PasswordResetIdentifyPayload): Promise<PasswordResetTarget> {
  return requestAuthPost(path, payload).then((payloadText: string) => buildPasswordResetTargetFromBackendPayload(payloadText));
}

function requestAuthAction(path: string, payload: PasswordResetRequestPayload): Promise<string> {
  return requestAuthPost(path, payload).then((payloadText: string) => {
    const raw = parseAuthActionPayload(payloadText);
    return raw.message ? raw.message : '';
  });
}

export function requestCurrentAuthSession(session: AuthSession): Promise<AuthSession> {
  const config = getApiConfig();
  const request = http.createHttp();
  return request.request(buildAuthApiUrl(config.authMePath), {
    method: http.RequestMethod.GET,
    header: buildBearerHeaders(session.token),
    connectTimeout: config.timeoutMs,
    readTimeout: config.timeoutMs
  }).then((response: http.HttpResponse) => {
    request.destroy();
    if (response.responseCode < 200 || response.responseCode >= 300) {
      return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
    }
    return buildAuthSessionFromCurrentUserPayload(session.token, `${response.result}`);
  }).catch((error: Error) => {
    request.destroy();
    return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
  });
}

export function loginWithPhone(phone: string, password: string): Promise<AuthSession> {
  return requestAuth(getApiConfig().authLoginPath, buildAuthRequestPayload(phone, password));
}

export function loginWithSmsCode(phone: string, code: string): Promise<AuthSession> {
  return requestAuth(getApiConfig().authSmsLoginPath, {
    phone: phone.trim(),
    password: '',
    code: code.trim()
  });
}

export function registerWithPhone(phone: string, password: string, roleCode: string = 'USER', code: string = ''): Promise<AuthSession> {
  return requestAuth(getApiConfig().authRegisterPath, buildAuthRequestPayload(phone, password, roleCode, code));
}

export function sendAuthSmsCode(phone: string, purpose: string): Promise<SmsCodeResult> {
  return requestSmsCode(getApiConfig().authSmsCodePath, buildSmsCodeRequestPayload(phone, purpose));
}

export function identifyPasswordResetAccount(account: string): Promise<PasswordResetTarget> {
  return requestPasswordResetTarget(getApiConfig().authPasswordResetIdentifyPath, buildPasswordResetIdentifyPayload(account));
}

export function resetPasswordWithSmsCode(phone: string, code: string, newPassword: string): Promise<string> {
  return requestAuthAction(getApiConfig().authPasswordResetPath, buildPasswordResetRequestPayload(phone, code, newPassword));
}
