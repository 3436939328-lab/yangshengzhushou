import { AdminAssistantLogGroup, AdminAssistantLogItem } from './AdminAssistantLogService';
import { ConsultationThread } from './ConsultationService';

export interface AdminAssistantLogMetrics {
  totalLogs: number;
  userCount: number;
  answeredLogs: number;
}

export interface AdminConsultationMetrics {
  totalConsultations: number;
  ongoingConsultations: number;
  repliedConsultations: number;
}

export function buildAdminAssistantLogMetrics(
  logs: AdminAssistantLogItem[],
  groups: AdminAssistantLogGroup[]
): AdminAssistantLogMetrics {
  const metrics: AdminAssistantLogMetrics = {
    totalLogs: logs.length,
    userCount: groups.length,
    answeredLogs: logs.filter((item: AdminAssistantLogItem) => item.status === 1).length
  };
  return metrics;
}

export function buildAdminConsultationMetrics(consultations: ConsultationThread[]): AdminConsultationMetrics {
  const metrics: AdminConsultationMetrics = {
    totalConsultations: consultations.length,
    ongoingConsultations: consultations.filter((item: ConsultationThread) => item.statusCode === 0).length,
    repliedConsultations: consultations.filter((item: ConsultationThread) => item.statusCode === 1).length
  };
  return metrics;
}
