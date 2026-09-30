import { HealthIndicatorEntry, HealthProfile, TongueObservationNote } from '../model/ProfileModels';
import { IndicatorItem, MedicalReportInterpretation, MonthlyReport } from '../model/WellnessModels';

function buildIndicator(name: string, value: string, reference: string, status: string, advice: string): IndicatorItem {
  return {
    name,
    value,
    reference,
    status,
    advice
  };
}

export function interpretMedicalIndicators(
  systolic: number,
  diastolic: number,
  glucose: number,
  sleepHours: number
): MedicalReportInterpretation {
  const abnormalItems: IndicatorItem[] = [];
  const normalItems: IndicatorItem[] = [];

  const systolicItem = buildIndicator(
    '收缩压',
    `${systolic}mmHg`,
    '< 140mmHg',
    systolic >= 140 ? '偏高' : '正常',
    systolic >= 140 ? '减少高盐饮食，连续记录早晚血压。' : '继续保持规律饮食和适量运动。'
  );
  const diastolicItem = buildIndicator(
    '舒张压',
    `${diastolic}mmHg`,
    '< 90mmHg',
    diastolic >= 90 ? '偏高' : '正常',
    diastolic >= 90 ? '保持情绪稳定，避免熬夜和过量咖啡因。' : '继续保持情绪稳定和规律作息。'
  );
  const glucoseItem = buildIndicator(
    '空腹血糖',
    `${glucose}mmol/L`,
    '< 7.0mmol/L',
    glucose >= 7.0 ? '偏高' : '正常',
    glucose >= 7.0 ? '控制精制碳水，记录餐前餐后血糖。' : '维持清淡饮食，避免暴饮暴食。'
  );
  const sleepItem = buildIndicator(
    '睡眠时长',
    `${sleepHours}小时`,
    '>= 7小时',
    sleepHours < 7 ? '不足' : '正常',
    sleepHours < 7 ? '固定入睡时间，睡前减少屏幕刺激。' : '继续保持稳定睡眠节律。'
  );

  const items: IndicatorItem[] = [systolicItem, diastolicItem, glucoseItem, sleepItem];
  for (let index = 0; index < items.length; index++) {
    if (items[index].status === '正常') {
      normalItems.push(items[index]);
    } else {
      abnormalItems.push(items[index]);
    }
  }

  return {
    summary: `本次解读发现${abnormalItems.length}项异常，${normalItems.length}项处于参考范围。`,
    abnormalItems,
    normalItems
  };
}

export function generateMonthlyReport(activeDays: number, abnormalCount: number, constitution: string): MonthlyReport {
  return {
    title: '月度养生报告',
    summary: `本月记录${activeDays}天，发现${abnormalCount}类需要持续关注的健康信号。`,
    suggestion: `结合${constitution}倾向，建议继续保持温和运动、规律饮食和睡眠修复。`
  };
}

function recordDay(timestamp: string): string {
  if (timestamp.length >= 10) {
    return timestamp.substring(0, 10);
  }
  return timestamp;
}

function addUniqueDay(days: string[], timestamp: string): void {
  const day = recordDay(timestamp);
  if (days.indexOf(day) < 0) {
    days.push(day);
  }
}

function numericValue(value: string): number {
  const parsed = Number.parseFloat(value);
  if (Number.isNaN(parsed)) {
    return 0;
  }
  return parsed;
}

function countIndicatorAttentionSignal(entry: HealthIndicatorEntry): number {
  if (entry.name.indexOf('血压') >= 0 && entry.value.indexOf('/') >= 0) {
    const parts = entry.value.split('/');
    const systolic = numericValue(parts[0]);
    const diastolic = numericValue(parts[1]);
    return systolic >= 140 || diastolic >= 90 ? 1 : 0;
  }
  if (entry.name.indexOf('血糖') >= 0) {
    return numericValue(entry.value) >= 7.0 ? 1 : 0;
  }
  if (entry.name.indexOf('睡眠') >= 0) {
    const hours = numericValue(entry.value);
    return hours > 0 && hours < 7 ? 1 : 0;
  }
  return 0;
}

function countTongueAttentionSignal(note: TongueObservationNote): number {
  const coatingNeedsAttention = note.coating.indexOf('厚') >= 0 || note.coating.indexOf('黄') >= 0;
  const drynessNeedsAttention = note.dryness.indexOf('干') >= 0;
  return coatingNeedsAttention || drynessNeedsAttention ? 1 : 0;
}

export function generateLocalMonthlyReport(profile: HealthProfile): MonthlyReport {
  const days: string[] = [];
  let attentionSignals = 0;

  for (let index = 0; index < profile.questionnaireRecords.length; index++) {
    addUniqueDay(days, profile.questionnaireRecords[index].submittedAt);
  }
  for (let index = 0; index < profile.healthIndicators.length; index++) {
    const entry = profile.healthIndicators[index];
    addUniqueDay(days, entry.recordedAt);
    attentionSignals += countIndicatorAttentionSignal(entry);
  }
  for (let index = 0; index < profile.tongueNotes.length; index++) {
    const note = profile.tongueNotes[index];
    addUniqueDay(days, note.recordedAt);
    attentionSignals += countTongueAttentionSignal(note);
  }

  if (days.length === 0) {
    return {
      title: '本地月度养生报告',
      summary: '本月暂无本地记录，报告将在你保存问卷、舌象或指标后自动更新。',
      suggestion: '建议先完成体质问卷，并记录一次舌象或常用健康指标，形成可复盘的基础档案。'
    };
  }

  return {
    title: '本地月度养生报告',
    summary: `本月已记录${days.length}天，发现${attentionSignals}类需要关注的健康信号。`,
    suggestion: `结合${profile.constitution.name}倾向，建议保持规律作息，并优先复盘最近的舌象和指标变化。`
  };
}
