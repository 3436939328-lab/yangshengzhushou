import {
  HealthProfile,
  MetricCode,
  AssessmentState,
  HealthMeasurement,
  BloodPressureMeasurement,
  BloodSugarMeasurement,
  HeartRateMeasurement,
  BloodOxygenMeasurement,
  TemperatureMeasurement,
  BodyMeasurement,
  StepsMeasurement,
  ExerciseMeasurement,
  WaterMeasurement,
  SleepMeasurement
} from '../../model/ProfileModels';
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
      // 异常指标提醒
      this.AbnormalAlertSection()

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

  // ==================== 异常指标提醒 ====================

  @Builder
  AbnormalAlertSection() {
    if (this.getAbnormalMetrics().length > 0) {
      Column({ space: 8 }) {
        ForEach(this.getAbnormalMetrics(), (item: SummaryMetricItem) => {
          Row() {
            Text('⚠️')
              .fontSize(20)
            Column({ space: 2 }) {
              Text(`${item.label}：${item.value}`)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(WARM_ACCENT)
              Text(`状态：${item.status}，建议关注或咨询医生`)
                .fontSize(12)
                .fontColor(MUTED_TEXT)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 8 })
          }
          .width('100%')
        }, (item: SummaryMetricItem) => item.label)
      }
      .width('100%')
      .padding(14)
      .backgroundColor('rgba(255, 152, 0, 0.08)')
      .borderRadius(CARD_RADIUS)
      .border({ width: 1, color: 'rgba(255, 152, 0, 0.3)' })
    }
  }

  private getAbnormalMetrics(): SummaryMetricItem[] {
    const result: SummaryMetricItem[] = [];
    const bp = this.findLatestMeasurement(MetricCode.BLOOD_PRESSURE) as BloodPressureMeasurement | null;
    if (bp && (bp.systolic >= 140 || bp.diastolic >= 90 || bp.systolic < 90 || bp.diastolic < 60)) {
      result.push({ label: '血压', value: `${bp.systolic}/${bp.diastolic} mmHg`, status: this.getStructuredMetricStatus('血压') } as SummaryMetricItem);
    }
    const bs = this.findLatestMeasurement(MetricCode.BLOOD_SUGAR) as BloodSugarMeasurement | null;
    if (bs && (bs.value > 7 || bs.value < 3.9)) {
      result.push({ label: '血糖', value: `${bs.value} mmol/L`, status: this.getStructuredMetricStatus('血糖') } as SummaryMetricItem);
    }
    const hr = this.findLatestMeasurement(MetricCode.HEART_RATE) as HeartRateMeasurement | null;
    if (hr && (hr.value > 100 || hr.value < 60)) {
      result.push({ label: '心率', value: `${hr.value} 次/分`, status: this.getStructuredMetricStatus('心率') } as SummaryMetricItem);
    }
    const bo = this.findLatestMeasurement(MetricCode.BLOOD_OXYGEN) as BloodOxygenMeasurement | null;
    if (bo && bo.value < 95) {
      result.push({ label: '血氧', value: `${bo.value}%`, status: this.getStructuredMetricStatus('血氧') } as SummaryMetricItem);
    }
    const temp = this.findLatestMeasurement(MetricCode.TEMPERATURE) as TemperatureMeasurement | null;
    if (temp && (temp.value >= 37.3 || temp.value < 36.0)) {
      result.push({ label: '体温', value: `${temp.value} ℃`, status: this.getStructuredMetricStatus('体温') } as SummaryMetricItem);
    }
    const body = this.findLatestMeasurement(MetricCode.BODY) as BodyMeasurement | null;
    if (body && body.bmi !== undefined && (body.bmi >= 24 || body.bmi < 18.5)) {
      result.push({ label: 'BMI', value: `${body.bmi}`, status: this.getStructuredMetricStatus('体重') } as SummaryMetricItem);
    }
    return result;
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
    // 从结构化测量记录中统计异常项
    const bp = this.findLatestMeasurement(MetricCode.BLOOD_PRESSURE) as BloodPressureMeasurement | null;
    if (bp && (bp.systolic >= 140 || bp.diastolic >= 90)) count++;
    const bs = this.findLatestMeasurement(MetricCode.BLOOD_SUGAR) as BloodSugarMeasurement | null;
    if (bs && bs.value > 7) count++;
    const hr = this.findLatestMeasurement(MetricCode.HEART_RATE) as HeartRateMeasurement | null;
    if (hr && (hr.value > 100 || hr.value < 60)) count++;
    // 回退到旧格式
    for (const metric of this.profile.healthIndicators) {
      if (metric.name.includes('血压') || metric.name.includes('血糖')) {
        count++;
      }
    }
    return Math.min(count, 3);
  }

  private getLastUpdateTime(): string {
    let latestTime = '';
    // 从结构化测量记录中找最新时间
    if (this.profile.measurements && this.profile.measurements.length > 0) {
      for (const m of this.profile.measurements) {
        if (m.measuredAt && m.measuredAt > latestTime) {
          latestTime = m.measuredAt;
        }
      }
    }
    // 回退到旧格式
    if (latestTime.length === 0 && this.profile.healthIndicators.length > 0) {
      const last = this.profile.healthIndicators[this.profile.healthIndicators.length - 1];
      latestTime = last.recordedAt || '';
    }
    if (latestTime.length === 0) return '暂无记录';
    if (latestTime.includes('T')) {
      return latestTime.split('T')[0];
    }
    return latestTime;
  }

  private getSummaryMetrics(): SummaryMetricItem[] {
    const result: SummaryMetricItem[] = [];

    // 血压 - 优先结构化数据
    const bpM = this.findLatestMeasurement(MetricCode.BLOOD_PRESSURE) as BloodPressureMeasurement | null;
    const bpIndicator = this.profile.healthIndicators.find(i => i.name.includes('血压'));
    const bpValue = bpM ? `${bpM.systolic}/${bpM.diastolic}` : (bpIndicator ? bpIndicator.value : '--');
    const bpStatus = bpM
      ? (bpM.systolic >= 140 || bpM.diastolic >= 90 ? 'attention' : 'normal')
      : (bpIndicator && (bpIndicator.value.includes('140') || bpIndicator.value.includes('90')) ? 'attention' : 'normal');
    result.push({ label: '血压', value: bpValue, status: bpStatus } as SummaryMetricItem);

    // 血糖
    const bsM = this.findLatestMeasurement(MetricCode.BLOOD_SUGAR) as BloodSugarMeasurement | null;
    const bsIndicator = this.profile.healthIndicators.find(i => i.name.includes('血糖'));
    const bsValue = bsM ? `${bsM.value}` : (bsIndicator ? bsIndicator.value : '--');
    result.push({ label: '血糖', value: bsValue, status: 'normal' } as SummaryMetricItem);

    // 心率
    const hrM = this.findLatestMeasurement(MetricCode.HEART_RATE) as HeartRateMeasurement | null;
    const hrIndicator = this.profile.healthIndicators.find(i => i.name.includes('心率'));
    const hrValue = hrM ? `${hrM.value}` : (hrIndicator ? hrIndicator.value : '--');
    result.push({ label: '心率', value: hrValue, status: 'normal' } as SummaryMetricItem);

    // 睡眠
    const sleepM = this.findLatestMeasurement(MetricCode.SLEEP) as SleepMeasurement | null;
    const sleepIndicator = this.profile.healthIndicators.find(i => i.name.includes('睡眠'));
    const sleepValue = sleepM ? `${sleepM.totalSleepMinutes}分钟` : (sleepIndicator ? sleepIndicator.value : '--');
    result.push({ label: '睡眠', value: sleepValue, status: 'normal' } as SummaryMetricItem);

    return result;
  }

  private getMissingCategories(): string[] {
    const existing = new Set<string>();
    for (const i of this.profile.healthIndicators) {
      existing.add(i.name);
    }
    if (this.profile.measurements) {
      for (const m of this.profile.measurements) {
        switch (m.metricCode) {
          case MetricCode.BLOOD_PRESSURE: existing.add('血压'); break;
          case MetricCode.BLOOD_SUGAR: existing.add('血糖'); break;
          case MetricCode.HEART_RATE: existing.add('心率'); break;
          case MetricCode.BLOOD_OXYGEN: existing.add('血氧'); break;
          case MetricCode.TEMPERATURE: existing.add('体温'); break;
          case MetricCode.BODY: existing.add('体重'); break;
          case MetricCode.SLEEP: existing.add('睡眠'); break;
          case MetricCode.STEPS: existing.add('步数'); break;
        }
      }
    }
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

  private findLatestMeasurement(metricCode: MetricCode): HealthMeasurement | null {
    if (!this.profile.measurements || this.profile.measurements.length === 0) {
      return null;
    }
    let latest: HealthMeasurement | null = null;
    for (let index = 0; index < this.profile.measurements.length; index++) {
      const m = this.profile.measurements[index];
      if (m.metricCode === metricCode) {
        if (latest === null || (m.measuredAt && m.measuredAt > (latest.measuredAt || ''))) {
          latest = m;
        }
      }
    }
    return latest;
  }

  private getMetricValue(nameKeyword: string): string {
    // 优先从结构化测量记录中读取
    const structured = this.getStructuredMetricValue(nameKeyword);
    if (structured.length > 0) {
      return structured;
    }
    // 回退到旧格式 healthIndicators
    const found = this.profile.healthIndicators.find(i => i.name.includes(nameKeyword));
    return found ? `${found.value}${found.unit}` : '未记录';
  }

  private getStructuredMetricValue(nameKeyword: string): string {
    if (nameKeyword.includes('血压')) {
      const m = this.findLatestMeasurement(MetricCode.BLOOD_PRESSURE) as BloodPressureMeasurement | null;
      if (m) return `${m.systolic}/${m.diastolic} mmHg`;
    } else if (nameKeyword.includes('血糖')) {
      const m = this.findLatestMeasurement(MetricCode.BLOOD_SUGAR) as BloodSugarMeasurement | null;
      if (m) return `${m.value} mmol/L`;
    } else if (nameKeyword.includes('心率')) {
      const m = this.findLatestMeasurement(MetricCode.HEART_RATE) as HeartRateMeasurement | null;
      if (m) return `${m.value} 次/分`;
    } else if (nameKeyword.includes('血氧')) {
      const m = this.findLatestMeasurement(MetricCode.BLOOD_OXYGEN) as BloodOxygenMeasurement | null;
      if (m) return `${m.value}%`;
    } else if (nameKeyword.includes('体温')) {
      const m = this.findLatestMeasurement(MetricCode.TEMPERATURE) as TemperatureMeasurement | null;
      if (m) return `${m.value} ℃`;
    } else if (nameKeyword.includes('体重')) {
      const m = this.findLatestMeasurement(MetricCode.BODY) as BodyMeasurement | null;
      if (m) {
        if (m.weightKg !== undefined) return `${m.weightKg} kg`;
        if (m.bmi !== undefined) return `BMI ${m.bmi}`;
      }
    } else if (nameKeyword.includes('步数')) {
      const m = this.findLatestMeasurement(MetricCode.STEPS) as StepsMeasurement | null;
      if (m) return `${m.steps} 步`;
    } else if (nameKeyword.includes('运动')) {
      const m = this.findLatestMeasurement(MetricCode.EXERCISE) as ExerciseMeasurement | null;
      if (m) return `${m.durationMinutes} 分钟`;
    } else if (nameKeyword.includes('饮水')) {
      const m = this.findLatestMeasurement(MetricCode.WATER) as WaterMeasurement | null;
      if (m) return `${m.amountMl} mL`;
    } else if (nameKeyword.includes('睡眠')) {
      const m = this.findLatestMeasurement(MetricCode.SLEEP) as SleepMeasurement | null;
      if (m) return `${m.totalSleepMinutes} 分钟`;
    }
    return '';
  }

  private getMetricStatus(nameKeyword: string): string {
    // 优先从结构化测量记录判断状态
    const structuredStatus = this.getStructuredMetricStatus(nameKeyword);
    if (structuredStatus.length > 0) {
      return structuredStatus;
    }
    // 回退到旧格式
    const found = this.profile.healthIndicators.find(i => i.name.includes(nameKeyword));
    if (!found) return '';
    if (found.name.includes('血压') && found.value.includes('140')) return '偏高';
    if (found.name.includes('血糖') && parseFloat(found.value) > 7) return '偏高';
    return '正常';
  }

  private getStructuredMetricStatus(nameKeyword: string): string {
    if (nameKeyword.includes('血压')) {
      const m = this.findLatestMeasurement(MetricCode.BLOOD_PRESSURE) as BloodPressureMeasurement | null;
      if (m) {
        if (m.systolic >= 180 || m.diastolic >= 110) return '高血压三级';
        if (m.systolic >= 160 || m.diastolic >= 100) return '高血压二级';
        if (m.systolic >= 140 || m.diastolic >= 90) return '偏高';
        if (m.systolic < 90 || m.diastolic < 60) return '偏低';
        return '正常';
      }
    } else if (nameKeyword.includes('血糖')) {
      const m = this.findLatestMeasurement(MetricCode.BLOOD_SUGAR) as BloodSugarMeasurement | null;
      if (m) {
        if (m.value >= 11.1) return '偏高（糖尿病范围）';
        if (m.value > 7) return '偏高';
        if (m.value < 3.9) return '偏低';
        return '正常';
      }
    } else if (nameKeyword.includes('心率')) {
      const m = this.findLatestMeasurement(MetricCode.HEART_RATE) as HeartRateMeasurement | null;
      if (m) {
        if (m.value > 120 || m.value < 50) return '异常';
        if (m.value > 100) return '偏快';
        if (m.value < 60) return '偏慢';
        return '正常';
      }
    } else if (nameKeyword.includes('血氧')) {
      const m = this.findLatestMeasurement(MetricCode.BLOOD_OXYGEN) as BloodOxygenMeasurement | null;
      if (m) {
        if (m.value < 90) return '严重偏低';
        if (m.value < 95) return '偏低';
        return '正常';
      }
    } else if (nameKeyword.includes('体温')) {
      const m = this.findLatestMeasurement(MetricCode.TEMPERATURE) as TemperatureMeasurement | null;
      if (m) {
        if (m.value >= 39.0) return '高热';
        if (m.value >= 37.3) return '偏高';
        if (m.value < 36.0) return '偏低';
        return '正常';
      }
    } else if (nameKeyword.includes('体重')) {
      const m = this.findLatestMeasurement(MetricCode.BODY) as BodyMeasurement | null;
      if (m && m.bmi !== undefined) {
        if (m.bmi >= 28) return '肥胖';
        if (m.bmi >= 24) return '超重';
        if (m.bmi < 18.5) return '偏瘦';
        return '正常';
      }
    }
    return '';
  }

  private getMetricStatusColor(nameKeyword: string): ResourceColor {
    const status = this.getMetricStatus(nameKeyword);
    if (status === '正常') return BRAND_GREEN;
    if (status.length === 0) return MUTED_TEXT;
    // 所有非正常状态都用警示色
    return WARM_ACCENT;
  }

  private getMetricTime(nameKeyword: string): string {
    // 优先从结构化测量记录读取时间
    const structuredTime = this.getStructuredMetricTime(nameKeyword);
    if (structuredTime.length > 0) {
      return structuredTime;
    }
    // 回退到旧格式
    const found = this.profile.healthIndicators.find(i => i.name.includes(nameKeyword));
    if (!found) return '';
    const time = found.recordedAt;
    if (time.includes('T')) {
      return time.split('T')[0];
    }
    return time;
  }

  private getStructuredMetricTime(nameKeyword: string): string {
    let metricCode: MetricCode | null = null;
    if (nameKeyword.includes('血压')) metricCode = MetricCode.BLOOD_PRESSURE;
    else if (nameKeyword.includes('血糖')) metricCode = MetricCode.BLOOD_SUGAR;
    else if (nameKeyword.includes('心率')) metricCode = MetricCode.HEART_RATE;
    else if (nameKeyword.includes('血氧')) metricCode = MetricCode.BLOOD_OXYGEN;
    else if (nameKeyword.includes('体温')) metricCode = MetricCode.TEMPERATURE;
    else if (nameKeyword.includes('体重')) metricCode = MetricCode.BODY;
    else if (nameKeyword.includes('步数')) metricCode = MetricCode.STEPS;
    else if (nameKeyword.includes('运动')) metricCode = MetricCode.EXERCISE;
    else if (nameKeyword.includes('饮水')) metricCode = MetricCode.WATER;
    else if (nameKeyword.includes('睡眠')) metricCode = MetricCode.SLEEP;

    if (metricCode === null) return '';
    const m = this.findLatestMeasurement(metricCode);
    if (!m) return '';
    const time = m.measuredAt;
    if (time && time.includes('T')) {
      return time.split('T')[0];
    }
    return time || '';
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
    const sleepM = this.findLatestMeasurement(MetricCode.SLEEP) as SleepMeasurement | null;
    if (sleepM) {
      const hours = sleepM.totalSleepMinutes / 60;
      return `${Math.round(hours * 10) / 10} 小时`;
    }
    const sleep = this.profile.healthIndicators.find(i => i.name.includes('睡眠'));
    if (sleep) {
      return sleep.value + sleep.unit;
    }
    return '-- 小时';
  }

  private getSleepQualityText(): string {
    const sleepM = this.findLatestMeasurement(MetricCode.SLEEP) as SleepMeasurement | null;
    if (sleepM) {
      const hours = sleepM.totalSleepMinutes / 60;
      if (hours >= 7) return '良好';
      if (hours >= 6) return '一般';
      return '偏少';
    }
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
    if (this.findLatestMeasurement(MetricCode.SLEEP) !== null) return true;
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
