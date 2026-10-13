import { GuideSlide } from '../model/WellnessModels';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  LINE_BG,
  MUTED_TEXT,
  PAGE_BG
} from '../theme/WellnessTheme';

@Component
export struct GuideView {
  @Link guideIndex: number;
  @Link hasEnteredApp: boolean;
  @Prop guideSlides: GuideSlide[];

  build() {
    Column() {
      Blank()
      Text('茹安阁')
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('本地记录驱动的日常养生助手')
        .fontSize(14)
        .fontColor(MUTED_TEXT)
        .margin({ top: 8, bottom: 30 })

      Column({ space: 14 }) {
        Text(this.guideSlides[this.guideIndex].title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(BRAND_GREEN)
        Text(this.guideSlides[this.guideIndex].description)
          .fontSize(15)
          .fontColor(DEEP_TEXT)
          .lineHeight(24)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding(24)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)

      Row({ space: 8 }) {
        ForEach(this.guideSlides, (slide: GuideSlide, index: number) => {
          Column()
            .width(this.guideIndex === index ? 24 : 8)
            .height(8)
            .backgroundColor(this.guideIndex === index ? BRAND_GREEN : LINE_BG)
            .borderRadius(4)
        }, (slide: GuideSlide) => slide.title)
      }
      .margin({ top: 22 })

      Blank()
      Button(this.guideIndex === this.guideSlides.length - 1 ? '进入应用' : '下一步')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor(BRAND_GREEN)
        .width('100%')
        .height(48)
        .borderRadius(CARD_RADIUS)
        .onClick(() => {
          if (this.guideIndex < this.guideSlides.length - 1) {
            this.guideIndex += 1;
          } else {
            this.hasEnteredApp = true;
          }
        })
      Button('跳过')
        .fontSize(14)
        .fontColor(MUTED_TEXT)
        .backgroundColor(PAGE_BG)
        .margin({ top: 8, bottom: 20 })
        .onClick(() => {
          this.hasEnteredApp = true;
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 22, right: 22 })
    .backgroundColor(Color.Transparent)
  }
}
