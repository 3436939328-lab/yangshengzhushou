import { HealthProfile, MetricCode, AssessmentState } from '../../model/ProfileModels';
import {
  DeviceStatus,
  HealthMetric,
  WeatherWellness
} from '../../model/WellnessModels';
import { countPendingDeviceSyncs, getDeviceSyncSummary } from '../../services/DeviceService';
import { getEmptyStateInfo } from '../../services/EmptyStateService';
import {
  buildDisplayMetrics
} from '../../viewmodel/ProfileViewModel';
import { EmptyStateBlock } from '../cards/EmptyStateBlock';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import { SectionTitle } from '../cards/CommonCards';

/**
 * 健康指标分类项
 */
interface HealthCategoryItem {
  key: string;
  title: string;
  subtitle: string;
  icon: string;
  metricCode?: MetricCode;
  valueText?: string;
  status?: string;
  statusColor?: ResourceColor;
  lastTime?: string;
}

interface SummaryMetricItem {
  label: string;
  value: string;
  status: string;
}

interface CategoryGroup {
  title: string;
  items: HealthCategoryItem[];
}

@Component
export struct DataTab {
  @Prop metrics: HealthMetric[];
  @Prop devices: DeviceStatus[];
  @Prop weather: WeatherWellness;
  @Prop weatherSuggestionSummary: string;
  @Prop profile: HealthProfile;
  @Prop authUserId: string;

  @State selectedCategory: string = '';
  onAddRecord?: (metricCode: MetricCode) => void;
  onViewCategory?: (category: string) => void;
  onViewTongue?: () => void;
  onViewSleep?: () => void;

  build() {
    Column({ space: 14 }) {
      // 健康卡摘要
      this.HealthSummaryCard()

      // 快速录入入口
      this.QuickAddSection()

      // 指标分类
      SectionTitle('指标分类')
      this.CategoryGrid()

      // 舌象记录
      this.TongueSection()

      // 睡眠记录
      this.SleepSection()

      // 设备同步
      this.DeviceSyncCard()
    }
    .margin({ top: 14 })
  }

  // ==================== 健康卡摘要 ====================

  @Builder
  HealthSummaryCard() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('我的健康卡')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Text(`最近更新：${this.getLastUpdateTime()}`)
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.getAttentionCount() > 0) {
          Column({ space: 2 }) {
            Text(`${this.getAttentionCount()} 项`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(WARM_ACCENT)
            Text('需要关注')
              .fontSize(11)
              .fontColor(MUTED_TEXT)
          }
          .alignItems(HorizontalAlign.Center)
        }
      }

      // 简要指标
      Row({ space: 8 }) {
        ForEach(this.getSummaryMetrics(), (item: SummaryMetricItem) => {
          Column({ space: 4 }) {
            Text(item.value)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(item.status === 'attention' ? WARM_ACCENT : DEEP_TEXT)
            Text(item.label)
              .fontSize(11)
              .fontColor(MUTED_TEXT)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 10, bottom: 10 })
          .backgroundColor('rgba(76, 175, 80, 0.05)')
          .borderRadius(10)
        }, (item: SummaryMetricItem) => item.label)
      }

      if (this.getMissingCategories().length > 0) {
        Text(`还有 ${this.getMissingCategories().length} 项未记录，完善数据获得更准确建议`)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  private getAttentionCount(): number {
    let count = 0;
    // 从旧格式指标中统计
    for (const metric of this.profile.healthIndicators) {
      if (metric.name.includes('血压') || metric.name.includes('血糖')) {
        count++;
      }
    }
    return Math.min(count, 3); // 模拟数据
  }

  private getLastUpdateTime(): string {
    if (this.profile.healthIndicators.length > 0) {
      const last = this.profile.healthIndicators[this.profile.healthIndicators.length - 1];
      return last.recordedAt || '今天';
    }
    return '暂无记录';
  }

  private getSummaryMetrics(): SummaryMetricItem[] {
    const result: SummaryMetricItem[] = [];
    const indicators = this.profile.healthIndicators;

    // 血压
    const bp = indicators.find(i => i.name.includes('血压'));
    result.push({
      label: '血压',
      value: bp ? bp.value : '--',
      status: bp && (bp.value.includes('140') || bp.value.includes('90')) ? 'attention' : 'normal'
    } as SummaryMetricItem);

    // 血糖
    const bs = indicators.find(i => i.name.includes('血糖'));
    result.push({
      label: '血糖',
      value: bs ? bs.value : '--',
      status: 'normal'
    } as SummaryMetricItem);

    // 心率
    const hr = indicators.find(i => i.name.includes('心率'));
    result.push({
      label: '心率',
      value: hr ? hr.value : '--',
      status: 'normal'
    } as SummaryMetricItem);

    // 睡眠
    const sleep = indicators.find(i => i.name.includes('睡眠'));
    result.push({
      label: '睡眠',
      value: sleep ? sleep.value : '--',
      status: 'normal'
    } as SummaryMetricItem);

    return result;
  }

  private getMissingCategories(): string[] {
    const existing = new Set(this.profile.healthIndicators.map(i => i.name));
    const all = ['血压', '血糖', '心率', '血氧', '体温', '体重', '睡眠', '步数'];
    return all.filter(name => !Array.from(existing).some(e => e.includes(name)));
  }

  // ==================== 快速录入 ====================

  @Builder
  QuickAddSection() {
    Row({ space: 10 }) {
      ForEach(this.quickAddItems(), (item: HealthCategoryItem) => {
        Column({ space: 6 }) {
          Text(item.icon)
            .fontSize(24)
          Text(item.title)
            .fontSize(13)
            .fontColor(DEEP_TEXT)
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)
        .height(80)
        .backgroundColor(CARD_BG)
        .borderRadius(CARD_RADIUS)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.onAddRecord && item.metricCode) {
            this.onAddRecord(item.metricCode);
          }
        })
      }, (item: HealthCategoryItem) => item.key)
    }
    .width('100%')
  }

  private quickAddItems(): HealthCategoryItem[] {
    return [
      { key: 'bp', title: '血压', subtitle: '高低压', icon: '🩺', metricCode: MetricCode.BLOOD_PRESSURE },
      { key: 'bs', title: '血糖', subtitle: '空腹/餐后', icon: '🩸', metricCode: MetricCode.BLOOD_SUGAR },
      { key: 'hr', title: '心率', subtitle: '次/分', icon: '❤️', metricCode: MetricCode.HEART_RATE },
      { key: 'weight', title: '体重', subtitle: 'BMI', icon: '⚖️', metricCode: MetricCode.BODY },
    ];
  }

  // ==================== 指标分类网格 ====================

  @Builder
  CategoryGrid() {
    Column({ space: 10 }) {
      ForEach(this.getCategoryGroups(), (group: CategoryGroup) => {
        Column({ space: 8 }) {
          Text(group.title)
            .fontSize(13)
            .fontColor(MUTED_TEXT)
            .fontWeight(FontWeight.Medium)

          Grid() {
            ForEach(group.items, (item: HealthCategoryItem) => {
              GridItem() {
                this.CategoryItemCard(item)
              }
            }, (item: HealthCategoryItem) => item.key)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(10)
          .rowsGap(10)
        }
        .width('100%')
      }, (group: CategoryGroup) => group.title)
    }
    .width('100%')
  }

  @Builder
  CategoryItemCard(item: HealthCategoryItem) {
    Column({ space: 8 }) {
      Row() {
        Text(item.icon)
          .fontSize(20)
        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(DEEP_TEXT)
          .margin({ left: 8 })
      }
      .width('100%')

      if (item.valueText) {
        Column({ space: 2 }) {
          Text(item.valueText)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.statusColor || DEEP_TEXT)
          Text(item.lastTime || '')
            .fontSize(11)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      } else {
        Text(item.subtitle)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .width('100%')
      }

      if (item.status) {
        Text(item.status)
          .fontSize(11)
          .fontColor(item.statusColor || MUTED_TEXT)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor('rgba(76, 175, 80, 0.1)')
          .borderRadius(8)
      }
    }
    .width('100%')
    .height(110)
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      if (this.onViewCategory) {
        this.onViewCategory(item.key);
      }
    })
  }

  private getCategoryGroups(): CategoryGroup[] {
    return [
      {
        title: '身体指标',
        items: [
          { key: 'bloodPressure', title: '血压', subtitle: '收缩压/舒张压', icon: '🩺', metricCode: MetricCode.BLOOD_PRESSURE,
            valueText: this.getMetricValue('血压'), status: this.getMetricStatus('血压'),
            statusColor: this.getMetricStatusColor('血压'), lastTime: this.getMetricTime('血压') } as HealthCategoryItem,
          { key: 'bloodSugar', title: '血糖', subtitle: '空腹/餐后/随机', icon: '🩸', metricCode: MetricCode.BLOOD_SUGAR,
            valueText: this.getMetricValue('血糖'), status: this.getMetricStatus('血糖'),
            statusColor: this.getMetricStatusColor('血糖'), lastTime: this.getMetricTime('血糖') } as HealthCategoryItem,
          { key: 'heartRate', title: '心率', subtitle: '静息/运动后', icon: '❤️', metricCode: MetricCode.HEART_RATE,
            valueText: this.getMetricValue('心率'), status: this.getMetricStatus('心率'),
            statusColor: this.getMetricStatusColor('心率'), lastTime: this.getMetricTime('心率') } as HealthCategoryItem,
          { key: 'bloodOxygen', title: '血氧', subtitle: '血氧饱和度', icon: '💧', metricCode: MetricCode.BLOOD_OXYGEN,
            valueText: this.getMetricValue('血氧'), status: this.getMetricStatus('血氧'),
            statusColor: this.getMetricStatusColor('血氧'), lastTime: this.getMetricTime('血氧') } as HealthCategoryItem,
          { key: 'temperature', title: '体温', subtitle: '多部位测量', icon: '🌡️', metricCode: MetricCode.TEMPERATURE,
            valueText: this.getMetricValue('体温'), status: this.getMetricStatus('体温'),
            statusColor: this.getMetricStatusColor('体温'), lastTime: this.getMetricTime('体温') } as HealthCategoryItem,
          { key: 'body', title: '体格', subtitle: '身高/体重/BMI', icon: '📏', metricCode: MetricCode.BODY,
            valueText: this.getMetricValue('体重'), status: this.getMetricStatus('体重'),
            statusColor: this.getMetricStatusColor('体重'), lastTime: this.getMetricTime('体重') } as HealthCategoryItem,
        ]
      } as CategoryGroup,
      {
        title: '生活方式',
        items: [
          { key: 'steps', title: '步数', subtitle: '每日运动', icon: '🚶', metricCode: MetricCode.STEPS,
            valueText: this.getMetricValue('步数'), status: '', lastTime: this.getMetricTime('步数') } as HealthCategoryItem,
          { key: 'exercise', title: '运动', subtitle: '运动时长', icon: '🏃', metricCode: MetricCode.EXERCISE,
            valueText: this.getMetricValue('运动'), status: '', lastTime: this.getMetricTime('运动') } as HealthCategoryItem,
          { key: 'water', title: '饮水', subtitle: '每日饮水量', icon: '💦', metricCode: MetricCode.WATER,
            valueText: this.getMetricValue('饮水'), status: '', lastTime: this.getMetricTime('饮水') } as HealthCategoryItem,
        ]
      } as CategoryGroup
    ];
  }

  private getMetricValue(nameKeyword: string): string {
    const found = this.profile.healthIndicators.find(i => i.name.includes(nameKeyword));
    return found ? `${found.value}${found.unit}` : '未记录';
  }

  private getMetricStatus(nameKeyword: string): string {
    const found = this.profile.healthIndicators.find(i => i.name.includes(nameKeyword));
    if (!found) return '';
    // 简单模拟状态判断
    if (found.name.includes('血压') && found.value.includes('140')) return '偏高';
    if (found.name.includes('血糖') && parseFloat(found.value) > 7) return '偏高';
    return '正常';
  }

  private getMetricStatusColor(nameKeyword: string): ResourceColor {
    const status = this.getMetricStatus(nameKeyword);
    if (status === '偏高') return WARM_ACCENT;
    if (status === '正常') return BRAND_GREEN;
    return MUTED_TEXT;
  }

  private getMetricTime(nameKeyword: string): string {
    const found = this.profile.healthIndicators.find(i => i.name.includes(nameKeyword));
    if (!found) return '';
    // 简化时间显示
    const time = found.recordedAt;
    if (time.includes('T')) {
      return time.split('T')[0];
    }
    return time;
  }

  // ==================== 舌象记录 ====================

  @Builder
  TongueSection() {
    Column({ space: 10 }) {
      Row() {
        Text('舌象记录')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Text('查看全部')
          .fontSize(13)
          .fontColor(BRAND_GREEN)
          .onClick(() => {
            if (this.onViewTongue) {
              this.onViewTongue();
            }
          })
      }
      .width('100%')

      Row({ space: 10 }) {
        // 舌象照片入口
        Column({ space: 8 }) {
          Text('👅')
            .fontSize(28)
          Text('拍舌象')
            .fontSize(13)
            .fontColor(DEEP_TEXT)
            .fontWeight(FontWeight.Medium)
          Text('辅助观察舌色舌苔')
            .fontSize(11)
            .fontColor(MUTED_TEXT)
        }
        .layoutWeight(1)
        .height(100)
        .backgroundColor(CARD_BG)
        .borderRadius(CARD_RADIUS)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          if (this.onViewTongue) {
            this.onViewTongue();
          }
        })

        // 文字记录入口
        Column({ space: 8 }) {
          Text('📝')
            .fontSize(28)
          Text('文字记录')
            .fontSize(13)
            .fontColor(DEEP_TEXT)
            .fontWeight(FontWeight.Medium)
          Text(`${this.profile.tongueNotes.length} 条记录`)
            .fontSize(11)
            .fontColor(MUTED_TEXT)
        }
        .layoutWeight(1)
        .height(100)
        .backgroundColor(CARD_BG)
        .borderRadius(CARD_RADIUS)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          if (this.onViewTongue) {
            this.onViewTongue();
          }
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  // ==================== 睡眠记录 ====================

  @Builder
  SleepSection() {
    Column({ space: 10 }) {
      Row() {
        Text('睡眠记录')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Text('查看详情')
          .fontSize(13)
          .fontColor(BRAND_GREEN)
          .onClick(() => {
            if (this.onViewSleep) {
              this.onViewSleep();
            }
          })
      }
      .width('100%')

      Column({ space: 12 }) {
        Row() {
          Column({ space: 4 }) {
            Text('昨晚睡眠')
              .fontSize(13)
              .fontColor(MUTED_TEXT)
            Text(this.getSleepDurationText())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(DEEP_TEXT)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Column({ space: 2 }) {
            Text('睡眠质量')
              .fontSize(12)
              .fontColor(MUTED_TEXT)
            Text(this.getSleepQualityText())
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(BRAND_GREEN)
          }
          .alignItems(HorizontalAlign.End)
        }

        // 睡眠分期条形图（简化版）
        if (this.hasSleepData()) {
          Row() {
            Column()
              .layoutWeight(25)
              .height(12)
              .backgroundColor('#64B5F6')
              .borderRadius({ topLeft: 6, bottomLeft: 6 })
            Column()
              .layoutWeight(50)
              .height(12)
              .backgroundColor('#81C784')
            Column()
              .layoutWeight(15)
              .height(12)
              .backgroundColor('#BA68C8')
            Column()
              .layoutWeight(10)
              .height(12)
              .backgroundColor('#FFB74D')
              .borderRadius({ topRight: 6, bottomRight: 6 })
          }
          .width('100%')

          Row({ space: 8 }) {
            this.SleepLegendItem('浅睡', '#64B5F6')
            this.SleepLegendItem('深睡', '#81C784')
            this.SleepLegendItem('REM', '#BA68C8')
            this.SleepLegendItem('清醒', '#FFB74D')
          }
        } else {
          Text('暂无睡眠记录，点击记录昨晚睡眠')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
      .onClick(() => {
        if (this.onViewSleep) {
          this.onViewSleep();
        }
      })
    }
    .width('100%')
  }

  @Builder
  SleepLegendItem(label: string, color: string) {
    Row({ space: 4 }) {
      Circle({ width: 8, height: 8 })
        .fill(color)
      Text(label)
        .fontSize(11)
        .fontColor(MUTED_TEXT)
    }
  }

  private getSleepDurationText(): string {
    const sleep = this.profile.healthIndicators.find(i => i.name.includes('睡眠'));
    if (sleep) {
      return sleep.value + sleep.unit;
    }
    return '-- 小时';
  }

  private getSleepQualityText(): string {
    const sleep = this.profile.healthIndicators.find(i => i.name.includes('睡眠'));
    if (sleep) {
      const hours = parseFloat(sleep.value);
      if (hours >= 7) return '良好';
      if (hours >= 6) return '一般';
      return '偏少';
    }
    return '未记录';
  }

  private hasSleepData(): boolean {
    return this.profile.healthIndicators.some(i => i.name.includes('睡眠'));
  }

  // ==================== 设备同步 ====================

  @Builder
  DeviceSyncCard() {
    Column({ space: 12 }) {
      Text(getDeviceSyncSummary(this.devices.length, countPendingDeviceSyncs(this.devices)))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      if (this.devices.length === 0) {
        Text('当前仅支持手动记录健康指标，暂未请求蓝牙、设备连接或后台同步权限。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .lineHeight(20)
      } else {
        ForEach(this.devices, (device: DeviceStatus) => {
          Row() {
            Column() {
              Text(device.name)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(DEEP_TEXT)
              Text(`${device.type} · ${device.lastSync}`)
                .fontSize(12)
                .fontColor(MUTED_TEXT)
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text(device.status)
              .fontSize(12)
              .fontColor(device.status === '已同步' ? BRAND_GREEN : WARM_ACCENT)
          }
          .width('100%')
        }, (device: DeviceStatus) => device.name)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }
}
