import { AdminAssistantLogItem } from './AdminAssistantLogService';
import { AdminUserItem } from './AdminPeopleService';
import { AdminRoleItem, AdminUserRoleItem } from './AdminRoleService';
import { ConsultationThread } from './ConsultationService';

export interface AdminOverviewMetrics {
  totalUsers: number;
  normalUsers: number;
  adminUsers: number;
  doctorUsers: number;
  roleBindings: number;
  assistantLogCount: number;
  consultationCount: number;
}

function roleIdByCode(roles: AdminRoleItem[], rawRoleCode: string): string {
  const targetCode = rawRoleCode.trim().toUpperCase();
  for (let index = 0; index < roles.length; index++) {
    if (roles[index].roleCode === targetCode) {
      return roles[index].id;
    }
  }
  return '';
}

function hasRawRole(userRoles: AdminUserRoleItem[], roles: AdminRoleItem[], userId: string, rawRoleCode: string): boolean {
  const roleId = roleIdByCode(roles, rawRoleCode);
  if (roleId.length === 0) {
    return false;
  }
  return userRoles.filter((binding: AdminUserRoleItem) => {
    return binding.userId === userId && binding.roleId === roleId;
  }).length > 0;
}

function hasElevatedRole(userRoles: AdminUserRoleItem[], roles: AdminRoleItem[], userId: string): boolean {
  return hasRawRole(userRoles, roles, userId, 'ADMIN')
    || hasRawRole(userRoles, roles, userId, 'DOCTOR')
    || hasRawRole(userRoles, roles, userId, 'ADVISER');
}

function countUsersByRole(userRoles: AdminUserRoleItem[], roles: AdminRoleItem[], rawRoleCode: string): number {
  const roleId = roleIdByCode(roles, rawRoleCode);
  if (roleId.length === 0) {
    return 0;
  }
  return userRoles.filter((binding: AdminUserRoleItem) => binding.roleId === roleId).length;
}

function countDoctorUsers(userRoles: AdminUserRoleItem[], roles: AdminRoleItem[]): number {
  const doctorRoleId = roleIdByCode(roles, 'DOCTOR');
  const adviserRoleId = roleIdByCode(roles, 'ADVISER');
  const userIds: string[] = [];
  for (let index = 0; index < userRoles.length; index++) {
    const binding = userRoles[index];
    const isDoctorBinding = binding.roleId === doctorRoleId || binding.roleId === adviserRoleId;
    if (isDoctorBinding && userIds.indexOf(binding.userId) < 0) {
      userIds.push(binding.userId);
    }
  }
  return userIds.length;
}

function countNormalUsers(users: AdminUserItem[], userRoles: AdminUserRoleItem[], roles: AdminRoleItem[]): number {
  let count = 0;
  for (let index = 0; index < users.length; index++) {
    if (!hasElevatedRole(userRoles, roles, users[index].id)) {
      count++;
    }
  }
  return count;
}

export function buildAdminOverviewMetrics(
  users: AdminUserItem[],
  roles: AdminRoleItem[],
  userRoles: AdminUserRoleItem[],
  assistantLogs: AdminAssistantLogItem[],
  consultations: ConsultationThread[]
): AdminOverviewMetrics {
  const metrics: AdminOverviewMetrics = {
    totalUsers: users.length,
    normalUsers: countNormalUsers(users, userRoles, roles),
    adminUsers: countUsersByRole(userRoles, roles, 'ADMIN'),
    doctorUsers: countDoctorUsers(userRoles, roles),
    roleBindings: userRoles.length,
    assistantLogCount: assistantLogs.length,
    consultationCount: consultations.length
  };
  return metrics;
}
