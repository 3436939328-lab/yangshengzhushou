export type SaveFeedbackTarget = 'tongueNote' | 'healthIndicator' | 'questionnaire' | 'reminder';

export function buildSaveSuccessText(target: SaveFeedbackTarget): string {
  if (target === 'tongueNote') {
    return '舌象记录已保存';
  }
  if (target === 'healthIndicator') {
    return '健康指标已保存';
  }
  if (target === 'questionnaire') {
    return '问卷结果已保存';
  }
  return '提醒设置已保存';
}

export function buildSaveFailureText(target: SaveFeedbackTarget): string {
  if (target === 'tongueNote') {
    return '舌象记录保存失败，请保留输入后重试';
  }
  if (target === 'healthIndicator') {
    return '健康指标保存失败，请保留输入后重试';
  }
  if (target === 'questionnaire') {
    return '问卷结果保存失败，请稍后重试';
  }
  return '提醒设置保存失败，请稍后重试';
}
