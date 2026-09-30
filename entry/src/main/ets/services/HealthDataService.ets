import { ArchiveSummary } from '../model/WellnessModels';
import {
  HealthIndicatorEntry,
  HealthProfile,
  QuestionnaireRecord,
  TongueObservationNote
} from '../model/ProfileModels';

export function buildHealthArchiveSummary(metricCount: number, constitution: string): string {
  return `已纳入${metricCount}项指标，当前体质倾向为${constitution}，建议每周复盘一次趋势。`;
}

export function getArchiveSummaries(): ArchiveSummary[] {
  return [
    {
      title: '体质档案',
      value: '气虚质',
      description: '问卷初筛结果，可继续结合舌象记录完善。'
    },
    {
      title: '指标记录',
      value: '手动',
      description: '当前支持手动录入血压、血糖、睡眠和步数。'
    },
    {
      title: '调理周期',
      value: '14天',
      description: '根据饮食、运动和睡眠记录生成本地报告。'
    }
  ];
}

function addUniqueRecordDay(days: string[], value: string): void {
  const day = value.length >= 10 ? value.substring(0, 10) : value;
  if (day.length === 0) {
    return;
  }
  for (let index = 0; index < days.length; index++) {
    if (days[index] === day) {
      return;
    }
  }
  days.push(day);
}

function countProfileRecordDays(profile: HealthProfile): number {
  const days: string[] = [];
  for (let index = 0; index < profile.questionnaireRecords.length; index++) {
    const record: QuestionnaireRecord = profile.questionnaireRecords[index];
    addUniqueRecordDay(days, record.submittedAt);
  }
  for (let index = 0; index < profile.healthIndicators.length; index++) {
    const entry: HealthIndicatorEntry = profile.healthIndicators[index];
    addUniqueRecordDay(days, entry.recordedAt);
  }
  for (let index = 0; index < profile.tongueNotes.length; index++) {
    const note: TongueObservationNote = profile.tongueNotes[index];
    addUniqueRecordDay(days, note.recordedAt);
  }
  return days.length;
}

export function buildArchiveSummariesFromProfile(profile: HealthProfile): ArchiveSummary[] {
  const questionnaireCount = profile.questionnaireRecords.length;
  const indicatorCount = profile.healthIndicators.length;
  const tongueCount = profile.tongueNotes.length;
  const recordDays = countProfileRecordDays(profile);
  return [
    {
      title: '体质档案',
      value: profile.constitution.name,
      description: questionnaireCount > 0 ? `已完成问卷${questionnaireCount}次，可结合舌象继续复盘。` : '暂无问卷记录，可先完成体质问卷。'
    },
    {
      title: '指标记录',
      value: `${indicatorCount}条`,
      description: `健康指标${indicatorCount}条，舌象${tongueCount}条。`
    },
    {
      title: '记录天数',
      value: `${recordDays}天`,
      description: recordDays > 0 ? '根据本地和后端同步记录生成。' : '保存健康指标或舌象后开始统计。'
    }
  ];
}
