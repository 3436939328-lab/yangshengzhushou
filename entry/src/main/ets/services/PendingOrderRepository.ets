import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { CreateRewardOrder } from './RewardsService';

export interface PendingRewardOrder { order: CreateRewardOrder; productName: string; points: number; }

export class PendingOrderRepository {
  private context: common.UIAbilityContext;
  private name: string;
  constructor(context: common.UIAbilityContext, userId: string) {
    this.context = context;
    this.name = `wellness_pending_order_${userId}`;
  }
  async load(): Promise<PendingRewardOrder | null> {
    const store = await preferences.getPreferences(this.context, { name: this.name });
    const raw = store.getSync('pending', '');
    if (typeof raw !== 'string' || raw.length === 0) return null;
    const pending = JSON.parse(raw) as PendingRewardOrder;
    if (!pending.order || !pending.order.requestId || !pending.order.productId) throw new Error('待确认订单记录无法读取');
    return pending;
  }
  async save(pending: PendingRewardOrder): Promise<void> {
    const store = await preferences.getPreferences(this.context, { name: this.name });
    await store.put('pending', JSON.stringify(pending));
    await store.flush();
  }
  async clear(): Promise<void> {
    const store = await preferences.getPreferences(this.context, { name: this.name });
    await store.delete('pending');
    await store.flush();
  }
}
