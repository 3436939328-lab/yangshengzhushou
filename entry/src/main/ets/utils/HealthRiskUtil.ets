import { HealthRiskSummary } from '../model/WellnessModels';

export function summarizeHealthRisk(systolic: number, diastolic: number, glucose: number, sleepHours: number): HealthRiskSummary {
  const actions: string[] = [];

  if (systolic >= 140 || diastolic >= 90) {
    actions.push('连续三天记录早晚血压，减少高盐饮食。');
  }

  if (glucose >= 7.0) {
    actions.push('记录餐前餐后血糖，并控制精制碳水。');
  }

  if (sleepHours < 7) {
    actions.push('睡前减少屏幕刺激，安排固定入睡时间。');
  }

  if (actions.length === 0) {
    return {
      level: '平稳',
      message: '当前核心指标保持平稳，可继续维持今日养生计划。',
      actions: ['保持规律饮食、温和运动和充足睡眠。']
    };
  }

  return {
    level: '需关注',
    message: '血压、血糖或睡眠指标存在波动，建议加强记录和生活方式干预。',
    actions
  };
}
