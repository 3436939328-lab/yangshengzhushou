import { PersonalPlan, PlanSegment } from '../model/WellnessModels';

function buildDietPlan(constitution: string, goal: string): PlanSegment {
  if (goal === '控糖') {
    return {
      title: '控糖健脾餐',
      detail: '早餐燕麦山药粥，午餐粗粮饭配清蒸鱼和绿叶菜，晚餐减少精制主食。',
      reason: `${constitution}需要稳定能量供给，控糖目标下优先选择低负担主食。`
    };
  }

  return {
    title: '节气清养餐',
    detail: '以莲子、百合、冬瓜、绿叶菜为主，减少油炸和冰饮。',
    reason: '顺应夏季清心祛湿，降低肠胃负担。'
  };
}

function buildExercisePlan(constitution: string): PlanSegment {
  return {
    title: '温和养气运动',
    detail: '每天 8-12 分钟八段锦，饭后慢走 15 分钟，避免大汗久练。',
    reason: `${constitution}更适合循序渐进的低强度运动。`
  };
}

function buildSleepPlan(sleepHours: number): PlanSegment {
  if (sleepHours < 7) {
    return {
      title: '睡眠修复计划',
      detail: '固定入睡时间，睡前泡脚 15 分钟，减少屏幕刺激和夜间加餐。',
      reason: '睡眠不足会影响代谢、情绪和体力恢复。'
    };
  }

  return {
    title: '睡眠维持计划',
    detail: '保持当前睡眠节律，午休控制在 20 分钟以内。',
    reason: '稳定作息有助于巩固调理效果。'
  };
}

export function generatePersonalPlan(constitution: string, goal: string, sleepHours: number): PersonalPlan {
  return {
    diet: buildDietPlan(constitution, goal),
    exercise: buildExercisePlan(constitution),
    sleep: buildSleepPlan(sleepHours)
  };
}
