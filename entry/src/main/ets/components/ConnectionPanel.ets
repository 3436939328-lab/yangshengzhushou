import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { getApiConfig } from '../services/ApiConfig';
import { saveConnectionSettings } from '../services/ConnectionSettings';
import { buildBackendStatusFromHealthPayload } from '../services/BackendStatusService';
import { BRAND_GREEN, DEEP_TEXT, MUTED_TEXT } from '../theme/WellnessTheme';

@Component
export struct ConnectionPanel {
  @State expanded: boolean = false;
  @State address: string = getApiConfig().baseUrl;
  @State message: string = '';
  @State busy: boolean = false;

  build() {
    Column({ space: 8 }) {
      Button('服务器连接设置')
        .fontSize(12).fontColor(MUTED_TEXT).backgroundColor(Color.Transparent)
        .onClick(() => { this.expanded = !this.expanded; })
      if (this.expanded) {
        TextInput({ text: this.address, placeholder: 'http://电脑局域网地址:8181' })
          .fontSize(13).onChange((value: string) => { this.address = value; })
        Button(this.busy ? '连接中' : '保存并测试连接')
          .fontSize(13).fontColor(BRAND_GREEN).enabled(!this.busy)
          .onClick(() => { this.saveAndTest(); })
        if (this.message.length > 0) {
          Text(this.message).fontSize(12).fontColor(DEEP_TEXT).width('100%')
        }
      }
    }.width('100%')
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
