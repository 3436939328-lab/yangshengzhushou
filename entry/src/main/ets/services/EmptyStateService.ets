import { EmptyStateInfo } from '../model/WellnessModels';

export function getEmptyStateInfo(key: string): EmptyStateInfo {
  if (key === 'records') {
    return {
      title: '暂无本地记录',
      detail: '保存舌象或健康指标后，会在这里看到最近记录。'
    };
  }
  if (key === 'indicators') {
    return {
      title: '暂无本地指标',
      detail: '手动记录血压、血糖、睡眠或步数后，数据页会优先展示本地结果。'
    };
  }
  if (key === 'reminders') {
    return {
      title: '暂无提醒偏好',
      detail: '开启饮水、久坐或睡前提醒后，会在这里统一管理。'
    };
  }
  if (key === 'monthlyReport') {
    return {
      title: '暂无报告记录',
      detail: '完成问卷并记录舌象或指标后，月度报告会自动更新。'
    };
  }
  if (key === 'profileLoad') {
    return {
      title: '本地档案暂不可用',
      detail: '已使用默认档案继续展示，稍后重新进入页面可再次尝试读取本地记录。'
    };
  }
  return {
    title: '暂无可显示内容',
    detail: '继续使用应用后，这里会显示与你相关的本地内容。'
  };
}
