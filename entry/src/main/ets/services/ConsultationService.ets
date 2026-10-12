import { http } from '@kit.NetworkKit';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

interface ApiResponsePayload {
  success?: boolean;
  message?: string;
  data?: Object;
}

interface EmptyBody {}

interface DoctorProfilePayload {
  id?: number;
  userId?: number;
  doctorName?: string;
  title?: string;
  specialty?: string;
  introduction?: string;
  department?: string;
  avatar?: string;
  verificationStatus?: string;
  accepting?: boolean;
}

interface ConsultationPayload {
  id?: number;
  userId?: number;
  doctorId?: number;
  symptom?: string;
  description?: string;
  status?: number;
  createTime?: string;
  sharedName?: string;
  sharedAge?: number;
  sharedGender?: string;
  sharedPhone?: string;
  healthSnapshot?: string;
  tongueImageUrls?: string;
}

interface ConsultationMessagePayload {
  id?: number;
  consultationId?: number;
  senderId?: number;
  senderRole?: string;
  content?: string;
  createTime?: string;
}

interface CreateConsultationPayload {
  userId: number;
  doctorId: number;
  symptom: string;
  description: string;
  sharedName?: string;
  sharedAge?: number;
  sharedGender?: string;
  sharedPhone?: string;
  healthSnapshot?: string;
  tongueImageUrls?: string;
}

interface SendConsultationMessagePayload {
  consultationId: number;
  content: string;
}

export interface DoctorOption {
  id: string;
  userId: string;
  name: string;
  title: string;
  specialty: string;
  introduction: string;
  department: string;
  avatar: string;
  accepting: boolean;
}

export interface ConsultationThread {
  id: string;
  userId: string;
  doctorId: string;
  symptom: string;
  description: string;
  statusCode: number;
  statusText: string;
  createTime: string;
  sharedName: string;
  sharedAge: number;
  sharedGender: string;
  sharedPhone: string;
  healthSnapshot: string;
  tongueImageUrls: string;
}

export interface ConsultationMessageItem {
  id: string;
  consultationId: string;
  senderId: string;
  senderRole: string;
  content: string;
  createTime: string;
}

function parseResponse(payload: string): ApiResponsePayload {
  return JSON.parse(payload) as ApiResponsePayload;
}

function responseDataArray<T>(payload: string): T[] {
  const response = parseResponse(payload);
  if (response.success !== true) {
    throw new Error(response.message ? response.message : 'consultation data failed');
  }
  if (!Array.isArray(response.data)) {
    throw new Error('consultation data invalid');
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

export interface DoctorRecommendation {
  doctorId: string;
  reason: string;
  department: string;
}

export function fetchRecommendedDoctor(): Promise<DoctorRecommendation | null> {
  return requestJson(buildApiUrl('/api/consultation/recommend-doctor'), http.RequestMethod.GET)
    .then((payload: string) => {
      const resp = parseResponse(payload);
      if (resp.success !== true || !resp.data) {
        return null;
      }
      const data = resp.data as Record<string, Object>;
      const doctorId = data['doctorId'] ? `${data['doctorId']}` : '';
      if (!doctorId || doctorId === 'null') {
        return null;
      }
      return {
        doctorId,
        reason: data['reason'] ? `${data['reason']}` : '',
        department: data['department'] ? `${data['department']}` : ''
      } as DoctorRecommendation;
    })
    .catch(() => null);
}

function normalizeConsultationStatus(status?: number): number {
  if (status === 49) {
    return 1;
  }
  if (status === 48) {
    return 0;
  }
  if (status === undefined) {
    return 0;
  }
  return status;
}

function statusText(status?: number): string {
  const normalizedStatus = normalizeConsultationStatus(status);
  if (normalizedStatus === 1) {
    return '已回复';
  }
  if (normalizedStatus === 2) {
    return '已关闭';
  }
  return '进行中';
}

export function buildConsultationSaveErrorMessage(payload: string): string {
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

export function buildConsultationSaveFailureText(errorMessage: string): string {
  const message = errorMessage.trim();
  if (message.indexOf('doctorId is required') >= 0) {
    return '请选择医生后再提交问诊。';
  }
  if (message.indexOf('userId is required') >= 0) {
    return '当前登录信息缺少用户编号，请重新登录后再提交。';
  }
  if (message.indexOf('symptom is required') >= 0) {
    return '请填写症状后再提交问诊。';
  }
  if (message.indexOf('description is required') >= 0) {
    return '请填写问诊描述后再提交。';
  }
  if (message.indexOf('content is required') >= 0) {
    return '请填写消息内容后再发送。';
  }
  if (message.indexOf('forbidden') >= 0 || message.indexOf('403') >= 0) {
    return '当前账号无权操作这条问诊，请确认已使用对应账号登录。';
  }
  return '问诊操作失败，请稍后重试。';
}

export function countOngoingConsultations(threads: ConsultationThread[]): number {
  return threads.filter((thread: ConsultationThread) => thread.statusCode === 0).length;
}

export function buildDoctorPendingNoticeTitle(threads: ConsultationThread[]): string {
  const ongoingCount = countOngoingConsultations(threads);
  if (ongoingCount > 0) {
    return `当前有 ${ongoingCount} 条待回复问诊`;
  }
  return '当前暂无待回复问诊';
}

export function buildDoctorOptionsFromPayload(payload: string): DoctorOption[] {
  return responseDataArray<DoctorProfilePayload>(payload).map((item: DoctorProfilePayload) => {
    const option: DoctorOption = {
      id: `${item.id ? item.id : item.userId ? item.userId : ''}`,
      userId: `${item.userId ? item.userId : ''}`,
      name: item.doctorName ? item.doctorName : '医生',
      title: item.title ? item.title : '',
      specialty: item.specialty ? item.specialty : '',
      introduction: item.introduction ? item.introduction : '',
      department: item.department ? item.department : '',
      avatar: item.avatar ? item.avatar : '',
      accepting: item.accepting === true
    };
    return option;
  }).filter((item: DoctorOption) => item.userId.length > 0);
}

export function buildConsultationThreadsFromPayload(payload: string): ConsultationThread[] {
  return responseDataArray<ConsultationPayload>(payload).map((item: ConsultationPayload) => {
    const normalizedStatus = normalizeConsultationStatus(item.status);
    const thread: ConsultationThread = {
      id: `${item.id ? item.id : ''}`,
      userId: `${item.userId ? item.userId : ''}`,
      doctorId: `${item.doctorId ? item.doctorId : ''}`,
      symptom: item.symptom ? item.symptom : '',
      description: item.description ? item.description : '',
      statusCode: normalizedStatus,
      statusText: statusText(normalizedStatus),
      createTime: item.createTime ? item.createTime : '',
      sharedName: item.sharedName ? item.sharedName : '',
      sharedAge: item.sharedAge ? item.sharedAge : 0,
      sharedGender: item.sharedGender ? item.sharedGender : '',
      sharedPhone: item.sharedPhone ? item.sharedPhone : '',
      healthSnapshot: item.healthSnapshot ? item.healthSnapshot : '',
      tongueImageUrls: item.tongueImageUrls ? item.tongueImageUrls : ''
    };
    return thread;
  }).filter((item: ConsultationThread) => item.id.length > 0);
}

export function buildConsultationMessagesFromPayload(payload: string): ConsultationMessageItem[] {
  return responseDataArray<ConsultationMessagePayload>(payload).map((item: ConsultationMessagePayload) => {
    const message: ConsultationMessageItem = {
      id: `${item.id ? item.id : ''}`,
      consultationId: `${item.consultationId ? item.consultationId : ''}`,
      senderId: `${item.senderId ? item.senderId : ''}`,
      senderRole: item.senderRole ? item.senderRole : 'USER',
      content: item.content ? item.content : '',
      createTime: item.createTime ? item.createTime : ''
    };
    return message;
  }).filter((item: ConsultationMessageItem) => item.id.length > 0);
}

export function fetchDoctorOptions(): Promise<DoctorOption[]> {
  return requestJson(buildApiUrl('/api/doctor-profile/list'), http.RequestMethod.GET)
    .then((payload: string) => buildDoctorOptionsFromPayload(payload));
}

export function fetchUserConsultations(userId: string): Promise<ConsultationThread[]> {
  return requestJson(buildApiUrl(`/api/consultation/list?userId=${encodeURIComponent(userId)}`), http.RequestMethod.GET)
    .then((payload: string) => buildConsultationThreadsFromPayload(payload));
}

export function fetchDoctorConsultations(doctorId: string): Promise<ConsultationThread[]> {
  return requestJson(buildApiUrl(`/api/consultation/list?doctorId=${encodeURIComponent(doctorId)}`), http.RequestMethod.GET)
    .then((payload: string) => buildConsultationThreadsFromPayload(payload));
}

export function fetchAdminConsultations(): Promise<ConsultationThread[]> {
  return requestJson(buildApiUrl('/api/consultation/list'), http.RequestMethod.GET)
    .then((payload: string) => buildConsultationThreadsFromPayload(payload));
}

export function fetchConsultationMessages(consultationId: string): Promise<ConsultationMessageItem[]> {
  return requestJson(buildApiUrl(`/api/consultation-message/list?consultationId=${encodeURIComponent(consultationId)}`), http.RequestMethod.GET)
    .then((payload: string) => buildConsultationMessagesFromPayload(payload));
}

export interface UserHealthArchive {
  realName: string;
  phone: string;
  gender: string;
  age: number;
  birthday: string;
  height: number;
  weight: number;
  allergyHistory: string;
  medicalHistory: string;
  healthGoal: string;
  constitutionType: string;
}

export function fetchUserHealthByConsultation(consultationId: string): Promise<UserHealthArchive | null> {
  return requestJson(buildApiUrl(`/api/consultation/user-health?consultationId=${encodeURIComponent(consultationId)}`), http.RequestMethod.GET)
    .then((payload: string) => {
      const resp = parseResponse(payload);
      if (resp.success !== true || !resp.data) {
        return null;
      }
      const data = resp.data as Object;
      const user = (data as Record<string, Object>)['user'] as Record<string, Object> | undefined;
      const archive = (data as Record<string, Object>)['healthArchive'] as Record<string, Object> | undefined;
      const result: UserHealthArchive = {
        realName: user && user['realName'] ? `${user['realName']}` : '',
        phone: user && user['phone'] ? `${user['phone']}` : '',
        gender: user && user['gender'] ? `${user['gender']}` : '',
        age: user && user['age'] ? Number(user['age']) : 0,
        birthday: user && user['birthday'] ? `${user['birthday']}` : '',
        height: archive && archive['height'] ? Number(archive['height']) : 0,
        weight: archive && archive['weight'] ? Number(archive['weight']) : 0,
        allergyHistory: archive && archive['allergyHistory'] ? `${archive['allergyHistory']}` : '',
        medicalHistory: archive && archive['medicalHistory'] ? `${archive['medicalHistory']}` : '',
        healthGoal: archive && archive['healthGoal'] ? `${archive['healthGoal']}` : '',
        constitutionType: archive && archive['constitutionType'] ? `${archive['constitutionType']}` : ''
      };
      return result;
    });
}

export function createConsultation(
  userId: string,
  doctorId: string,
  symptom: string,
  description: string,
  sharedName?: string,
  sharedAge?: number,
  sharedGender?: string,
  sharedPhone?: string,
  healthSnapshot?: string,
  tongueImageUrls?: string
): Promise<boolean> {
  const body: CreateConsultationPayload = {
    userId: Number(userId),
    doctorId: Number(doctorId),
    symptom,
    description,
    sharedName: sharedName && sharedName.length > 0 ? sharedName : '',
    sharedAge: sharedAge && sharedAge > 0 ? sharedAge : 0,
    sharedGender: sharedGender && sharedGender.length > 0 ? sharedGender : '',
    sharedPhone: sharedPhone && sharedPhone.length > 0 ? sharedPhone : '',
    healthSnapshot: healthSnapshot && healthSnapshot.length > 0 ? healthSnapshot : '',
    tongueImageUrls: tongueImageUrls && tongueImageUrls.length > 0 ? tongueImageUrls : ''
  };
  return requestJson(buildApiUrl('/api/consultation'), http.RequestMethod.POST, body).then((payload: string) => {
    const errorMessage = buildConsultationSaveErrorMessage(payload);
    if (errorMessage.length > 0) {
      return Promise.reject(new Error(errorMessage));
    }
    return true;
  });
}

export function sendConsultationMessage(consultationId: string, content: string): Promise<boolean> {
  const body: SendConsultationMessagePayload = {
    consultationId: Number(consultationId),
    content
  };
  return requestJson(buildApiUrl('/api/consultation-message'), http.RequestMethod.POST, body).then((payload: string) => {
    const errorMessage = buildConsultationSaveErrorMessage(payload);
    if (errorMessage.length > 0) {
      return Promise.reject(new Error(errorMessage));
    }
    return true;
  });
}

export function deleteConsultationMessage(messageId: string): Promise<boolean> {
  const config = getApiConfig();
  const request = http.createHttp();
  const url = buildApiUrl(`/api/consultation-message?id=${encodeURIComponent(messageId)}`);
  return request.request(url, {
    method: http.RequestMethod.DELETE,
    header: buildAuthorizedJsonHeaders(),
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

export function recallConsultationMessage(messageId: string): Promise<boolean> {
  const config = getApiConfig();
  const request = http.createHttp();
  const url = buildApiUrl(`/api/consultation-message/recall?id=${encodeURIComponent(messageId)}`);
  const body: EmptyBody = {};
  return request.request(url, {
    method: http.RequestMethod.PUT,
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
