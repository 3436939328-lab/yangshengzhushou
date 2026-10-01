import { http } from '@kit.NetworkKit';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

export interface DoctorReviewItem {
  id: number;
  doctorUserId: number;
  reviewerId?: number;
  status: string;
  reason?: string;
  version: number;
  createdAt?: string;
  submittedAt?: string;
  reviewedAt?: string;
}

export interface DoctorProfileSnapshot {
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

export interface DoctorQualificationData {
  profile?: DoctorProfileSnapshot;
  review?: DoctorReviewItem;
}

export interface AdminReviewDetail {
  review?: DoctorReviewItem;
  profile?: DoctorProfileSnapshot;
  history?: DoctorReviewItem[];
}

export interface AdminReviewListData {
  items: DoctorReviewItem[];
  page: number;
  pageSize: number;
  total: number;
}

interface ApiResponsePayload {
  success?: boolean;
  message?: string;
  data?: Object;
}

interface EmptyBody {}

interface AcceptingPayload {
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

function parseResponse(payload: string): ApiResponsePayload {
  return JSON.parse(payload) as ApiResponsePayload;
}

function ensureData(payload: string): Object {
  const response = parseResponse(payload);
  if (response.success !== true) {
    throw new Error(response.message ? response.message : 'request failed');
  }
  if (response.data === undefined || response.data === null) {
    const empty: EmptyBody = {};
    return empty;
  }
  return response.data;
}

export function fetchMyQualification(): Promise<DoctorQualificationData> {
  return requestJson(buildApiUrl('/api/doctor/qualification'), http.RequestMethod.GET)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as DoctorQualificationData;
    });
}

export function ensureDraft(): Promise<DoctorReviewItem> {
  const body: EmptyBody = {};
  return requestJson(buildApiUrl('/api/doctor-registration/drafts'), http.RequestMethod.POST, body)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as DoctorReviewItem;
    });
}

interface DraftUpdatePayload {
  doctorName: string;
  title: string;
  specialty: string;
  introduction: string;
  avatar?: string;
  department?: string;
  licenseNumber?: string;
  licenseImageUrls?: string;
}

export function saveDraft(reviewId: number, profile: DraftUpdatePayload): Promise<boolean> {
  return requestJson(buildApiUrl(`/api/doctor-registration/drafts/${reviewId}`), http.RequestMethod.PUT, profile as Object)
    .then((payload: string) => {
      const response = parseResponse(payload);
      return response.success === true;
    });
}

export function submitForReview(reviewId: number): Promise<DoctorReviewItem> {
  const body: EmptyBody = {};
  return requestJson(buildApiUrl(`/api/doctor-registration/drafts/${reviewId}/submit`), http.RequestMethod.POST, body)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as DoctorReviewItem;
    });
}

export function resubmitReview(): Promise<DoctorReviewItem> {
  const body: EmptyBody = {};
  return requestJson(buildApiUrl('/api/doctor/qualification/resubmissions'), http.RequestMethod.POST, body)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as DoctorReviewItem;
    });
}

export function updateAccepting(accepting: boolean): Promise<boolean> {
  const body: AcceptingPayload = { accepting };
  return requestJson(buildApiUrl('/api/doctor/availability'), http.RequestMethod.PUT, body)
    .then((payload: string) => {
      const response = parseResponse(payload);
      return response.success === true;
    });
}

export function fetchAdminReviewQueue(status: string, page: number, pageSize: number): Promise<AdminReviewListData> {
  const params: string[] = [];
  params.push(`page=${encodeURIComponent(page)}`);
  params.push(`pageSize=${encodeURIComponent(pageSize)}`);
  if (status.length > 0 && status !== 'ALL') {
    params.push(`status=${encodeURIComponent(status)}`);
  }
  const url = buildApiUrl(`/api/admin/doctor-reviews?${params.join('&')}`);
  return requestJson(url, http.RequestMethod.GET)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as AdminReviewListData;
    });
}

export function fetchAdminReviewDetail(reviewId: number): Promise<AdminReviewDetail> {
  return requestJson(buildApiUrl(`/api/admin/doctor-reviews/${reviewId}`), http.RequestMethod.GET)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as AdminReviewDetail;
    });
}

interface AdminDecisionPayload {
  result: string;
  reason: string;
  version: number;
}

export function submitAdminDecision(reviewId: number, result: string, reason: string, version: number): Promise<DoctorReviewItem> {
  const body: AdminDecisionPayload = { result, reason, version };
  return requestJson(buildApiUrl(`/api/admin/doctor-reviews/${reviewId}/decision`), http.RequestMethod.POST, body as Object)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as DoctorReviewItem;
    });
}
