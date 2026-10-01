import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { getApiConfig } from '../services/ApiConfig';
import { saveConnectionSettings } from '../services/ConnectionSettings';
import { buildBackendStatusFromHealthPayload } from '../services/BackendStatusService';
import { discoverBackendOnLan } from '../services/BackendDiscoveryService';
import { BRAND_GREEN, DEEP_TEXT, MUTED_TEXT } from '../theme/WellnessTheme';

@Component
export struct ConnectionPanel {
  @State expanded: boolean = false;
  @State address: string = getApiConfig().baseUrl;
  @State message: string = '';
  @State busy: boolean = false;
  @State discovering: boolean = false;

  build() {
    Column({ space: 8 }) {
      Button('服务器连接设置')
        .fontSize(12).fontColor(MUTED_TEXT).backgroundColor(Color.Transparent)
        .onClick(() => { this.expanded = !this.expanded; })
      if (this.expanded) {
        Column({ space: 8 }) {
          Text('建议使用电脑名称（如 http://DESKTOP-ABC:8181）代替 IP，换网络后无需改地址。')
            .fontSize(11)
            .fontColor(MUTED_TEXT)
            .lineHeight(16)
            .width('100%')

          Row({ space: 8 }) {
            TextInput({ text: this.address, placeholder: 'http://电脑名或IP:8181' })
              .fontSize(13)
              .layoutWeight(1)
              .onChange((value: string) => { this.address = value; })
            Button(this.discovering ? '查找中' : '自动查找')
              .fontSize(12)
              .fontColor(BRAND_GREEN)
              .enabled(!this.discovering)
              .height(40)
              .onClick(() => { this.autoDiscover(); })
          }
          .width('100%')

          Button(this.busy ? '连接中' : '保存并测试连接')
            .fontSize(13).fontColor(BRAND_GREEN).enabled(!this.busy)
            .onClick(() => { this.saveAndTest(); })

          if (this.message.length > 0) {
            Text(this.message).fontSize(12).fontColor(DEEP_TEXT).width('100%')
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }.width('100%')
  }

  private async autoDiscover(): Promise<void> {
    this.discovering = true;
    this.message = '正在扫描局域网寻找养生助手后端...';
    try {
      const found = await discoverBackendOnLan();
      if (found.length > 0) {
        this.address = found;
        await saveConnectionSettings(this.getUIContext().getHostContext() as common.UIAbilityContext, found);
        this.message = `已自动找到后端：${found}，已保存。`;
      } else {
        this.message = '未在局域网找到后端，请确认 8181 服务已启动，且手机与电脑同一网络。';
      }
    } catch (error) {
      this.message = '查找失败，请手动输入电脑名或 IP 地址。';
    } finally {
      this.discovering = false;
    }
  }

  private async saveAndTest(): Promise<void> {
    this.busy = true;
    const request = http.createHttp();
    try {
      await saveConnectionSettings(this.getUIContext().getHostContext() as common.UIAbilityContext, this.address);
      const response = await request.request(`${getApiConfig().baseUrl}/api/health`, {
        method: http.RequestMethod.GET, connectTimeout: 6000, readTimeout: 6000
      });
      const available = response.responseCode === 200
        && buildBackendStatusFromHealthPayload(`${response.result}`).available;
      this.message = available ? '已保存，服务器连接成功' : '已保存，但服务器未返回有效状态';
    } catch (error) {
      this.message = '未连接成功，请检查地址、8181 服务和手机网络';
    } finally {
      request.destroy();
      this.busy = false;
    }
  }
}
