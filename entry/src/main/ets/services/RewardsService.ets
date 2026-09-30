import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { getApiConfig, buildApiUrl } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

interface ApiEnvelope<T> { code: number; success?: boolean; message?: string; data: T; }
export class RemoteRequestError extends Error {
  statusCode: number;
  constructor(statusCode: number, message: string) { super(message); this.statusCode = statusCode; }
}
export interface RewardAccount {
  balance: number; reserved: number; available: number; checkedInToday: boolean;
  dailyCheckInPoints: number; chatCost: number;
}
export interface RewardProduct {
  id: number; name: string; description: string; imageUrl: string; points: number; stock: number; active: boolean;
}
export interface RewardOrder {
  id: string; productName: string; points: number; recipient: string; phone: string; address: string;
  status: string; createdAt: string; carrier?: string; trackingNumber?: string;
}
export interface RewardLedger { id: number; delta: number; type: string; reference: string; createdAt: string; }
export interface CreateRewardOrder {
  requestId: string; productId: number; recipient: string; phone: string; address: string; addressConfirmed: boolean;
}

export function newRequestId(): string { return util.generateRandomUUID(); }

export async function rewardRequest<T>(path: string, method: http.RequestMethod = http.RequestMethod.GET, body: string = ''): Promise<T> {
  const request = http.createHttp();
  try {
    const response = await request.request(buildApiUrl(path), {
      method, header: buildAuthorizedJsonHeaders(), extraData: body,
      connectTimeout: getApiConfig().timeoutMs, readTimeout: 15000
    });
    if (response.responseCode < 200 || response.responseCode >= 300) {
      throw new RemoteRequestError(response.responseCode, buildHttpFailureText(response.responseCode, `${response.result}`));
    }
    const envelope = JSON.parse(`${response.result}`) as ApiEnvelope<T>;
    if (envelope.code !== 200 && envelope.success !== true) throw new RemoteRequestError(envelope.code, envelope.message || '请求未完成');
    return envelope.data;
  } catch (error) {
    if (error instanceof RemoteRequestError) throw error;
    throw new Error(normalizeNetworkErrorMessage((error as Error).message));
  } finally { request.destroy(); }
}

export function getRewardAccount(): Promise<RewardAccount> { return rewardRequest<RewardAccount>('/api/rewards/account'); }
export function checkIn(): Promise<RewardAccount> {
  return rewardRequest<RewardAccount>('/api/rewards/check-in', http.RequestMethod.POST, JSON.stringify({ requestId: newRequestId() }));
}
export function getRewardProducts(): Promise<RewardProduct[]> { return rewardRequest<RewardProduct[]>('/api/rewards/products'); }
export function getRewardOrders(admin: boolean = false): Promise<RewardOrder[]> {
  return rewardRequest<RewardOrder[]>(admin ? '/api/rewards/admin/orders' : '/api/rewards/orders');
}
export function getRewardLedger(): Promise<RewardLedger[]> { return rewardRequest<RewardLedger[]>('/api/rewards/ledger'); }
export function createRewardOrder(order: CreateRewardOrder): Promise<RewardOrder> {
  return rewardRequest<RewardOrder>('/api/rewards/orders', http.RequestMethod.POST, JSON.stringify(order));
}
