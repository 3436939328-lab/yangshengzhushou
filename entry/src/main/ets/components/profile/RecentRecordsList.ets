import { HealthProfile } from '../../model/ProfileModels';
import {
  RecentRecordItem,
  buildRecentIndicatorRecords,
  buildRecentTongueRecords
} from '../../viewmodel/ProfileViewModel';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import { getEmptyStateInfo } from '../../services/EmptyStateService';
import { EmptyStateBlock } from '../cards/EmptyStateBlock';

@Component
export struct RecentRecordsList {
  @Prop profile: HealthProfile;
  onDeleteIndicator?: (recordedAt: string) => void;
  onDeleteTongueNote?: (recordedAt: string) => void;

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('最近记录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
        Text(`${this.indicatorRecords().length + this.tongueRecords().length}条`)
          .fontSize(12)
          .fontColor(BRAND_GREEN)
      }

      if (this.indicatorRecords().length === 0 && this.tongueRecords().length === 0) {
        EmptyStateBlock({ info: getEmptyStateInfo('records') })
      } else {
        if (this.indicatorRecords().length > 0) {
          this.RecordSection('健康指标', this.indicatorRecords(), 'indicator')
        }
        if (this.tongueRecords().length > 0) {
          this.RecordSection('舌象记录', this.tongueRecords(), 'tongue')
        }
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  private indicatorRecords(): RecentRecordItem[] {
    return buildRecentIndicatorRecords(this.profile, 3);
  }

  private tongueRecords(): RecentRecordItem[] {
    return buildRecentTongueRecords(this.profile, 3);
  }

  @Builder
  RecordSection(title: string, records: RecentRecordItem[], recordType: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(13)
        .fontColor(WARM_ACCENT)
      ForEach(records, (item: RecentRecordItem) => {
        this.RecordRow(item, recordType)
      }, (item: RecentRecordItem) => `${item.tag}-${item.title}-${item.recordedAt}`)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  RecordRow(item: RecentRecordItem, recordType: string) {
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
        Text(item.recordedAt)
          .fontSize(11)
          .fontColor(WARM_ACCENT)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Column({ space: 6 }) {
        Text(item.tag)
          .fontSize(11)
          .fontColor(BRAND_GREEN)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#EEF7F1')
          .borderRadius(10)
        Button('删除')
          .fontSize(11)
          .fontColor(WARM_ACCENT)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#FFF2E8')
          .borderRadius(10)
          .onClick(() => {
            if (recordType === 'indicator' && this.onDeleteIndicator) {
              this.onDeleteIndicator(item.recordedAt);
            } else if (recordType === 'tongue' && this.onDeleteTongueNote) {
              this.onDeleteTongueNote(item.recordedAt);
            }
          })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
  }
}
