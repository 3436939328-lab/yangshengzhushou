import { common } from '@kit.AbilityKit';
import { PrivacyStatusItem } from '../../model/WellnessModels';
import { getPrivacyStatusItems, getPrivacySummary, getRuntimePrivacyStatusItems } from '../../services/PrivacyService';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

@Component
export struct PrivacyStatusCard {
  @State privacyItems: PrivacyStatusItem[] = getPrivacyStatusItems();

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    getRuntimePrivacyStatusItems(context).then((items: PrivacyStatusItem[]) => {
      this.privacyItems = items;
    }).catch(() => {
      this.privacyItems = getPrivacyStatusItems();
    });
  }

  build() {
    Column({ space: 12 }) {
      Text('隐私与数据安全')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(getPrivacySummary())
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .lineHeight(20)

      ForEach(this.items(), (item: PrivacyStatusItem) => {
        Row() {
          Column() {
            Text(item.title)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(DEEP_TEXT)
            Text(item.detail)
              .fontSize(12)
              .fontColor(MUTED_TEXT)
              .lineHeight(18)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(item.status)
            .fontSize(11)
            .fontColor(this.isAttentionStatus(item.status) ? WARM_ACCENT : BRAND_GREEN)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#EEF7F1')
            .borderRadius(10)
        }
        .width('100%')
      }, (item: PrivacyStatusItem) => item.title)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  private items(): PrivacyStatusItem[] {
    return this.privacyItems;
  }

  private isAttentionStatus(status: string): boolean {
    return status === '未开启' || status === '未授权' || status === '未配置' || status === '当前未使用';
  }
}
