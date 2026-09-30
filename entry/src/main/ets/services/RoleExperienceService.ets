export interface RoleTabItem {
  key: string;
  label: string;
}

export function normalizeRoleCode(roleCode: string): string {
  const value = roleCode.trim().toUpperCase();
  if (value === 'ADVISER') {
    return 'DOCTOR';
  }
  if (value === 'ADMIN' || value === 'DOCTOR' || value === 'USER') {
    return value;
  }
  return 'USER';
}

export function resolvePrimaryRole(roles: string[]): string {
  const normalizedRoles = roles.map((role: string) => normalizeRoleCode(role));
  if (normalizedRoles.indexOf('ADMIN') >= 0) {
    return 'ADMIN';
  }
  if (normalizedRoles.indexOf('DOCTOR') >= 0) {
    return 'DOCTOR';
  }
  return 'USER';
}

export function normalizeRoleList(roles: string[]): string[] {
  const values: string[] = [];
  for (let index = 0; index < roles.length; index++) {
    const role = normalizeRoleCode(roles[index]);
    if (values.indexOf(role) < 0) {
      values.push(role);
    }
  }
  if (values.length === 0) {
    values.push('USER');
  }
  return values;
}

export function getRoleTabs(primaryRole: string): RoleTabItem[] {
  const role = normalizeRoleCode(primaryRole);
  if (role === 'ADMIN') {
    return [
      { key: 'adminOverview', label: '总览' },
      { key: 'adminPeople', label: '人员' },
      { key: 'adminAssistantLogs', label: '问答' },
      { key: 'adminConsultations', label: '问诊' },
      { key: 'profile', label: '我的' }
    ];
  }
  if (role === 'DOCTOR') {
    return [
      { key: 'doctorWorkbench', label: '工作台' },
      { key: 'doctorConsultation', label: '问诊' },
      { key: 'assistant', label: '助手' },
      { key: 'doctorProfile', label: '资料' },
      { key: 'profile', label: '我的' }
    ];
  }
  return [
    { key: 'home', label: '首页' },
    { key: 'assistant', label: '助手' },
    { key: 'health', label: '健康' },
    { key: 'consultation', label: '问诊' },
    { key: 'family', label: '亲人' },
    { key: 'profile', label: '我的' }
  ];
}

export function resolveAuthorizedTabIndex(primaryRole: string, requestedTabKey: string): number {
  const tabs = getRoleTabs(primaryRole);
  for (let index = 0; index < tabs.length; index++) {
    if (tabs[index].key === requestedTabKey) {
      return index;
    }
  }
  return 0;
}

export function resolveAuthorizedTabKey(primaryRole: string, requestedTabKey: string): string {
  const tabs = getRoleTabs(primaryRole);
  return tabs[resolveAuthorizedTabIndex(primaryRole, requestedTabKey)].key;
}
