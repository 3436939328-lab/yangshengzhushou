import { http } from '@kit.NetworkKit';
import { RewardProduct, RewardOrder, rewardRequest, getRewardOrders } from '../../services/RewardsService';
import { BRAND_GREEN, DEEP_TEXT, MUTED_TEXT, WARM_ACCENT } from '../../theme/WellnessTheme';

@Component
export struct RewardAdminPanel {
  @State open: boolean = false;
  @State products: RewardProduct[] = [];
  @State orders: RewardOrder[] = [];
  @State editingId: number = 0;
  @State name: string = '';
  @State description: string = '';
  @State imageUrl: string = '';
  @State points: string = '100';
  @State stock: string = '0';
  @State active: boolean = false;
  @State orderId: string = '';
  @State carrier: string = '';
  @State tracking: string = '';
  @State busy: boolean = false;
  @State message: string = '';

  build() {
    Column({ space: 10 }) {
      Button(this.open ? '收起物资管理' : '物资与发货管理').fontSize(13).backgroundColor(Color.Transparent)
        .onClick(() => { this.open = !this.open; if (this.open) this.load(); })
      if (this.open) {
        if (this.message.length > 0) { Text(this.message).fontSize(12).fontColor(WARM_ACCENT) }
        ForEach(this.products, (product: RewardProduct) => {
          Button(`${product.name} · 库存 ${product.stock} · ${product.active ? '上架' : '下架'}`)
            .fontSize(13).fontColor(DEEP_TEXT).enabled(!this.busy).onClick(() => {
              this.editingId = product.id; this.name = product.name; this.description = product.description;
              this.imageUrl = product.imageUrl; this.points = `${product.points}`; this.stock = `${product.stock}`; this.active = product.active;
            })
        }, (product: RewardProduct) => `${product.id}`)
        Text(this.editingId > 0 ? '编辑物资' : '新增物资').fontSize(16).fontWeight(FontWeight.Bold)
        TextInput({ text: this.name, placeholder: '物资名称' }).maxLength(100).onChange((value: string) => { this.name = value; })
        TextInput({ text: this.description, placeholder: '物资说明' }).maxLength(1000).onChange((value: string) => { this.description = value; })
        TextInput({ text: this.imageUrl, placeholder: '图片 HTTPS 地址（选填）' }).onChange((value: string) => { this.imageUrl = value; })
        Row({ space: 8 }) {
          Text('积分').fontSize(12)
          TextInput({ text: this.points }).type(InputType.Number).layoutWeight(1).onChange((value: string) => { this.points = value; })
          Text('库存').fontSize(12)
          TextInput({ text: this.stock }).type(InputType.Number).layoutWeight(1).onChange((value: string) => { this.stock = value; })
        }
        Row({ space: 8 }) {
          Text('上架').fontSize(13)
          Toggle({ type: ToggleType.Switch, isOn: this.active }).onChange((value: boolean) => { this.active = value; })
          Button('保存').enabled(!this.busy).onClick(() => { this.saveProduct(); })
          Button('新增').enabled(!this.busy).onClick(() => {
            this.editingId = 0; this.name = ''; this.description = ''; this.imageUrl = ''; this.stock = '0'; this.active = false;
          })
        }
        Text('待发货订单').fontSize(16).fontWeight(FontWeight.Bold)
        ForEach(this.orders.filter((order: RewardOrder) => order.status === 'PENDING'), (order: RewardOrder) => {
          Column({ space: 4 }) {
            Text(order.productName).fontSize(14).fontColor(DEEP_TEXT)
            Text(`${order.recipient} ${order.phone}\n${order.address}`).fontSize(12).fontColor(MUTED_TEXT)
            Button('填写发货信息').fontSize(12).enabled(!this.busy)
              .onClick(() => { this.orderId = order.id; this.carrier = ''; this.tracking = ''; })
          }.width('100%').alignItems(HorizontalAlign.Start)
        }, (order: RewardOrder) => order.id)
        if (this.orderId.length > 0) {
          TextInput({ text: this.carrier, placeholder: '快递公司' }).onChange((value: string) => { this.carrier = value; })
          TextInput({ text: this.tracking, placeholder: '运单号' }).onChange((value: string) => { this.tracking = value; })
          Button('确认发货').enabled(!this.busy).onClick(() => { this.fulfill(); })
        }
      }
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
  private async load(): Promise<void> {
    this.busy = true;
    try {
      this.products = await rewardRequest<RewardProduct[]>('/api/rewards/admin/products');
      this.orders = await getRewardOrders(true);
    } catch (error) { this.message = (error as Error).message; }
    finally { this.busy = false; }
  }
  private async saveProduct(): Promise<void> {
    if (this.busy) return;
    const points = Number(this.points); const stock = Number(this.stock);
    if (this.name.trim().length === 0 || !Number.isInteger(points) || points < 1 || !Number.isInteger(stock) || stock < 0) {
      this.message = '请填写名称、正整数积分和非负整数库存'; return;
    }
    this.busy = true;
    try {
      await rewardRequest<RewardProduct>(`/api/rewards/admin/products${this.editingId > 0 ? '/' + this.editingId : ''}`,
        this.editingId > 0 ? http.RequestMethod.PUT : http.RequestMethod.POST,
        JSON.stringify({ name: this.name.trim(), description: this.description, imageUrl: this.imageUrl, points, stock, active: this.active }));
      this.message = '物资已保存'; await this.load();
    } catch (error) { this.message = (error as Error).message; }
    finally { this.busy = false; }
  }
  private async fulfill(): Promise<void> {
    if (this.busy || this.carrier.trim().length === 0 || this.tracking.trim().length === 0) return;
    this.busy = true;
    try {
      await rewardRequest<RewardOrder>(`/api/rewards/admin/orders/${this.orderId}/fulfill`, http.RequestMethod.POST,
        JSON.stringify({ carrier: this.carrier.trim(), trackingNumber: this.tracking.trim() }));
      this.orderId = ''; this.message = '已登记发货'; await this.load();
    } catch (error) { this.message = (error as Error).message; }
    finally { this.busy = false; }
  }
}
