import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  MUTED_TEXT
} from '../../theme/WellnessTheme';

@Component
export struct AdminSummaryCard {
  @Prop title: string;
  @Prop value: string;

  build() {
    Column({ space: 4 }) {
      Text(this.value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(BRAND_GREEN)
      Text(this.title)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(74)
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }
}
