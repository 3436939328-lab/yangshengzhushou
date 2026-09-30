import { common } from '@kit.AbilityKit';
import { PendingOrderRepository } from '../../services/PendingOrderRepository';
import {
  RewardAccount, RewardProduct, RewardOrder, RewardLedger, CreateRewardOrder,
  getRewardAccount, checkIn, getRewardProducts, getRewardOrders, getRewardLedger,
  createRewardOrder, newRequestId, RemoteRequestError
} from '../../services/RewardsService';
import { BRAND_GREEN, DEEP_TEXT, MUTED_TEXT, WARM_ACCENT, CARD_BG } from '../../theme/WellnessTheme';
import { RewardAdminPanel } from './RewardAdminPanel';

@Component
export struct RewardsPanel {
  @Prop userId: string = '';
  @Prop isAdmin: boolean = false;
  @State account: RewardAccount = { balance: 0, reserved: 0, available: 0, checkedInToday: false, dailyCheckInPoints: 10, chatCost: 1 };
  @State products: RewardProduct[] = [];
  @State orders: RewardOrder[] = [];
  @State ledger: RewardLedger[] = [];
  @State tab: number = 0;
  @State busy: boolean = false;
  @State loaded: boolean = false;
  @State message: string = '';
  @State selected: RewardProduct | null = null;
  @State recipient: string = '';
  @State phone: string = '';
  @State address: string = '';
  @State confirmed: boolean = false;
  @State submitted: boolean = false;
  @State pendingStateReady: boolean = false;
  private orderRequestId: string = '';
  private pendingRepository?: PendingOrderRepository;
  private activeView: boolean = false;

  aboutToAppear(): void {
    this.activeView = true;
    this.pendingRepository = new PendingOrderRepository(this.getUIContext().getHostContext() as common.UIAbilityContext, this.userId);
    this.restoreAndRefresh();
  }
  aboutToDisappear(): void { this.activeView = false; }

  private async restoreAndRefresh(): Promise<void> {
    this.busy = true;
    this.pendingStateReady = false;
    try {
      if (this.pendingRepository) {
        const pending = await this.pendingRepository.load();
        if (!this.activeView) return;
        if (pending) {
          this.orderRequestId = pending.order.requestId;
          this.recipient = pending.order.recipient; this.phone = pending.order.phone; this.address = pending.order.address;
          this.selected = { id: pending.order.productId, name: pending.productName, points: pending.points,
            stock: 0, description: '', imageUrl: '', active: false };
          this.confirmed = true; this.submitted = true;
          this.message = '有一笔待确认兑换，请重试原订单以确认结果';
        }
      }
      await this.loadData();
      this.pendingStateReady = true;
    } catch (error) { this.message = (error as Error).message; }
    finally { this.busy = false; }
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('我的积分').fontSize(17).fontWeight(FontWeight.Bold).fontColor(DEEP_TEXT)
          Text(this.loaded ? `${this.account.available}` : '--').fontSize(26).fontWeight(FontWeight.Bold).fontColor(BRAND_GREEN)
          if (this.account.reserved > 0) {
            Text(`${this.account.reserved} 分用于正在生成的回答`).fontSize(12).fontColor(MUTED_TEXT)
          }
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Button(this.account.checkedInToday ? '今日已签到' : `签到 +${this.account.dailyCheckInPoints}`)
          .fontSize(13).fontColor(Color.White).backgroundColor(BRAND_GREEN)
          .enabled(this.loaded && !this.busy && !this.account.checkedInToday)
          .onClick(() => { this.doCheckIn(); })
      }.width('100%')
      Row() {
        ForEach(['物资兑换', '兑换记录', '积分明细'], (label: string, index: number) => {
          Button(label).fontSize(12).layoutWeight(1)
            .backgroundColor(this.tab === index ? '#E6F1EB' : Color.Transparent)
            .fontColor(this.tab === index ? BRAND_GREEN : MUTED_TEXT)
            .onClick(() => { this.tab = index; })
        })
      }.width('100%')
      if (this.message.length > 0) { Text(this.message).fontSize(12).fontColor(WARM_ACCENT).width('100%') }
      if (this.busy) { Text('正在更新…').fontSize(12).fontColor(MUTED_TEXT) }
      if (!this.loaded) { Button('重新加载').enabled(!this.busy).onClick(() => { this.refresh(); }) }
      if (this.tab === 0) {
        if (this.products.length === 0 && this.loaded) {
          Text('暂无可兑换物资').fontSize(14).fontColor(MUTED_TEXT).padding({ top: 10, bottom: 10 })
        }
        ForEach(this.products, (product: RewardProduct) => {
          Row({ space: 12 }) {
            if (product.imageUrl.length > 0) {
              Image(product.imageUrl).width(64).height(64).objectFit(ImageFit.Cover).borderRadius(8)
            }
            Column({ space: 4 }) {
              Text(product.name).fontSize(15).fontColor(DEEP_TEXT)
              Text(product.description).fontSize(12).fontColor(MUTED_TEXT)
              Text(`${product.points} 积分 · 剩余 ${product.stock}`).fontSize(12).fontColor(BRAND_GREEN)
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Button('兑换').fontSize(12).enabled(this.pendingStateReady && !this.busy && !this.submitted && product.stock > 0 && this.account.available >= product.points)
              .onClick(() => {
                this.selected = product; this.confirmed = false; this.submitted = false;
                this.orderRequestId = newRequestId(); this.message = '';
              })
          }.width('100%').padding(12).backgroundColor(CARD_BG).borderRadius(8)
        }, (product: RewardProduct) => `${product.id}`)
        if (this.selected !== null) { this.Checkout() }
      } else if (this.tab === 1) {
        if (this.orders.length === 0 && this.loaded) { Text('暂无兑换记录').fontColor(MUTED_TEXT).fontSize(14) }
        ForEach(this.orders, (order: RewardOrder) => {
          Column({ space: 6 }) {
            Text(`${order.productName} · ${order.points} 积分`).fontSize(15).fontColor(DEEP_TEXT)
            Text(order.status === 'SHIPPED' ? '已发货' : '待发货').fontSize(13).fontColor(BRAND_GREEN)
            Text(`${order.recipient} · ${order.phone}`).fontSize(12).fontColor(MUTED_TEXT)
            Text(order.address).fontSize(12).fontColor(MUTED_TEXT)
            if (order.trackingNumber) { Text(`${order.carrier || ''} ${order.trackingNumber}`).fontSize(12).fontColor(DEEP_TEXT) }
          }.alignItems(HorizontalAlign.Start).width('100%').padding(12).backgroundColor(CARD_BG).borderRadius(8)
        }, (order: RewardOrder) => order.id)
      } else {
        if (this.ledger.length === 0 && this.loaded) { Text('暂无积分明细').fontColor(MUTED_TEXT).fontSize(14) }
        ForEach(this.ledger, (entry: RewardLedger) => {
          Row() {
            Column({ space: 4 }) {
              Text(entry.type === 'CHECK_IN' ? '每日签到' : entry.type === 'CHAT' ? '养生问答' : '物资兑换').fontSize(14).fontColor(DEEP_TEXT)
              Text(new Date(entry.createdAt).toLocaleString()).fontSize(11).fontColor(MUTED_TEXT)
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text(`${entry.delta > 0 ? '+' : ''}${entry.delta}`).fontSize(15).fontColor(BRAND_GREEN)
          }.width('100%').padding({ top: 8, bottom: 8 })
        }, (entry: RewardLedger) => `${entry.id}`)
      }
      Button('刷新积分与记录').fontSize(12).enabled(!this.busy).backgroundColor(Color.Transparent)
        .onClick(() => { this.refresh(); })
      if (this.isAdmin) { RewardAdminPanel() }
    }.width('100%').alignItems(HorizontalAlign.Start).padding({ top: 12, bottom: 12 })
  }

  @Builder
  Checkout() {
    Column({ space: 8 }) {
      Text(`确认兑换：${this.selected ? this.selected.name : ''}`).fontSize(16).fontWeight(FontWeight.Bold)
      TextInput({ text: this.recipient, placeholder: '收货人' }).maxLength(80).enabled(!this.submitted)
        .onChange((value: string) => { this.recipient = value; this.confirmed = false; })
      TextInput({ text: this.phone, placeholder: '联系电话' }).type(InputType.PhoneNumber).maxLength(32).enabled(!this.submitted)
        .onChange((value: string) => { this.phone = value; this.confirmed = false; })
      TextArea({ text: this.address, placeholder: '省市区、街道与门牌号' }).maxLength(500).height(84).enabled(!this.submitted)
        .onChange((value: string) => { this.address = value; this.confirmed = false; })
      Row({ space: 8 }) {
        Checkbox().select(this.confirmed).enabled(!this.busy)
          .onChange((value: boolean) => { this.confirmed = value; })
        Text('确认物资、积分和收货信息').fontSize(13).layoutWeight(1)
      }
      Row({ space: 10 }) {
        Button('取消').enabled(!this.busy && !this.submitted).onClick(() => { this.selected = null; })
        Button(this.submitted ? '重试原订单' : '确认兑换').enabled(!this.busy && this.confirmed)
          .onClick(() => { this.submitOrder(); })
      }
    }.width('100%').padding({ top: 12, bottom: 12 })
  }

  private async loadData(): Promise<void> {
    this.account = await getRewardAccount();
    this.products = await getRewardProducts();
    this.orders = await getRewardOrders();
    this.ledger = await getRewardLedger();
    this.loaded = true;
  }
  private async refresh(): Promise<void> {
    if (this.busy) return;
    if (!this.pendingStateReady) { await this.restoreAndRefresh(); return; }
    this.busy = true; this.message = '';
    try { await this.loadData(); } catch (error) { this.message = (error as Error).message || '积分服务暂不可用'; }
    finally { this.busy = false; }
  }
  private async doCheckIn(): Promise<void> {
    if (this.busy) return;
    this.busy = true;
    try { this.account = await checkIn(); this.ledger = await getRewardLedger(); this.message = '签到成功'; }
    catch (error) { this.message = (error as Error).message; }
    finally { this.busy = false; }
  }
  private async submitOrder(): Promise<void> {
    if (!this.pendingStateReady || this.busy || this.selected === null || !this.confirmed) return;
    if (this.recipient.trim().length === 0 || this.phone.trim().length < 7 || this.address.trim().length < 6) {
      this.message = '请填写完整的收货信息'; return;
    }
    this.busy = true; this.submitted = true;
    const order: CreateRewardOrder = { requestId: this.orderRequestId, productId: this.selected.id,
      recipient: this.recipient.trim(), phone: this.phone.trim(), address: this.address.trim(), addressConfirmed: true };
    try {
      if (this.pendingRepository) {
        await this.pendingRepository.save({ order, productName: this.selected.name, points: this.selected.points });
      } else { throw new Error('无法保存兑换记录，请重试'); }
      if (!this.activeView) return;
      await createRewardOrder(order);
      await this.pendingRepository.clear();
      if (!this.activeView) return;
      this.selected = null; this.submitted = false; this.tab = 1; this.message = '兑换成功，等待发货';
      await this.loadData();
    } catch (error) {
      if (!this.activeView) return;
      if (error instanceof RemoteRequestError && [400, 402, 404, 409].indexOf(error.statusCode) >= 0 && this.pendingRepository) {
        try { await this.pendingRepository.clear(); this.submitted = false; } catch (storageError) { this.submitted = true; }
      }
      this.message = (error as Error).message || '请重试原订单以确认结果';
    }
    finally { this.busy = false; }
  }
}
