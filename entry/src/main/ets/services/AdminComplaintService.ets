import { http } from '@kit.NetworkKit';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

export interface ComplaintItem {
  id: number;
  eventId: number;
  reporterId: number;
  description: string;
  status: string;
  assigneeId?: number;
  mergedIntoId?: number;
  createdAt?: string;
  updatedAt?: string;
  version: number;
}

export interface ComplaintEventItem {
  id: number;
  doctorId: number;
  consultationId?: number;
  category: string;
  effectiveDecision?: string;
  decisionAt?: string;
  policyVersion: number;
  createdAt?: string;
}

export interface ComplaintEvidenceItem {
  id: number;
  complaintId: number;
  uploaderId: number;
  summary?: string;
  createdAt?: string;
}

export interface ComplaintDecisionItem {
  id: number;
  eventId: number;
  reviewerId: number;
  result: string;
  severity?: string;
  reason?: string;
  createdAt?: string;
}

export interface DoctorSanctionItem {
  id: number;
  eventId: number;
  decisionId?: number;
  doctorId: number;
  type: string;
  scope: string;
  status: string;
  startsAt?: string;
  endsAt?: string;
  issuerId: number;
  approverId?: number;
  reason?: string;
  createdAt?: string;
}

export interface ComplaintDetail {
  complaint?: ComplaintItem;
  event?: ComplaintEventItem;
  evidence?: ComplaintEvidenceItem[];
  decisions?: ComplaintDecisionItem[];
  sanctions?: DoctorSanctionItem[];
}

export interface ComplaintListData {
  items: ComplaintItem[];
  page: number;
  pageSize: number;
  total: number;
}

export interface AppealItem {
  id: number;
  decisionId: number;
  doctorId: number;
  status: string;
  reason?: string;
  reviewerId?: number;
  resultReason?: string;
  createdAt?: string;
  reviewedAt?: string;
  version: number;
}

export interface AppealDetail {
  appeal?: AppealItem;
  originalDecision?: ComplaintDecisionItem;
  event?: ComplaintEventItem;
  complaint?: ComplaintItem;
  sanctions?: DoctorSanctionItem[];
}

export interface AppealListData {
  items: AppealItem[];
  page: number;
  pageSize: number;
  total: number;
}

export interface SanctionListData {
  items: DoctorSanctionItem[];
  total: number;
}

interface ApiResponsePayload {
  success?: boolean;
  message?: string;
  data?: Object;
}

interface EmptyBody {}

interface ComplaintActionPayload {
  action: string;
  reason: string;
  version: number;
  targetEventId?: number;
}

interface ComplaintDecisionPayload {
  result: string;
  severity: string;
  reason: string;
  version: number;
  sanction?: Object;
}

interface AppealReviewPayload {
  decision: string;
  reason: string;
  version: number;
}

interface SanctionApprovePayload {
  reason: string;
}

export interface SanctionPayload {
  type?: string;
  scope?: string;
  endsAt?: string;
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

export function fetchAdminComplaints(status: string, page: number, pageSize: number): Promise<ComplaintListData> {
  const params: string[] = [];
  params.push(`page=${encodeURIComponent(page)}`);
  params.push(`pageSize=${encodeURIComponent(pageSize)}`);
  if (status.length > 0 && status !== 'ALL') {
    params.push(`status=${encodeURIComponent(status)}`);
  }
  const url = buildApiUrl(`/api/admin/complaints?${params.join('&')}`);
  return requestJson(url, http.RequestMethod.GET)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as ComplaintListData;
    });
}

export function fetchAdminComplaintDetail(complaintId: number): Promise<ComplaintDetail> {
  return requestJson(buildApiUrl(`/api/admin/complaints/${complaintId}`), http.RequestMethod.GET)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as ComplaintDetail;
    });
}

export function submitComplaintAction(complaintId: number, action: string, reason: string, version: number, targetEventId?: number): Promise<ComplaintItem> {
  const body: ComplaintActionPayload = { action, reason, version };
  if (targetEventId !== undefined) {
    body.targetEventId = targetEventId;
  }
  return requestJson(buildApiUrl(`/api/admin/complaints/${complaintId}/action`), http.RequestMethod.POST, body as Object)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as ComplaintItem;
    });
}

export function submitComplaintDecision(complaintId: number, result: string, severity: string, reason: string, version: number, sanction?: SanctionPayload): Promise<ComplaintItem> {
  const body: ComplaintDecisionPayload = { result, severity, reason, version };
  if (sanction) {
    body.sanction = sanction as Object;
  }
  return requestJson(buildApiUrl(`/api/admin/complaints/${complaintId}/decision`), http.RequestMethod.POST, body as Object)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as ComplaintItem;
    });
}

export function fetchAdminAppeals(status: string, page: number, pageSize: number): Promise<AppealListData> {
  const params: string[] = [];
  params.push(`page=${encodeURIComponent(page)}`);
  params.push(`pageSize=${encodeURIComponent(pageSize)}`);
  if (status.length > 0 && status !== 'ALL') {
    params.push(`status=${encodeURIComponent(status)}`);
  }
  const url = buildApiUrl(`/api/admin/appeals?${params.join('&')}`);
  return requestJson(url, http.RequestMethod.GET)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as AppealListData;
    });
}

export function fetchAdminAppealDetail(appealId: number): Promise<AppealDetail> {
  return requestJson(buildApiUrl(`/api/admin/appeals/${appealId}`), http.RequestMethod.GET)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as AppealDetail;
    });
}

export function submitAppealReview(appealId: number, decision: string, reason: string, version: number): Promise<AppealItem> {
  const body: AppealReviewPayload = { decision, reason, version };
  return requestJson(buildApiUrl(`/api/admin/appeals/${appealId}/review`), http.RequestMethod.POST, body as Object)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as AppealItem;
    });
}

export function fetchAdminSanctions(doctorId: number): Promise<SanctionListData> {
  const url = buildApiUrl(`/api/admin/sanctions?doctorId=${encodeURIComponent(doctorId)}`);
  return requestJson(url, http.RequestMethod.GET)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as SanctionListData;
    });
}

export function approvePermanentBan(sanctionId: number, reason: string): Promise<DoctorSanctionItem> {
  const body: SanctionApprovePayload = { reason };
  return requestJson(buildApiUrl(`/api/admin/sanctions/${sanctionId}/approve`), http.RequestMethod.POST, body as Object)
    .then((payload: string) => {
      const data = ensureData(payload);
      return data as DoctorSanctionItem;
    });
}
