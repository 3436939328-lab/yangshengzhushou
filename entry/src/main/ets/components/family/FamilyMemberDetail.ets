import {
  FamilyMemberCard,
  FamilyRelationStatus
} from '../tabs/FamilyTab';
import {
  HealthCardSummary,
  MetricCode,
  AssessmentState
} from '../../model/ProfileModels';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

interface DetailTabItem {
  key: string;
  label: string;
}

interface HealthRecordItem {
  label: string;
  value: string;
  time: string;
  status: string;
}

interface HealthRecordTypeItem {
  type: string;
  value: string;
  time: string;
  status: string;
}

interface HealthRecordGroup {
  date: string;
  records: HealthRecordTypeItem[];
}

/**
 * 亲人详情页
 * 展示亲人的健康数据详情、历史记录、关怀操作
 */
@Component
export struct FamilyMemberDetail {
  @Prop member: FamilyMemberCard | null = null;
  @Prop healthCard: HealthCardSummary | null = null;
  @Prop isLoading: boolean = false;

  @State activeTab: 'overview' | 'history' | 'settings' = 'overview';
  @State showCareSheet: boolean = false;
  @State careMessage: string = '';
  @State careSending: boolean = false;

  onBack?: () => void;
  onSendCare?: (message: string) => Promise<boolean>;
  onViewSettings?: () => void;
  onViewCategoryDetail?: (category: string) => void;

  build() {
    Column() {
      if (this.member) {

    Column({ space: 0 }) {
      // 头部
      this.HeaderSection()

      // Tab 切换
      this.TabBar()

      // 内容区域
      Scroll() {
        Column({ space: 14 }) {
          if (this.activeTab === 'overview') {
            this.OverviewTab()
          } else if (this.activeTab === 'history') {
            this.HistoryTab()
          } else if (this.activeTab === 'settings') {
            this.SettingsTab()
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F9F8')
      }
    }
  }

  // ==================== 头部 ====================

  @Builder
  HeaderSection() {
    Column({ space: 12 }) {
      Row() {
        Text('← 返回')
          .fontSize(15)
          .fontColor(Color.White)
          .onClick(() => {
            if (this.onBack) this.onBack();
          })
        Blank()
          .layoutWeight(1)
        Text('⚙️ 设置')
          .fontSize(14)
          .fontColor(Color.White)
          .onClick(() => {
            this.activeTab = 'settings';
            if (this.onViewSettings) this.onViewSettings();
          })
      }
      .width('100%')

      Row({ space: 14 }) {
        // 头像
        Circle({ width: 60, height: 60 })
          .fill(Color.White)
          .stroke(BRAND_GREEN)
          .strokeWidth(3)

        Column({ space: 4 }) {
          Text(this.member?.displayName || '')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(`${this.member?.relationLabel || ''} · 最近更新 ${this.member?.lastUpdateTime || ''}`)
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.8)')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 关注项摘要
      if (this.member && this.member.attentionCount > 0) {
        Row({ space: 10 }) {
          Column({ space: 2 }) {
            Text(`${this.member.attentionCount}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text('项需关注')
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.8)')
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 8, bottom: 8, left: 14, right: 14 })
          .backgroundColor('rgba(255, 255, 255, 0.2)')
          .borderRadius(12)

          Button() {
            Text('💌 发送关怀')
              .fontSize(13)
              .fontColor(BRAND_GREEN)
              .fontWeight(FontWeight.Medium)
          }
          .height(36)
          .backgroundColor(Color.White)
          .borderRadius(18)
          .onClick(() => {
            this.showCareSheet = true;
          })
        }
      } else {
        Button() {
          Text('💌 发送关怀')
            .fontSize(13)
            .fontColor(BRAND_GREEN)
            .fontWeight(FontWeight.Medium)
        }
        .height(36)
        .backgroundColor(Color.White)
        .borderRadius(18)
        .onClick(() => {
          this.showCareSheet = true;
        })
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 14, bottom: 20 })
    .backgroundColor(BRAND_GREEN)
  }

  // ==================== Tab Bar ====================

  @Builder
  TabBar() {
    Row() {
      ForEach(
        [
          { key: 'overview', label: '健康概览' } as DetailTabItem,
          { key: 'history', label: '历史记录' } as DetailTabItem,
          { key: 'settings', label: '共享设置' } as DetailTabItem
        ],
        (tab: DetailTabItem) => {
          Column({ space: 4 }) {
            Text(tab.label)
              .fontSize(14)
              .fontColor(this.activeTab === tab.key ? BRAND_GREEN : MUTED_TEXT)
              .fontWeight(this.activeTab === tab.key ? FontWeight.Medium : FontWeight.Normal)
            Column()
              .width(this.activeTab === tab.key ? 24 : 0)
              .height(3)
              .backgroundColor(BRAND_GREEN)
              .borderRadius(1.5)
          }
          .layoutWeight(1)
          .height(44)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.activeTab = tab.key as 'overview' | 'history' | 'settings';
          })
        },
        (tab: DetailTabItem) => tab.key
      )
    }
    .width('100%')
    .backgroundColor(Color.White)
  }

  // ==================== 健康概览 ====================

  @Builder
  OverviewTab() {
    Column({ space: 14 }) {
      // 健康卡摘要
      this.HealthSummaryCard()

      // 各指标详情
      this.MetricDetailsSection()

      // 最近记录
      this.RecentRecordsSection()
    }
    .width('100%')
  }

  @Builder
  HealthSummaryCard() {
    if (!this.healthCard) {
      Column({ space: 8 }) {
        Text('📊')
          .fontSize(36)
        Text('暂无健康数据')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
        Text('对方尚未共享健康数据或暂无记录')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')
      .padding({ top: 24, bottom: 24 })
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
      .alignItems(HorizontalAlign.Center)
    } else {

    Column({ space: 14 }) {
      Row() {
        Text('健康概览')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .layoutWeight(1)
        Text(`更新于 ${this.formatTime(this.healthCard.generatedAt)}`)
          .fontSize(11)
          .fontColor(MUTED_TEXT)
      }

      // 4 格摘要
      Grid() {
        GridItem() {
          this.MetricSummaryCell(
            '血压',
            this.healthCard.bloodPressure
              ? `${this.healthCard.bloodPressure.systolic}/${this.healthCard.bloodPressure.diastolic}`
              : '--',
            this.healthCard.bloodPressure?.stateText || '未记录',
            this.healthCard.bloodPressure?.state === AssessmentState.IN_RANGE
              ? BRAND_GREEN
              : this.healthCard.bloodPressure?.state === AssessmentState.ATTENTION
              ? WARM_ACCENT
              : MUTED_TEXT
          )
        }

        GridItem() {
          this.MetricSummaryCell(
            '血糖',
            this.healthCard.bloodSugar ? `${this.healthCard.bloodSugar.value}` : '--',
            this.healthCard.bloodSugar?.stateText || '未记录',
            this.healthCard.bloodSugar?.state === AssessmentState.IN_RANGE
              ? BRAND_GREEN
              : this.healthCard.bloodSugar?.state === AssessmentState.ATTENTION
              ? WARM_ACCENT
              : MUTED_TEXT
          )
        }

        GridItem() {
          this.MetricSummaryCell(
            '心率',
            this.healthCard.heartRate ? `${this.healthCard.heartRate.value}` : '--',
            this.healthCard.heartRate?.stateText || '未记录',
            this.healthCard.heartRate?.state === AssessmentState.IN_RANGE
              ? BRAND_GREEN
              : this.healthCard.heartRate?.state === AssessmentState.ATTENTION
              ? WARM_ACCENT
              : MUTED_TEXT
          )
        }

        GridItem() {
          this.MetricSummaryCell(
            '睡眠',
            this.healthCard.sleep ? `${Math.floor(this.healthCard.sleep.totalMinutes / 60)}h` : '--',
            this.healthCard.sleep?.stateText || '未记录',
            this.healthCard.sleep?.state === AssessmentState.IN_RANGE
              ? BRAND_GREEN
              : this.healthCard.sleep?.state === AssessmentState.ATTENTION
              ? WARM_ACCENT
              : MUTED_TEXT
          )
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(10)
      .columnsGap(10)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
    }
  }

  @Builder
  MetricSummaryCell(label: string, value: string, status: string, statusColor: ResourceColor) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(statusColor)
      Text(label)
        .fontSize(12)
        .fontColor(DEEP_TEXT)
      Text(status)
        .fontSize(11)
        .fontColor(MUTED_TEXT)
    }
    .width('100%')
    .height(80)
    .backgroundColor('#FAFAFA')
    .borderRadius(10)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MetricDetailsSection() {
    if (this.healthCard) {

    Column({ space: 10 }) {
      Text('指标详情')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
        .width('100%')

      Column({ space: 0 }) {
        if (this.healthCard.bloodPressure) {
          this.MetricDetailRow(
            '血压',
            `${this.healthCard.bloodPressure.systolic}/${this.healthCard.bloodPressure.diastolic} mmHg`,
            this.healthCard.bloodPressure.stateText,
            this.healthCard.bloodPressure.state === AssessmentState.IN_RANGE ? BRAND_GREEN : WARM_ACCENT,
            this.healthCard.bloodPressure.measuredAt,
            'bloodPressure'
          )
        }

        if (this.healthCard.bloodSugar) {
          this.MetricDetailRow(
            '血糖',
            `${this.healthCard.bloodSugar.value} mmol/L · ${this.healthCard.bloodSugar.typeText}`,
            this.healthCard.bloodSugar.stateText,
            this.healthCard.bloodSugar.state === AssessmentState.IN_RANGE ? BRAND_GREEN : WARM_ACCENT,
            this.healthCard.bloodSugar.measuredAt,
            'bloodSugar'
          )
        }

        if (this.healthCard.heartRate) {
          this.MetricDetailRow(
            '心率',
            `${this.healthCard.heartRate.value} 次/分`,
            this.healthCard.heartRate.stateText,
            this.healthCard.heartRate.state === AssessmentState.IN_RANGE ? BRAND_GREEN : WARM_ACCENT,
            this.healthCard.heartRate.measuredAt,
            'heartRate'
          )
        }

        if (this.healthCard.bloodOxygen) {
          this.MetricDetailRow(
            '血氧',
            `${this.healthCard.bloodOxygen.value}%`,
            this.healthCard.bloodOxygen.stateText,
            this.healthCard.bloodOxygen.state === AssessmentState.IN_RANGE ? BRAND_GREEN : WARM_ACCENT,
            this.healthCard.bloodOxygen.measuredAt,
            'bloodOxygen'
          )
        }

        if (this.healthCard.temperature) {
          this.MetricDetailRow(
            '体温',
            `${this.healthCard.temperature.value}℃`,
            this.healthCard.temperature.stateText,
            this.healthCard.temperature.state === AssessmentState.IN_RANGE ? BRAND_GREEN : WARM_ACCENT,
            this.healthCard.temperature.measuredAt,
            'temperature'
          )
        }

        if (this.healthCard.sleep) {
          this.MetricDetailRow(
            '睡眠',
            this.healthCard.sleep.totalText,
            this.healthCard.sleep.stateText,
            this.healthCard.sleep.state === AssessmentState.IN_RANGE ? BRAND_GREEN : WARM_ACCENT,
            this.healthCard.sleep.measuredAt,
            'sleep'
          )
        }

        if (this.healthCard.body) {
          this.MetricDetailRow(
            '体重/BMI',
            `${this.healthCard.body.weightKg}kg · BMI ${this.healthCard.body.bmi}`,
            this.healthCard.body.stateText,
            this.healthCard.body.state === AssessmentState.IN_RANGE ? BRAND_GREEN : WARM_ACCENT,
            this.healthCard.body.measuredAt,
            'body'
          )
        }
      }
      .width('100%')
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
    }
  }

  @Builder
  MetricDetailRow(
    label: string,
    value: string,
    status: string,
    statusColor: ResourceColor,
    time: string,
    key: string
  ) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .width(80)

      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(DEEP_TEXT)
        .layoutWeight(1)

      Column({ space: 2 }) {
        Text(status)
          .fontSize(12)
          .fontColor(statusColor)
        Text(this.formatTime(time))
          .fontSize(10)
          .fontColor(MUTED_TEXT)
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
    .onClick(() => {
      if (this.onViewCategoryDetail) {
        this.onViewCategoryDetail(key);
      }
    })
  }

  @Builder
  RecentRecordsSection() {
    Column({ space: 10 }) {
      Text('最近记录')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
        .width('100%')

      Column({ space: 0 }) {
        ForEach(
          [
            { label: '血压记录', value: '142/88 mmHg', time: '今天 07:30', status: '偏高' } as HealthRecordItem,
            { label: '血糖记录', value: '7.2 mmol/L (空腹)', time: '今天 07:00', status: '偏高' } as HealthRecordItem,
            { label: '睡眠记录', value: '6小时', time: '昨晚', status: '偏少' } as HealthRecordItem,
          ],
          (item: HealthRecordItem) => {
            Row() {
              Text(item.label)
                .fontSize(13)
                .fontColor(DEEP_TEXT)
                .layoutWeight(1)
              Text(item.value)
                .fontSize(13)
                .fontColor(MUTED_TEXT)
                .margin({ right: 12 })
              Text(item.time)
                .fontSize(12)
                .fontColor(MUTED_TEXT)
                .width(80)
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .height(44)
            .padding({ left: 16, right: 16 })
            .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
          },
          (item: HealthRecordItem) => item.label
        )
      }
      .width('100%')
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
  }

  // ==================== 历史记录 ====================

  @Builder
  HistoryTab() {
    Column({ space: 14 }) {
      Text('历史记录')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
        .width('100%')

      // 按日期分组的历史记录（简化版）
      ForEach(
        [
          {
            date: '今天',
            records: [
              { type: '血压', value: '142/88 mmHg', time: '07:30', status: '偏高' } as HealthRecordTypeItem,
              { type: '血糖', value: '7.2 mmol/L', time: '07:00', status: '偏高' } as HealthRecordTypeItem,
              { type: '心率', value: '76 次/分', time: '07:30', status: '正常' } as HealthRecordTypeItem,
            ]
          } as HealthRecordGroup,
          {
            date: '昨天',
            records: [
              { type: '血压', value: '138/86 mmHg', time: '08:00', status: '正常' } as HealthRecordTypeItem,
              { type: '睡眠', value: '6小时30分', time: '昨晚', status: '偏少' } as HealthRecordTypeItem,
              { type: '步数', value: '5,280 步', time: '全天', status: '' } as HealthRecordTypeItem,
            ]
          } as HealthRecordGroup,
          {
            date: '2026-09-27',
            records: [
              { type: '血压', value: '135/85 mmHg', time: '07:45', status: '正常' } as HealthRecordTypeItem,
              { type: '体重', value: '68.5 kg', time: '07:00', status: '正常' } as HealthRecordTypeItem,
            ]
          } as HealthRecordGroup,
        ],
        (group: HealthRecordGroup) => {
          Column({ space: 8 }) {
            Text(group.date)
              .fontSize(13)
              .fontColor(MUTED_TEXT)
              .fontWeight(FontWeight.Medium)

            Column({ space: 0 }) {
              ForEach(
                group.records,
                (record: HealthRecordTypeItem) => {
                  Row() {
                    Text(record.type)
                      .fontSize(14)
                      .fontColor(DEEP_TEXT)
                      .width(60)
                    Text(record.value)
                      .fontSize(14)
                      .fontColor(DEEP_TEXT)
                      .layoutWeight(1)
                    Text(record.time)
                      .fontSize(12)
                      .fontColor(MUTED_TEXT)
                      .margin({ right: 8 })
                    if (record.status) {
                      Text(record.status)
                        .fontSize(11)
                        .fontColor(record.status === '正常' ? BRAND_GREEN : WARM_ACCENT)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .backgroundColor(
                          record.status === '正常'
                            ? 'rgba(76, 175, 80, 0.1)'
                            : 'rgba(255, 152, 0, 0.1)'
                        )
                        .borderRadius(6)
                    }
                  }
                  .width('100%')
                  .height(44)
                  .padding({ left: 14, right: 14 })
                  .backgroundColor(CARD_BG)
                  .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
                },
                (record: HealthRecordTypeItem) =>
                  record.type + record.time
              )
            }
            .borderRadius(CARD_RADIUS)
          }
          .width('100%')
        },
        (group: HealthRecordGroup) => group.date
      )
    }
    .width('100%')
  }

  // ==================== 设置 ====================

  @Builder
  SettingsTab() {
    Column({ space: 14 }) {
      Text('关系设置')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
        .width('100%')

      Column({ space: 0 }) {
        this.SettingRow('共享设置', '管理我对TA的共享授权', () => {
          if (this.onViewSettings) this.onViewSettings();
        })
        this.SettingRow('修改称呼', '修改对方的显示名称', () => {})
        this.SettingRow('解除关系', '解除亲人关系，停止所有数据共享', () => {}, true)
      }
      .width('100%')
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
    .width('100%')
  }

  @Builder
  SettingRow(label: string, subtitle: string, onClick: () => void, isDanger: boolean = false) {
    Row() {
      Column({ space: 3 }) {
        Text(label)
          .fontSize(15)
          .fontColor(isDanger ? '#E53935' : DEEP_TEXT)
          .fontWeight(FontWeight.Medium)
        Text(subtitle)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(18)
        .fontColor(MUTED_TEXT)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
    .onClick(() => {
      onClick();
    })
  }

  // ==================== 工具方法 ====================

  private formatTime(isoTime: string): string {
    if (!isoTime) return '';
    try {
      const date = new Date(isoTime);
      const now = new Date();
      const diffMs = now.getTime() - date.getTime();
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
      if (diffHours < 1) return '刚刚';
      if (diffHours < 24) return `${diffHours}小时前`;
      const diffDays = Math.floor(diffHours / 24);
      if (diffDays < 7) return `${diffDays}天前`;
      return isoTime.split('T')[0];
    } catch {
      return isoTime;
    }
  }
}
