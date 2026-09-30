import { BRAND_GREEN, DEEP_TEXT } from '../../theme/WellnessTheme';

@Builder
export function SectionTitle(title: string) {
  Text(title)
    .fontSize(18)
    .fontWeight(FontWeight.Bold)
    .fontColor(DEEP_TEXT)
    .width('100%')
    .margin({ top: 4 })
}

@Builder
export function ActionChip(label: string) {
  Text(label)
    .fontSize(12)
    .fontColor(BRAND_GREEN)
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .backgroundColor('#EEF7F1')
    .borderRadius(14)
}
