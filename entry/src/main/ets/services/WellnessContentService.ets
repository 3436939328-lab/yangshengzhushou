import {
  ChatMessage,
  GuideSlide,
  HealthMetric,
  ProfileAction,
  QuickAction,
  ReminderItem,
  WellnessPlan
} from '../model/WellnessModels';

export function getGuideSlides(): GuideSlide[] {
  return [
    {
      title: '节气与天气养护',
      description: '获取当前节气、湿度和温度，交给大模型生成每日调理重点。'
    },
    {
      title: '本地体质初筛',
      description: '记录问卷、舌象文字和症状，作为大模型生成建议的依据。'
    },
    {
      title: '本地健康档案',
      description: '手动记录血压、血糖、睡眠和运动，形成长期健康档案。'
    }
  ];
}

export function getDailyPlans(): WellnessPlan[] {
  return [
    {
      title: '晨间养气',
      time: '07:30',
      detail: '八段锦 8 分钟，配合鼻吸口呼。',
      tag: '运动'
    },
    {
      title: '午后清心',
      time: '13:00',
      detail: '莲子百合饮，减少冰饮和辛辣。',
      tag: '食疗'
    },
    {
      title: '睡前安神',
      time: '22:00',
      detail: '温水泡脚 15 分钟，按摩神门穴。',
      tag: '作息'
    }
  ];
}

export function getQuickActions(): QuickAction[] {
  return [
    { title: '体质问卷', description: '快速记录调理线索' },
    { title: '舌象记录', description: '记录舌象文字特征' },
    { title: '食疗茶饮', description: '由大模型生成建议' },
    { title: '穴位按揉', description: '由大模型生成建议' }
  ];
}

export function getAssistantMessages(): ChatMessage[] {
  return [];
}

export function getHealthMetrics(): HealthMetric[] {
  return [
    { name: '血压', value: '118/76', unit: 'mmHg', status: '平稳', trend: [46, 52, 48, 56, 54] },
    { name: '血糖', value: '5.4', unit: 'mmol/L', status: '正常', trend: [42, 40, 45, 43, 44] },
    { name: '睡眠', value: '7.1', unit: '小时', status: '可改善', trend: [35, 48, 50, 44, 52] },
    { name: '步数', value: '6820', unit: '步', status: '达标中', trend: [30, 50, 44, 58, 62] }
  ];
}

export function getProfileActions(): ProfileAction[] {
  return [
    { title: '健康档案', description: '体质、舌象、指标和月度报告已在本页汇总。', status: '本页可用' },
    { title: '设备管理', description: '设备同步暂未接入，当前以手动记录为主。', status: '暂未接入' },
    { title: '提醒管理', description: '饮水、久坐和睡前提醒可在下方开关管理。', status: '本页可用' },
    { title: '隐私设置', description: '本地存储、云同步和设备权限状态已在隐私卡片展示。', status: '本页可用' }
  ];
}

export function getReminderItems(): ReminderItem[] {
  return [
    { title: '饮水提醒', time: '10:00', enabled: true },
    { title: '久坐拉伸', time: '15:30', enabled: true },
    { title: '睡前泡脚', time: '21:40', enabled: false }
  ];
}
