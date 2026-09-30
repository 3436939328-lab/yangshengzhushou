import {
  MetricCode,
  AssessmentState,
  ReferenceRule,
  HealthMeasurement,
  BloodPressureMeasurement,
  BloodSugarMeasurement,
  HeartRateMeasurement,
  BloodOxygenMeasurement,
  TemperatureMeasurement,
  BodyMeasurement,
  SleepMeasurement,
  BloodSugarType,
  TemperatureSite,
  HeartRateContext,
  HealthCardSummary,
  SleepType
} from '../model/ProfileModels';

/**
 * 内置参考范围规则（中国成年人标准）
 * 版本: v1.0.0-cn-adult
 * 生效日期: 2025-01-01
 */
const BUILTIN_REFERENCE_RULES: ReferenceRule[] = [
  // ==================== 血压 ====================
  {
    id: 'ref_bp_adult_sitting',
    metricCode: MetricCode.BLOOD_PRESSURE,
    unit: 'mmHg',
    context: 'SITTING',
    attentionMin: 90,
    attentionMax: 140,
    urgentMin: 80,
    urgentMax: 160,
    applicableGroup: 'adult_general',
    sourceName: '中国高血压防治指南2023',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  },
  // 血压-舒张压参考
  {
    id: 'ref_bp_diastolic_adult',
    metricCode: MetricCode.BLOOD_PRESSURE,
    unit: 'mmHg',
    context: 'DIASTOLIC',
    attentionMin: 60,
    attentionMax: 90,
    urgentMin: 50,
    urgentMax: 100,
    applicableGroup: 'adult_general',
    sourceName: '中国高血压防治指南2023',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  },

  // ==================== 血糖 ====================
  {
    id: 'ref_bs_fasting_adult',
    metricCode: MetricCode.BLOOD_SUGAR,
    unit: 'mmol/L',
    context: 'FASTING',
    attentionMin: 3.9,
    attentionMax: 6.1,
    urgentMin: 3.0,
    urgentMax: 7.0,
    applicableGroup: 'adult_general',
    sourceName: '中国2型糖尿病防治指南2024',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  },
  {
    id: 'ref_bs_postmeal_adult',
    metricCode: MetricCode.BLOOD_SUGAR,
    unit: 'mmol/L',
    context: 'POST_MEAL_2H',
    attentionMin: 3.9,
    attentionMax: 7.8,
    urgentMin: 3.0,
    urgentMax: 11.1,
    applicableGroup: 'adult_general',
    sourceName: '中国2型糖尿病防治指南2024',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  },
  {
    id: 'ref_bs_random_adult',
    metricCode: MetricCode.BLOOD_SUGAR,
    unit: 'mmol/L',
    context: 'RANDOM',
    attentionMin: 3.9,
    attentionMax: 11.1,
    urgentMin: 3.0,
    urgentMax: 13.9,
    applicableGroup: 'adult_general',
    sourceName: '中国2型糖尿病防治指南2024',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  },

  // ==================== 心率 ====================
  {
    id: 'ref_hr_resting_adult',
    metricCode: MetricCode.HEART_RATE,
    unit: '次/分',
    context: 'RESTING',
    attentionMin: 60,
    attentionMax: 100,
    urgentMin: 50,
    urgentMax: 120,
    applicableGroup: 'adult_general',
    sourceName: '内科学第9版',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  },
  {
    id: 'ref_hr_general_adult',
    metricCode: MetricCode.HEART_RATE,
    unit: '次/分',
    context: 'GENERAL',
    attentionMin: 50,
    attentionMax: 120,
    urgentMin: 40,
    urgentMax: 150,
    applicableGroup: 'adult_general',
    sourceName: '内科学第9版',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  },

  // ==================== 血氧 ====================
  {
    id: 'ref_bo_adult',
    metricCode: MetricCode.BLOOD_OXYGEN,
    unit: '%',
    attentionMin: 95,
    attentionMax: 100,
    urgentMin: 90,
    urgentMax: 100,
    applicableGroup: 'adult_general',
    sourceName: '内科学第9版',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  },

  // ==================== 体温 ====================
  {
    id: 'ref_temp_axillary_adult',
    metricCode: MetricCode.TEMPERATURE,
    unit: '℃',
    context: 'AXILLARY',
    attentionMin: 36.0,
    attentionMax: 37.3,
    urgentMin: 35.5,
    urgentMax: 38.5,
    applicableGroup: 'adult_general',
    sourceName: '诊断学第9版',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  },
  {
    id: 'ref_temp_oral_adult',
    metricCode: MetricCode.TEMPERATURE,
    unit: '℃',
    context: 'ORAL',
    attentionMin: 36.3,
    attentionMax: 37.2,
    urgentMin: 35.8,
    urgentMax: 38.5,
    applicableGroup: 'adult_general',
    sourceName: '诊断学第9版',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  },

  // ==================== BMI ====================
  {
    id: 'ref_bmi_adult',
    metricCode: MetricCode.BODY,
    unit: 'kg/m²',
    context: 'BMI',
    attentionMin: 18.5,
    attentionMax: 24.0,
    urgentMin: 16.0,
    urgentMax: 28.0,
    applicableGroup: 'adult_general',
    sourceName: '中国成人超重和肥胖症预防控制指南',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  },

  // ==================== 睡眠 ====================
  {
    id: 'ref_sleep_adult_main',
    metricCode: MetricCode.SLEEP,
    unit: '分钟',
    context: 'MAIN',
    attentionMin: 420, // 7小时
    attentionMax: 540, // 9小时
    urgentMin: 300,    // 5小时
    urgentMax: 600,    // 10小时
    applicableGroup: 'adult_general',
    sourceName: '中国睡眠研究会2023',
    version: 'v1.0.0-cn-adult',
    effectiveDate: '2025-01-01'
  }
];

/**
 * 健康参考范围服务
 */
export class ReferenceRangeService {
  private rules: ReferenceRule[] = BUILTIN_REFERENCE_RULES;

  /**
   * 获取所有参考范围规则
   */
  getAllRules(): ReferenceRule[] {
    return [...this.rules];
  }

  /**
   * 根据指标代码获取参考范围规则
   */
  getRulesByMetric(metricCode: MetricCode): ReferenceRule[] {
    return this.rules.filter(r => r.metricCode === metricCode);
  }

  /**
   * 获取最匹配的参考范围规则
   * @param metricCode 指标代码
   * @param context 测量情境（如测量类型、部位等）
   */
  getBestMatchingRule(metricCode: MetricCode, context?: string): ReferenceRule | null {
    const metricRules = this.getRulesByMetric(metricCode);
    if (metricRules.length === 0) return null;

    // 优先匹配指定情境
    if (context) {
      const matched = metricRules.find(r => r.context === context);
      if (matched) return matched;
    }

    // 返回第一个（默认）
    return metricRules[0];
  }

  /**
   * 评估单个数值的状态
   */
  assessValue(value: number, rule: ReferenceRule | null): AssessmentState {
    if (!rule) return AssessmentState.UNKNOWN;

    // 紧急范围
    if (rule.urgentMin !== undefined && value < rule.urgentMin) {
      return AssessmentState.URGENT;
    }
    if (rule.urgentMax !== undefined && value > rule.urgentMax) {
      return AssessmentState.URGENT;
    }

    // 关注范围
    if (rule.attentionMin !== undefined && value < rule.attentionMin) {
      return AssessmentState.ATTENTION;
    }
    if (rule.attentionMax !== undefined && value > rule.attentionMax) {
      return AssessmentState.ATTENTION;
    }

    // 正常范围
    return AssessmentState.IN_RANGE;
  }

  /**
   * 生成评估原因文本
   */
  getAssessmentReason(value: number, rule: ReferenceRule | null): string {
    if (!rule) return '暂无参考范围';

    const state = this.assessValue(value, rule);
    const rangeText = this.formatRange(rule);

    switch (state) {
      case AssessmentState.IN_RANGE:
        return `在正常范围内（参考：${rangeText}）`;
      case AssessmentState.ATTENTION:
        return `超出正常范围，建议关注（参考：${rangeText}）`;
      case AssessmentState.URGENT:
        return `明显异常，建议及时就医（参考：${rangeText}）`;
      default:
        return '无法判定';
    }
  }

  private formatRange(rule: ReferenceRule): string {
    if (rule.attentionMin !== undefined && rule.attentionMax !== undefined) {
      return `${rule.attentionMin}-${rule.attentionMax} ${rule.unit}`;
    }
    if (rule.attentionMax !== undefined) {
      return `≤${rule.attentionMax} ${rule.unit}`;
    }
    if (rule.attentionMin !== undefined) {
      return `≥${rule.attentionMin} ${rule.unit}`;
    }
    return rule.unit;
  }
}

// 单例
const referenceRangeService = new ReferenceRangeService();
export function getReferenceRangeService(): ReferenceRangeService {
  return referenceRangeService;
}

/**
 * 健康卡摘要构建服务
 */
export class HealthCardBuilder {
  private refService: ReferenceRangeService;

  constructor() {
    this.refService = getReferenceRangeService();
  }

  /**
   * 从测量记录列表构建健康卡摘要
   */
  buildCard(
    subjectId: string,
    subjectName: string,
    measurements: HealthMeasurement[]
  ): HealthCardSummary {
    const card: HealthCardSummary = {
      subjectId,
      subjectName,
      generatedAt: new Date().toISOString(),
      attentionCount: 0,
      urgentCount: 0,
      missingCategories: []
    };

    const latestByMetric = this.getLatestByMetric(measurements);

    // 血压
    const bp = latestByMetric[MetricCode.BLOOD_PRESSURE] as BloodPressureMeasurement;
    if (bp) {
      const systolicRule = this.refService.getBestMatchingRule(MetricCode.BLOOD_PRESSURE, bp.position);
      const state = this.assessBloodPressure(bp, systolicRule);
      card.bloodPressure = {
        systolic: bp.systolic,
        diastolic: bp.diastolic,
        pulse: bp.pulse,
        measuredAt: bp.measuredAt,
        state,
        stateText: this.stateText(state)
      };
      if (state === AssessmentState.ATTENTION) card.attentionCount++;
      if (state === AssessmentState.URGENT) card.urgentCount++;
    } else {
      card.missingCategories.push('BLOOD_PRESSURE');
    }

    // 血糖
    const bs = latestByMetric[MetricCode.BLOOD_SUGAR] as BloodSugarMeasurement;
    if (bs) {
      const rule = this.refService.getBestMatchingRule(MetricCode.BLOOD_SUGAR, bs.sugarType);
      const state = this.refService.assessValue(bs.value, rule);
      card.bloodSugar = {
        value: bs.value,
        unit: 'mmol/L',
        type: bs.sugarType,
        typeText: this.bloodSugarTypeText(bs.sugarType),
        measuredAt: bs.measuredAt,
        state,
        stateText: this.stateText(state)
      };
      if (state === AssessmentState.ATTENTION) card.attentionCount++;
      if (state === AssessmentState.URGENT) card.urgentCount++;
    } else {
      card.missingCategories.push('BLOOD_SUGAR');
    }

    // 心率
    const hr = latestByMetric[MetricCode.HEART_RATE] as HeartRateMeasurement;
    if (hr) {
      const rule = this.refService.getBestMatchingRule(
        MetricCode.HEART_RATE,
        hr.context === HeartRateContext.RESTING ? 'RESTING' : 'GENERAL'
      );
      const state = this.refService.assessValue(hr.value, rule);
      card.heartRate = {
        value: hr.value,
        unit: '次/分',
        context: hr.context,
        measuredAt: hr.measuredAt,
        state,
        stateText: this.stateText(state)
      };
      if (state === AssessmentState.ATTENTION) card.attentionCount++;
      if (state === AssessmentState.URGENT) card.urgentCount++;
    } else {
      card.missingCategories.push('HEART_RATE');
    }

    // 血氧
    const bo = latestByMetric[MetricCode.BLOOD_OXYGEN] as BloodOxygenMeasurement;
    if (bo) {
      const rule = this.refService.getBestMatchingRule(MetricCode.BLOOD_OXYGEN);
      const state = this.refService.assessValue(bo.value, rule);
      card.bloodOxygen = {
        value: bo.value,
        unit: '%',
        measuredAt: bo.measuredAt,
        state,
        stateText: this.stateText(state)
      };
      if (state === AssessmentState.ATTENTION) card.attentionCount++;
      if (state === AssessmentState.URGENT) card.urgentCount++;
    } else {
      card.missingCategories.push('BLOOD_OXYGEN');
    }

    // 体温
    const temp = latestByMetric[MetricCode.TEMPERATURE] as TemperatureMeasurement;
    if (temp) {
      const rule = this.refService.getBestMatchingRule(MetricCode.TEMPERATURE, temp.site);
      const state = this.refService.assessValue(temp.value, rule);
      card.temperature = {
        value: temp.value,
        unit: '℃',
        site: temp.site,
        measuredAt: temp.measuredAt,
        state,
        stateText: this.stateText(state)
      };
      if (state === AssessmentState.ATTENTION) card.attentionCount++;
      if (state === AssessmentState.URGENT) card.urgentCount++;
    } else {
      card.missingCategories.push('TEMPERATURE');
    }

    // 体格
    const body = latestByMetric[MetricCode.BODY] as BodyMeasurement;
    if (body && body.bmi !== undefined) {
      const rule = this.refService.getBestMatchingRule(MetricCode.BODY, 'BMI');
      const state = this.refService.assessValue(body.bmi, rule);
      card.body = {
        heightCm: body.heightCm,
        weightKg: body.weightKg,
        bmi: body.bmi,
        measuredAt: body.measuredAt,
        state,
        stateText: this.stateText(state)
      };
      if (state === AssessmentState.ATTENTION) card.attentionCount++;
      if (state === AssessmentState.URGENT) card.urgentCount++;
    }

    // 睡眠
    const sleep = latestByMetric[MetricCode.SLEEP] as SleepMeasurement;
    if (sleep) {
      const rule = this.refService.getBestMatchingRule(
        MetricCode.SLEEP,
        sleep.sleepType === SleepType.MAIN ? 'MAIN' : undefined
      );
      const state = this.refService.assessValue(sleep.totalSleepMinutes, rule);
      card.sleep = {
        totalMinutes: sleep.totalSleepMinutes,
        totalText: this.formatSleepDuration(sleep.totalSleepMinutes),
        sleepType: sleep.sleepType,
        measuredAt: sleep.measuredAt,
        source: sleep.sourceName || '手动记录',
        state,
        stateText: this.stateText(state),
        lightMinutes: sleep.lightMinutes,
        deepMinutes: sleep.deepMinutes,
        remMinutes: sleep.remMinutes
      };
    } else {
      card.missingCategories.push('SLEEP');
    }

    return card;
  }

  /**
   * 获取各指标最新记录
   */
  private getLatestByMetric(measurements: HealthMeasurement[]): Record<string, HealthMeasurement> {
    const result: Record<string, HealthMeasurement> = {};
    for (const m of measurements) {
      const code = m.metricCode;
      if (!result[code] || new Date(m.measuredAt) > new Date(result[code].measuredAt)) {
        result[code] = m;
      }
    }
    return result;
  }

  /**
   * 评估血压（综合收缩压和舒张压）
   */
  private assessBloodPressure(bp: BloodPressureMeasurement, rule: ReferenceRule | null): AssessmentState {
    if (!rule) return AssessmentState.UNKNOWN;

    const systolicState = this.refService.assessValue(bp.systolic, rule);
    const diastolicRule = this.refService.getBestMatchingRule(MetricCode.BLOOD_PRESSURE, 'DIASTOLIC');
    const diastolicState = this.refService.assessValue(bp.diastolic, diastolicRule);

    // 取更严重的状态
    const stateOrder = {
      [AssessmentState.IN_RANGE]: 0,
      [AssessmentState.UNKNOWN]: 1,
      [AssessmentState.ATTENTION]: 2,
      [AssessmentState.URGENT]: 3
    };

    return stateOrder[systolicState] >= stateOrder[diastolicState]
      ? systolicState
      : diastolicState;
  }

  private stateText(state: AssessmentState): string {
    switch (state) {
      case AssessmentState.IN_RANGE: return '正常';
      case AssessmentState.ATTENTION: return '需要关注';
      case AssessmentState.URGENT: return '需及时处理';
      default: return '未知';
    }
  }

  private bloodSugarTypeText(type: BloodSugarType): string {
    switch (type) {
      case BloodSugarType.FASTING: return '空腹';
      case BloodSugarType.POST_MEAL_2H: return '餐后2小时';
      case BloodSugarType.RANDOM: return '随机';
      default: return '';
    }
  }

  private formatSleepDuration(minutes: number): string {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    if (mins === 0) return `${hours}小时`;
    return `${hours}小时${mins}分`;
  }
}

// 单例
const healthCardBuilder = new HealthCardBuilder();
export function getHealthCardBuilder(): HealthCardBuilder {
  return healthCardBuilder;
}

/**
 * 异常提醒项
 */
export interface AbnormalAlertItem {
  id: string;
  metricCode: MetricCode;
  metricName: string;
  state: AssessmentState;
  valueText: string;
  measuredAt: string;
  reason: string;
  suggestion?: string;
  isRead: boolean;
}

/**
 * 异常提醒服务
 */
export class AbnormalAlertService {
  private alerts: AbnormalAlertItem[] = [];

  /**
   * 从健康卡生成提醒
   */
  generateAlerts(card: HealthCardSummary): AbnormalAlertItem[] {
    const newAlerts: AbnormalAlertItem[] = [];

    if (card.bloodPressure &&
        (card.bloodPressure.state === AssessmentState.ATTENTION ||
         card.bloodPressure.state === AssessmentState.URGENT)) {
      newAlerts.push({
        id: `alert_bp_${card.bloodPressure.measuredAt}`,
        metricCode: MetricCode.BLOOD_PRESSURE,
        metricName: '血压',
        state: card.bloodPressure.state,
        valueText: `${card.bloodPressure.systolic}/${card.bloodPressure.diastolic} mmHg`,
        measuredAt: card.bloodPressure.measuredAt,
        reason: card.bloodPressure.stateText,
        suggestion: card.bloodPressure.state === AssessmentState.URGENT
          ? '血压明显异常，建议尽快就医检查'
          : '血压偏高，建议规律监测，保持低盐饮食、适量运动',
        isRead: false
      });
    }

    if (card.bloodSugar &&
        (card.bloodSugar.state === AssessmentState.ATTENTION ||
         card.bloodSugar.state === AssessmentState.URGENT)) {
      newAlerts.push({
        id: `alert_bs_${card.bloodSugar.measuredAt}`,
        metricCode: MetricCode.BLOOD_SUGAR,
        metricName: '血糖',
        state: card.bloodSugar.state,
        valueText: `${card.bloodSugar.value} mmol/L (${card.bloodSugar.typeText})`,
        measuredAt: card.bloodSugar.measuredAt,
        reason: card.bloodSugar.stateText,
        suggestion: card.bloodSugar.state === AssessmentState.URGENT
          ? '血糖明显异常，建议尽快就医检查'
          : '血糖偏高，建议控制饮食、规律运动，定期监测',
        isRead: false
      });
    }

    if (card.heartRate &&
        (card.heartRate.state === AssessmentState.ATTENTION ||
         card.heartRate.state === AssessmentState.URGENT)) {
      newAlerts.push({
        id: `alert_hr_${card.heartRate.measuredAt}`,
        metricCode: MetricCode.HEART_RATE,
        metricName: '心率',
        state: card.heartRate.state,
        valueText: `${card.heartRate.value} 次/分`,
        measuredAt: card.heartRate.measuredAt,
        reason: card.heartRate.stateText,
        suggestion: card.heartRate.state === AssessmentState.URGENT
          ? '心率明显异常，建议尽快就医检查'
          : '心率异常，建议保持平静，避免剧烈运动，持续观察',
        isRead: false
      });
    }

    if (card.bloodOxygen &&
        (card.bloodOxygen.state === AssessmentState.ATTENTION ||
         card.bloodOxygen.state === AssessmentState.URGENT)) {
      newAlerts.push({
        id: `alert_bo_${card.bloodOxygen.measuredAt}`,
        metricCode: MetricCode.BLOOD_OXYGEN,
        metricName: '血氧饱和度',
        state: card.bloodOxygen.state,
        valueText: `${card.bloodOxygen.value}%`,
        measuredAt: card.bloodOxygen.measuredAt,
        reason: card.bloodOxygen.stateText,
        suggestion: card.bloodOxygen.state === AssessmentState.URGENT
          ? '血氧偏低，建议立即就医'
          : '血氧偏低，建议保持通风，如有不适及时就医',
        isRead: false
      });
    }

    if (card.temperature &&
        (card.temperature.state === AssessmentState.ATTENTION ||
         card.temperature.state === AssessmentState.URGENT)) {
      newAlerts.push({
        id: `alert_temp_${card.temperature.measuredAt}`,
        metricCode: MetricCode.TEMPERATURE,
        metricName: '体温',
        state: card.temperature.state,
        valueText: `${card.temperature.value}℃`,
        measuredAt: card.temperature.measuredAt,
        reason: card.temperature.stateText,
        suggestion: card.temperature.state === AssessmentState.URGENT
          ? '体温明显异常，建议及时就医'
          : '体温偏高，建议多饮水，注意休息，持续监测',
        isRead: false
      });
    }

    // 合并到现有提醒列表（去重）
    const existingIds = new Set(this.alerts.map(a => a.id));
    for (const alert of newAlerts) {
      if (!existingIds.has(alert.id)) {
        this.alerts.unshift(alert);
      }
    }

    return newAlerts;
  }

  /**
   * 获取所有未读提醒
   */
  getUnreadAlerts(): AbnormalAlertItem[] {
    return this.alerts.filter(a => !a.isRead);
  }

  /**
   * 获取所有提醒
   */
  getAllAlerts(): AbnormalAlertItem[] {
    return [...this.alerts];
  }

  /**
   * 标记为已读
   */
  markAsRead(alertId: string): void {
    const alert = this.alerts.find(a => a.id === alertId);
    if (alert) {
      alert.isRead = true;
    }
  }

  /**
   * 全部标记为已读
   */
  markAllAsRead(): void {
    this.alerts.forEach(a => { a.isRead = true; });
  }

  /**
   * 清空提醒
   */
  clearAll(): void {
    this.alerts = [];
  }
}

// 单例
const abnormalAlertService = new AbnormalAlertService();
export function getAbnormalAlertService(): AbnormalAlertService {
  return abnormalAlertService;
}
