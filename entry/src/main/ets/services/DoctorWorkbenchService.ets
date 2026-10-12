import { http } from '@kit.NetworkKit';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

export interface DoctorWorkbenchProfile {
  doctorId: string;
  name: string;
  title: string;
  specialty: string;
  department: string;
  avatar: string;
  verificationStatus: string;
  accepting: boolean;
}

export interface DoctorWorkbenchStats {
  todayConsultations: number;
  pendingReplies: number;
  totalPatients: number;
  totalConsultations: number;
  avgRating: number;
  ratingCount: number;
  goodRate: number;
}

export interface DoctorTodoItem {
  type: string;
  title: string;
  count: number;
  description: string;
  icon: string;
  actionTab: string;
}

export interface DoctorQuickAction {
  key: string;
  title: string;
  icon: string;
  tab: string;
}

export interface DoctorWorkbenchData {
  profile: DoctorWorkbenchProfile;
  stats: DoctorWorkbenchStats;
  todos: DoctorTodoItem[];
  quickActions: DoctorQuickAction[];
}

interface ApiResponsePayload {
  success?: boolean;
  message?: string;
  data?: Object;
}

function parseResponse(payload: string): ApiResponsePayload {
  return JSON.parse(payload) as ApiResponsePayload;
}

interface ToggleAcceptingBody {
  accepting: boolean;
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

export function fetchDoctorWorkbench(): Promise<DoctorWorkbenchData> {
  return requestJson(buildApiUrl('/api/doctor/workbench/overview'), http.RequestMethod.GET)
    .then((payload: string) => {
      const resp = parseResponse(payload);
      if (resp.success !== true || !resp.data) {
        throw new Error(resp.message || '获取工作台数据失败');
      }
      return resp.data as DoctorWorkbenchData;
    });
}

export function toggleDoctorAccepting(accepting: boolean): Promise<boolean> {
  const body: ToggleAcceptingBody = { accepting: accepting };
  return requestJson(buildApiUrl('/api/doctor/workbench/toggle-accepting'), http.RequestMethod.POST, body)
    .then((payload: string) => {
      const resp = parseResponse(payload);
      if (resp.success !== true) {
        throw new Error(resp.message || '切换失败');
      }
      const data = resp.data as Record<string, Object>;
      return data['accepting'] === true;
    });
}
