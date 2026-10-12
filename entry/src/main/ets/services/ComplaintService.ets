import { http } from '@kit.NetworkKit';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

export interface UserComplaintItem {
  id: number;
  eventId: number;
  reporterId: number;
  description: string;
  status: string;
  createdAt: string;
  updatedAt: string;
  category?: string;
  decisionId?: number;
  decisionResult?: string;
  decisionReason?: string;
  decisionAt?: string;
  consultationId?: number;
  appeal?: AppealInfo;
}

export interface AppealInfo {
  id: number;
  status: string;
  reason: string;
  resultReason?: string;
  createdAt: string;
  reviewedAt?: string;
}

export interface DoctorSanctionItem {
  id: number;
  eventId: number;
  decisionId: number;
  doctorId: number;
  type: string;
  scope: string;
  status: string;
  startsAt: string;
  endsAt: string;
  reason: string;
  createdAt: string;
}

export interface DoctorAppealItem {
  id: number;
  decisionId: number;
  doctorId: number;
  status: string;
  reason: string;
  resultReason: string;
  createdAt: string;
  reviewedAt: string;
}

interface SubmitComplaintPayload {
  consultationId: number;
  doctorId: number;
  category: string;
  description: string;
}

interface SubmitAppealPayload {
  decisionId: number;
  reason: string;
}

interface ApiResponsePayload {
  success?: boolean;
  message?: string;
  data?: Object;
}

interface EmptyBody {}

export function submitComplaint(consultationId: string, doctorId: string,
                                 category: string, description: string): Promise<boolean> {
  const config = getApiConfig();
  const request = http.createHttp();
  const url = buildApiUrl('/api/user/complaints');
  const body: SubmitComplaintPayload = {
    consultationId: Number(consultationId),
    doctorId: Number(doctorId),
    category,
    description
  };
  return request.request(url, {
    method: http.RequestMethod.POST,
    header: buildAuthorizedJsonHeaders(),
    extraData: JSON.stringify(body),
    connectTimeout: config.timeoutMs,
    readTimeout: config.timeoutMs
  }).then((response: http.HttpResponse) => {
    request.destroy();
    if (response.responseCode < 200 || response.responseCode >= 300) {
      return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
    }
    const payload = `${response.result}`;
    const resp = JSON.parse(payload) as ApiResponsePayload;
    return resp.success === true;
  }).catch((error: Error) => {
    request.destroy();
    return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
  });
}

export function fetchMyComplaints(): Promise<UserComplaintItem[]> {
  return requestJsonGet('/api/user/my-complaints').then((payload: string) => {
    const resp = JSON.parse(payload) as ApiResponsePayload;
    if (resp.success !== true || !resp.data) {
      return [];
    }
    const data = resp.data as Record<string, Object>;
    const items = data['items'];
    if (!items || !Array.isArray(items)) {
      return [];
    }
    return items as UserComplaintItem[];
  }).catch(() => []);
}

export function fetchDoctorComplaints(): Promise<UserComplaintItem[]> {
  return requestJsonGet('/api/doctor/complaints').then((payload: string) => {
    const resp = JSON.parse(payload) as ApiResponsePayload;
    if (resp.success !== true || !resp.data) {
      return [];
    }
    const data = resp.data as Record<string, Object>;
    const items = data['items'];
    if (!items || !Array.isArray(items)) {
      return [];
    }
    return items as UserComplaintItem[];
  }).catch(() => []);
}

export interface SanctionsResult {
  all: DoctorSanctionItem[];
  active: DoctorSanctionItem[];
  blocked: boolean;
}

export function fetchDoctorSanctions(): Promise<SanctionsResult> {
  return requestJsonGet('/api/doctor/sanctions').then((payload: string) => {
    const resp = JSON.parse(payload) as ApiResponsePayload;
    if (resp.success !== true || !resp.data) {
      const empty: SanctionsResult = { all: [], active: [], blocked: false };
      return empty;
    }
    const data = resp.data as Record<string, Object>;
    const result: SanctionsResult = {
      all: Array.isArray(data['all']) ? data['all'] as DoctorSanctionItem[] : [],
      active: Array.isArray(data['active']) ? data['active'] as DoctorSanctionItem[] : [],
      blocked: data['blocked'] === true
    };
    return result;
  }).catch(() => {
    const empty: SanctionsResult = { all: [], active: [], blocked: false };
    return empty;
  });
}

export function fetchDoctorAppeals(): Promise<DoctorAppealItem[]> {
  return requestJsonGet('/api/doctor/appeals').then((payload: string) => {
    const resp = JSON.parse(payload) as ApiResponsePayload;
    if (resp.success !== true || !resp.data) {
      return [];
    }
    const data = resp.data as Record<string, Object>;
    const items = data['items'];
    if (!items || !Array.isArray(items)) {
      return [];
    }
    return items as DoctorAppealItem[];
  }).catch(() => []);
}

export function submitAppeal(decisionId: number, reason: string): Promise<boolean> {
  const config = getApiConfig();
  const request = http.createHttp();
  const url = buildApiUrl('/api/doctor/appeals');
  const body: SubmitAppealPayload = {
    decisionId,
    reason
  };
  return request.request(url, {
    method: http.RequestMethod.POST,
    header: buildAuthorizedJsonHeaders(),
    extraData: JSON.stringify(body),
    connectTimeout: config.timeoutMs,
    readTimeout: config.timeoutMs
  }).then((response: http.HttpResponse) => {
    request.destroy();
    if (response.responseCode < 200 || response.responseCode >= 300) {
      return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
    }
    const payload = `${response.result}`;
    const resp = JSON.parse(payload) as ApiResponsePayload;
    return resp.success === true;
  }).catch((error: Error) => {
    request.destroy();
    return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
  });
}

function requestJsonGet(path: string): Promise<string> {
  const config = getApiConfig();
  const request = http.createHttp();
  const url = buildApiUrl(path);
  return request.request(url, {
    method: http.RequestMethod.GET,
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

export function complaintStatusText(status: string): string {
  switch (status) {
    case 'SUBMITTED': return '已提交';
    case 'REVIEWING': return '审核中';
    case 'NEED_INFO': return '需补充';
    case 'UPHELD': return '投诉成立';
    case 'REJECTED': return '投诉驳回';
    case 'MERGED': return '已合并';
    default: return status;
  }
}

export function sanctionTypeText(type: string): string {
  switch (type) {
    case 'WARNING': return '警告';
    case 'SUSPEND_1D': return '暂停接诊1天';
    case 'SUSPEND_7D': return '暂停接诊7天';
    case 'SUSPEND_30D': return '暂停接诊30天';
    case 'PERMANENT_BAN': return '永久封禁';
    default: return type;
  }
}

export function sanctionStatusText(status: string): string {
  switch (status) {
    case 'ACTIVE': return '生效中';
    case 'EXPIRED': return '已过期';
    case 'REVOKED': return '已撤销';
    default: return status;
  }
}

export function appealStatusText(status: string): string {
  switch (status) {
    case 'PENDING': return '待审核';
    case 'REVIEWING': return '审核中';
    case 'MAINTAINED': return '维持原判';
    case 'REDUCED': return '减轻处罚';
    case 'REVOKED': return '撤销处罚';
    default: return status;
  }
}

export function categoryText(category: string): string {
  switch (category) {
    case 'ATTITUDE': return '服务态度';
    case 'PROFESSIONAL': return '专业水平';
    case 'RESPONSE_SPEED': return '响应速度';
    case 'PAYMENT': return '收费问题';
    case 'PRIVACY': return '隐私泄露';
    case 'OTHER': return '其他';
    default: return category;
  }
}
