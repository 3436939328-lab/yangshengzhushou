import { AdminUserItem } from './AdminPeopleService';
import { AdminRoleItem, AdminUserRoleItem } from './AdminRoleService';

export type AdminPeopleFilter = 'ALL' | 'USER' | 'ADMIN' | 'DOCTOR';

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

function hasDoctorRole(userRoles: AdminUserRoleItem[], roles: AdminRoleItem[], userId: string): boolean {
  return hasRawRole(userRoles, roles, userId, 'DOCTOR') || hasRawRole(userRoles, roles, userId, 'ADVISER');
}

export function buildFilteredAdminUsers(
  users: AdminUserItem[],
  roles: AdminRoleItem[],
  userRoles: AdminUserRoleItem[],
  filter: AdminPeopleFilter
): AdminUserItem[] {
  return users.filter((user: AdminUserItem) => {
    if (filter === 'ALL') {
      return true;
    }
    if (filter === 'USER') {
      return !hasElevatedRole(userRoles, roles, user.id);
    }
    if (filter === 'DOCTOR') {
      return hasDoctorRole(userRoles, roles, user.id);
    }
    return hasRawRole(userRoles, roles, user.id, filter);
  });
}
