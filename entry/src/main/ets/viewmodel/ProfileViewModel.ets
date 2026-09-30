import { HealthProfile, ReminderPreference } from '../model/ProfileModels';
import {
  ChatMessage,
  HealthMetric,
  HealthRiskSummary,
  MedicalReportInterpretation,
  PersonalPlan
} from '../model/WellnessModels';
import { AssistantReplyResult, requestAssistantReply } from '../services/AssistantReplyService';
import { generatePersonalPlan } from '../services/PersonalPlanService';
import { interpretMedicalIndicators } from '../services/ReportService';
import { summarizeHealthRisk } from '../utils/HealthRiskUtil';

export interface ProfileSummaryData {
  constitutionName: string;
  constitutionSuggestion: string;
  recordCount: number;
  tongueNoteCount: number;
  reminderEnabledCount: number;
  completenessText: string;
  updatedAt: string;
}

export interface RecentRecordItem {
  title: string;
  detail: string;
  tag: string;
  recordedAt: string;
}

function countCompletedProfileSections(profile: HealthProfile): number {
  let completed = 1;
  if (profile.questionnaireRecords.length > 0) {
    completed += 1;
  }
  if (profile.healthIndicators.length > 0) {
    completed += 1;
  }
  if (profile.tongueNotes.length > 0) {
    completed += 1;
  }
  return completed;
}

export function countEnabledReminderPreferences(profile: HealthProfile): number {
  let count = 0;
  for (let index = 0; index < profile.reminderPreferences.length; index++) {
    if (profile.reminderPreferences[index].enabled) {
      count += 1;
    }
  }
  return count;
}

export function toggleReminderPreference(
  reminderPreferences: ReminderPreference[],
  title: string,
  enabled: boolean
): ReminderPreference[] {
  const nextPreferences: ReminderPreference[] = [];
  for (let index = 0; index < reminderPreferences.length; index++) {
    const item = reminderPreferences[index];
    nextPreferences.push({
      title: item.title,
      time: item.time,
      enabled: item.title === title ? enabled : item.enabled
    });
  }
  return nextPreferences;
}

export function createProfileSummary(profile: HealthProfile): ProfileSummaryData {
  const completedSections = countCompletedProfileSections(profile);
  return {
    constitutionName: profile.constitution.name,
    constitutionSuggestion: profile.constitution.suggestion,
    recordCount: profile.questionnaireRecords.length,
    tongueNoteCount: profile.tongueNotes.length,
    reminderEnabledCount: countEnabledReminderPreferences(profile),
    completenessText: `档案完整度 ${completedSections}/4`,
    updatedAt: profile.updatedAt
  };
}

export function buildDisplayMetrics(profile: HealthProfile, fallbackMetrics: HealthMetric[]): HealthMetric[] {
  if (profile.healthIndicators.length === 0) {
    return [];
  }

  const metrics: HealthMetric[] = [];
  for (let index = 0; index < profile.healthIndicators.length; index++) {
    const indicator = profile.healthIndicators[index];
    metrics.push({
      name: indicator.name,
      value: indicator.value,
      unit: indicator.unit,
      status: '本地记录',
      trend: [42, 48, 52, 50, 56]
    });
  }
  return metrics;
}

export function buildRecentIndicatorRecords(profile: HealthProfile, limit: number): RecentRecordItem[] {
  if (limit <= 0) {
    return [];
  }

  const records: RecentRecordItem[] = [];
  const count = Math.min(profile.healthIndicators.length, limit);
  for (let index = 0; index < count; index++) {
    const item = profile.healthIndicators[index];
    records.push({
      title: item.name,
      detail: `${item.value} ${item.unit}`,
      tag: '指标',
      recordedAt: item.recordedAt
    });
  }
  return records;
}

export function buildRecentTongueRecords(profile: HealthProfile, limit: number): RecentRecordItem[] {
  if (limit <= 0) {
    return [];
  }

  const records: RecentRecordItem[] = [];
  const count = Math.min(profile.tongueNotes.length, limit);
  for (let index = 0; index < count; index++) {
    const item = profile.tongueNotes[index];
    const noteText = item.note.length > 0 ? `，${item.note}` : '';
    records.push({
      title: '舌象观察',
      detail: `${item.color}，${item.coating}，${item.dryness}${noteText}`,
      tag: '舌象',
      recordedAt: item.recordedAt
    });
  }
  return records;
}

function parsedIndicatorNumber(value: string): number {
  const parsed = Number.parseFloat(value);
  if (Number.isNaN(parsed)) {
    return 0;
  }
  return parsed;
}

interface LocalVitalValues {
  systolic: number;
  diastolic: number;
  glucose: number;
  sleepHours: number;
}

function defaultVitalValues(): LocalVitalValues {
  return {
    systolic: 118,
    diastolic: 76,
    glucose: 5.4,
    sleepHours: 7.2
  };
}

function buildLocalVitalValues(profile: HealthProfile): LocalVitalValues {
  const values = defaultVitalValues();
  for (let index = 0; index < profile.healthIndicators.length; index++) {
    const indicator = profile.healthIndicators[index];
    if (indicator.name.indexOf('血压') >= 0 && indicator.value.indexOf('/') >= 0) {
      const parts = indicator.value.split('/');
      const systolic = parsedIndicatorNumber(parts[0]);
      const diastolic = parsedIndicatorNumber(parts[1]);
      if (systolic > 0 && diastolic > 0) {
        values.systolic = systolic;
        values.diastolic = diastolic;
      }
    } else if (indicator.name.indexOf('血糖') >= 0) {
      const glucose = parsedIndicatorNumber(indicator.value);
      if (glucose > 0) {
        values.glucose = glucose;
      }
    } else if (indicator.name.indexOf('睡眠') >= 0) {
      const sleepHours = parsedIndicatorNumber(indicator.value);
      if (sleepHours > 0) {
        values.sleepHours = sleepHours;
      }
    }
  }
  return values;
}

export function buildLocalHealthRisk(profile: HealthProfile): HealthRiskSummary {
  const values = buildLocalVitalValues(profile);
  return summarizeHealthRisk(values.systolic, values.diastolic, values.glucose, values.sleepHours);
}

export function buildLocalMedicalReport(
  profile: HealthProfile,
  fallbackReport: MedicalReportInterpretation
): MedicalReportInterpretation {
  if (profile.healthIndicators.length === 0) {
    return fallbackReport;
  }
  const values = buildLocalVitalValues(profile);
  return interpretMedicalIndicators(values.systolic, values.diastolic, values.glucose, values.sleepHours);
}

export function inferHomeGoal(profile: HealthProfile): string {
  for (let index = 0; index < profile.healthIndicators.length; index++) {
    const indicator = profile.healthIndicators[index];
    if (indicator.name.indexOf('血糖') >= 0) {
      return '控糖';
    }
    if (indicator.name.indexOf('血压') >= 0) {
      return '稳压';
    }
  }
  return '节气养护';
}

export function inferSleepHours(profile: HealthProfile): number {
  for (let index = profile.healthIndicators.length - 1; index >= 0; index--) {
    const indicator = profile.healthIndicators[index];
    if (indicator.name.indexOf('睡眠') >= 0) {
      const hours = parsedIndicatorNumber(indicator.value);
      if (hours > 0) {
        return hours;
      }
    }
  }
  return 7.2;
}

function hasDryTongueNote(profile: HealthProfile): boolean {
  for (let index = profile.tongueNotes.length - 1; index >= 0; index--) {
    if (profile.tongueNotes[index].dryness.indexOf('干') >= 0) {
      return true;
    }
  }
  return false;
}

export function buildLocalPersonalPlan(profile: HealthProfile): PersonalPlan {
  const plan = generatePersonalPlan(profile.constitution.name, inferHomeGoal(profile), inferSleepHours(profile));
  if (!hasDryTongueNote(profile)) {
    return plan;
  }

  return {
    diet: {
      title: plan.diet.title,
      detail: `${plan.diet.detail} 近期舌象偏干时，可少量多次饮用温水。`,
      reason: plan.diet.reason
    },
    exercise: plan.exercise,
    sleep: plan.sleep
  };
}

export function appendLocalAssistantReply(
  messages: ChatMessage[],
  question: string,
  profile: HealthProfile
): ChatMessage[] {
  const normalizedQuestion = question.trim();
  if (normalizedQuestion.length === 0) {
    return messages;
  }

  return appendAssistantReplyResult(
    appendUserQuestion(messages, normalizedQuestion),
    requestAssistantReply(normalizedQuestion, profile)
  );
}

export function appendUserQuestion(messages: ChatMessage[], question: string): ChatMessage[] {
  const normalizedQuestion = question.trim();
  if (normalizedQuestion.length === 0) {
    return messages;
  }
  const nextMessages = messages.slice();
  nextMessages.push({
    role: 'user',
    id: `user-${Date.now()}-${messages.length}`,
    content: normalizedQuestion
  });
  return nextMessages;
}

export function appendAssistantReplyResult(
  messages: ChatMessage[],
  reply: AssistantReplyResult
): ChatMessage[] {
  if (reply.content.trim().length === 0) {
    return messages;
  }
  const nextMessages = messages.slice();
  nextMessages.push({
    role: 'assistant',
    id: `assistant-${Date.now()}-${messages.length}`,
    content: reply.content,
    source: reply.source,
    suggestions: reply.suggestions,
    plan: reply.plan,
    riskLevel: reply.riskLevel
  });
  return nextMessages;
}

export function buildAssistantSourceText(source: string, backendMode: string): string {
  const normalizedSource = source.trim().length > 0 ? source.trim() : '大模型未连接';
  return `回复来源：${normalizedSource}`;
}

export function canSendAssistantQuestion(question: string, isSending: boolean): boolean {
  return question.trim().length > 0 && !isSending;
}
