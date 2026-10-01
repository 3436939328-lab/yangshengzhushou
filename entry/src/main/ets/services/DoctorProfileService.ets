import { http } from '@kit.NetworkKit';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

interface ApiResponsePayload {
  success?: boolean;
  message?: string;
  data?: Object;
}

interface DoctorProfilePayload {
  id?: number;
  userId?: number;
  doctorName?: string;
  title?: string;
  specialty?: string;
  introduction?: string;
  avatar?: string;
  department?: string;
  licenseNumber?: string;
  licenseImageUrls?: string;
  verificationStatus?: string;
  verificationRemark?: string;
  accepting?: boolean;
}

interface SaveDoctorProfilePayload {
  id?: number;
  userId: number;
  doctorName: string;
  title: string;
  specialty: string;
  introduction: string;
  avatar?: string;
  department?: string;
  licenseNumber?: string;
  licenseImageUrls?: string;
  verificationStatus?: string;
  accepting?: boolean;
}

export interface DoctorProfileForm {
  id: string;
  userId: string;
  doctorName: string;
  title: string;
  specialty: string;
  introduction: string;
  avatar: string;
  department: string;
  licenseNumber: string;
  licenseImageUrls: string;
  verificationStatus: string;
  verificationRemark: string;
  accepting: boolean;
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

export function createEmptyDoctorProfile(userId: string): DoctorProfileForm {
  const profile: DoctorProfileForm = {
    id: '',
    userId,
    doctorName: '',
    title: '',
    specialty: '',
    introduction: '',
    avatar: '',
    department: '',
    licenseNumber: '',
    licenseImageUrls: '',
    verificationStatus: 'PENDING',
    verificationRemark: '',
    accepting: false
  };
  return profile;
}

export function buildDoctorProfileFromPayload(payload: string, fallbackUserId: string): DoctorProfileForm {
  const response = parseResponse(payload);
  if (!response.success || response.data === undefined || response.data === null || Array.isArray(response.data)) {
    return createEmptyDoctorProfile(fallbackUserId);
  }
  const data = response.data as DoctorProfilePayload;
  const profile: DoctorProfileForm = {
    id: `${data.id ? data.id : ''}`,
    userId: `${data.userId ? data.userId : fallbackUserId}`,
    doctorName: data.doctorName ? data.doctorName : '',
    title: data.title ? data.title : '',
    specialty: data.specialty ? data.specialty : '',
    introduction: data.introduction ? data.introduction : '',
    avatar: data.avatar ? data.avatar : '',
    department: data.department ? data.department : '',
    licenseNumber: data.licenseNumber ? data.licenseNumber : '',
    licenseImageUrls: data.licenseImageUrls ? data.licenseImageUrls : '',
    verificationStatus: data.verificationStatus ? data.verificationStatus : 'PENDING',
    verificationRemark: data.verificationRemark ? data.verificationRemark : '',
    accepting: data.accepting === true
  };
  return profile;
}

export function buildDoctorProfileValidationText(profile: DoctorProfileForm): string {
  if (profile.doctorName.trim().length === 0) {
    return '请填写医生姓名。';
  }
  if (profile.specialty.trim().length === 0) {
    return '请填写擅长方向。';
  }
  return '';
}

export function buildDoctorProfileIdentityText(userId: string): string {
  const normalizedUserId = Number(userId.trim());
  if (userId.trim().length === 0 || !Number.isFinite(normalizedUserId) || normalizedUserId <= 0) {
    return '当前登录信息缺少用户编号，请重新登录后再保存。';
  }
  return '';
}

export function buildDoctorProfileSaveFailureText(errorMessage: string): string {
  const message = errorMessage.trim();
  if (message.indexOf('specialty is required') >= 0) {
    return '请填写擅长方向后再保存。';
  }
  if (message.indexOf('doctorName is required') >= 0) {
    return '请填写医生姓名后再保存。';
  }
  if (message.indexOf('forbidden') >= 0 || message.indexOf('403') >= 0 || message.indexOf('没有权限') >= 0) {
    return '当前账号没有医生资料维护权限，请确认已使用医生账号登录。';
  }
  if (message.indexOf('userId is required') >= 0) {
    return '当前登录信息缺少用户编号，请重新登录后再保存。';
  }
  return '医生资料保存失败，请稍后重试。';
}

export function buildDoctorProfileSaveErrorMessage(payload: string): string {
  try {
    const response = parseResponse(payload);
    if (response.success === true) {
      return '';
    }
    return response.message ? response.message : 'save failed';
  } catch (error) {
    return payload.trim();
  }
}

export function fetchDoctorProfile(userId: string): Promise<DoctorProfileForm> {
  return requestJson(buildApiUrl(`/api/doctor-profile?userId=${encodeURIComponent(userId)}`), http.RequestMethod.GET)
    .then((payload: string) => buildDoctorProfileFromPayload(payload, userId));
}

export function saveDoctorProfile(profile: DoctorProfileForm): Promise<boolean> {
  const body: SaveDoctorProfilePayload = {
    id: profile.id.length > 0 ? Number(profile.id) : undefined,
    userId: Number(profile.userId),
    doctorName: profile.doctorName,
    title: profile.title,
    specialty: profile.specialty,
    introduction: profile.introduction,
    avatar: profile.avatar.length > 0 ? profile.avatar : undefined,
    department: profile.department.length > 0 ? profile.department : undefined,
    licenseNumber: profile.licenseNumber.length > 0 ? profile.licenseNumber : undefined,
    licenseImageUrls: profile.licenseImageUrls.length > 0 ? profile.licenseImageUrls : undefined,
    verificationStatus: profile.verificationStatus.length > 0 ? profile.verificationStatus : undefined,
    accepting: profile.accepting
  };
  return requestJson(buildApiUrl('/api/doctor-profile'), http.RequestMethod.POST, body)
    .then((payload: string) => {
      const errorMessage = buildDoctorProfileSaveErrorMessage(payload);
      if (errorMessage.length > 0) {
        return Promise.reject(new Error(errorMessage));
      }
      return true;
    });
}
