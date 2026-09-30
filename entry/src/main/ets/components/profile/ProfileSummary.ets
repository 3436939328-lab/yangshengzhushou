import { HealthProfile } from '../../model/ProfileModels';
import { createProfileSummary, ProfileSummaryData } from '../../viewmodel/ProfileViewModel';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

@Component
export struct ProfileSummary {
  @Prop profile: HealthProfile;

  build() {
    Column({ space: 10 }) {
      Row() {
        Text('本地健康档案')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
        Text(this.summary().completenessText)
          .fontSize(12)
          .fontColor(BRAND_GREEN)
      }
      Text(`当前体质：${this.summary().constitutionName}`)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(DEEP_TEXT)
      Text('体质建议将由大模型结合天气和健康档案生成。')
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .lineHeight(20)
      Row({ space: 8 }) {
        this.StatChip(`问卷 ${this.summary().recordCount}`)
        this.StatChip(`舌象 ${this.summary().tongueNoteCount}`)
        this.StatChip(`提醒 ${this.summary().reminderEnabledCount}`)
      }
      Text(`更新于 ${this.summary().updatedAt}`)
        .fontSize(11)
        .fontColor(WARM_ACCENT)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  private summary(): ProfileSummaryData {
    return createProfileSummary(this.profile);
  }

  @Builder
  StatChip(label: string) {
    Text(label)
      .fontSize(12)
      .fontColor(BRAND_GREEN)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor('#EEF7F1')
      .borderRadius(14)
  }
}
