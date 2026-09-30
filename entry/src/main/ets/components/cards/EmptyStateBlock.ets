import { EmptyStateInfo } from '../../model/WellnessModels';
import { MUTED_TEXT, WARM_ACCENT } from '../../theme/WellnessTheme';

@Component
export struct EmptyStateBlock {
  @Prop info: EmptyStateInfo;

  build() {
    Column({ space: 6 }) {
      Text(this.info.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(WARM_ACCENT)
      Text(this.info.detail)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .lineHeight(20)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}
