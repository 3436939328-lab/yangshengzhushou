import { HealthProfile } from '../model/ProfileModels';

export function generateHealthAnswer(question: string, constitution: string): string {
  const normalizedQuestion = question.trim().length > 0 ? question.trim() : '日常调理';

  return `针对“${normalizedQuestion}”，当前体质倾向为${constitution}。建议先从规律作息、清淡饮食和温和运动入手，持续记录症状变化。本建议不能替代医生诊断，若症状持续、加重或伴随明显疼痛，请及时就医。`;
}

function latestTongueContext(profile: HealthProfile): string {
  if (profile.tongueNotes.length === 0) {
    return '';
  }
  const note = profile.tongueNotes[0];
  return `最近舌象记录为${note.color}、${note.coating}、${note.dryness}`;
}

function latestIndicatorContext(profile: HealthProfile): string {
  if (profile.healthIndicators.length === 0) {
    return '';
  }
  const indicator = profile.healthIndicators[0];
  return `最近指标为${indicator.name} ${indicator.value}${indicator.unit}`;
}

export function generateContextualHealthAnswer(question: string, profile: HealthProfile): string {
  const normalizedQuestion = question.trim().length > 0 ? question.trim() : '日常调理';
  const contexts: string[] = [`当前体质倾向为${profile.constitution.name}`];
  const tongueContext = latestTongueContext(profile);
  const indicatorContext = latestIndicatorContext(profile);

  if (tongueContext.length > 0) {
    contexts.push(tongueContext);
  }
  if (indicatorContext.length > 0) {
    contexts.push(indicatorContext);
  }

  return `针对“${normalizedQuestion}”，${contexts.join('，')}。建议继续保持规律作息、清淡饮食和温和运动，并结合每日记录观察变化。本建议不能替代医生诊断，若症状持续、加重或伴随明显疼痛，请及时就医。`;
}
