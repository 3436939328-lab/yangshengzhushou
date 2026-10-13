import {
  WARM_ACCENT
} from '../theme/WellnessTheme';

@Component
export struct AppHeader {
  @Prop riskLevel: string;

  build() {
    Row() {
      Column() {
        Text('茹安阁')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textShadow({ radius: 4, color: '#99000000', offsetY: 1 })
        Text('本地记录驱动的日常养生助手')
          .fontSize(13)
          .fontColor(Color.White)
          .textShadow({ radius: 4, color: '#99000000', offsetY: 1 })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.riskLevel)
        .fontSize(12)
        .fontColor(WARM_ACCENT)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor('#FFF2E8')
        .borderRadius(14)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 14 })
    .backgroundColor(Color.Transparent)
  }
}
