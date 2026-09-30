import { getEmptyStateInfo } from '../../services/EmptyStateService';
import {
  CARD_BG,
  CARD_RADIUS,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

@Component
export struct LoadStateNotice {
  @Prop message: string;

  build() {
    if (this.message.length > 0) {
      Column({ space: 6 }) {
        Text(getEmptyStateInfo('profileLoad').title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(WARM_ACCENT)
        Text(this.message)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .lineHeight(18)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(14)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
  }
}
