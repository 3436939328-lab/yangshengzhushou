import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import reminderAgentManager from '@ohos.reminderAgentManager';
import notificationManager from '@ohos.notificationManager';
import { ReminderPreference } from '../model/ProfileModels';

interface ReminderRegistration {
  scope: string;
  title: string;
  time: string;
  reminderId: number;
  groupId: string;
  active: boolean;
}

const STORE_NAME: string = 'wellness_system_reminders_v1';
const STORE_KEY: string = 'registrations';
let pendingOperation: Promise<void> = Promise.resolve();

function serialize<T>(operation: () => Promise<T>): Promise<T> {
  const result: Promise<T> = pendingOperation.then(operation);
  pendingOperation = result.then(() => {}, () => {});
  return result;
}

function userScope(userId: string | number): string {
  const id: string = String(userId).trim();
  if (id.length === 0) {
    throw new Error('请先登录再设置提醒');
  }
  return `user:${id}`;
}

async function readRegistrations(context: common.UIAbilityContext): Promise<ReminderRegistration[]> {
  const store = await preferences.getPreferences(context, { name: STORE_NAME });
  const value = store.getSync(STORE_KEY, '');
  if (typeof value !== 'string' || value.length === 0) {
    return [];
  }
  const records = JSON.parse(value) as ReminderRegistration[];
  if (!Array.isArray(records)) {
    throw new Error('提醒记录无法读取，请稍后重试');
  }
  for (const record of records) {
    if (typeof record.scope !== 'string' || typeof record.title !== 'string' ||
      typeof record.groupId !== 'string' || typeof record.reminderId !== 'number') {
      throw new Error('提醒记录无法读取，请稍后重试');
    }
  }
  return records;
}

async function writeRegistrations(context: common.UIAbilityContext,
  records: ReminderRegistration[]): Promise<void> {
  const store = await preferences.getPreferences(context, { name: STORE_NAME });
  const previous = store.getSync(STORE_KEY, '');
  store.putSync(STORE_KEY, JSON.stringify(records));
  try {
    await store.flush();
  } catch (error) {
    store.putSync(STORE_KEY, previous);
    try {
      await store.flush();
    } catch (restoreError) {
      throw new Error('提醒记录保存失败，请检查设备存储后重试');
    }
    throw new Error('提醒记录保存失败，未应用本次设置');
  }
}

async function requestNotificationPermission(context: common.UIAbilityContext): Promise<void> {
  if (!(await notificationManager.isNotificationEnabled())) {
    await notificationManager.requestEnableNotification(context);
  }
  if (!(await notificationManager.isNotificationEnabled())) {
    throw new Error('通知权限未开启，无法设置提醒');
  }
}

function isRegistered(record: ReminderRegistration,
  valid: reminderAgentManager.ReminderInfo[]): boolean {
  return valid.some((item: reminderAgentManager.ReminderInfo) =>
    item.reminderId === record.reminderId && item.reminderReq.groupId === record.groupId);
}

async function cancelRegistration(record: ReminderRegistration): Promise<void> {
  const valid = await reminderAgentManager.getAllValidReminders();
  if (isRegistered(record, valid)) {
    await reminderAgentManager.cancelReminder(record.reminderId);
  }
}

function newGroupId(scope: string): string {
  return `wellness:${scope}:${Date.now()}:${Math.floor(Math.random() * 1000000000)}`;
}

// Keep both IDs until the replacement is durable so failed storage never loses the old schedule.
async function commitReplacement(context: common.UIAbilityContext, records: ReminderRegistration[],
  replacement: ReminderRegistration): Promise<void> {
  const previous = records.filter((item: ReminderRegistration) =>
    item.scope === replacement.scope && item.title === replacement.title);
  const retained = records.filter((item: ReminderRegistration) =>
    item.scope !== replacement.scope || item.title !== replacement.title);
  const pending: ReminderRegistration[] = retained.concat(previous.map((item: ReminderRegistration) => {
    const retired: ReminderRegistration = {
      scope: item.scope, title: item.title, time: item.time,
      reminderId: item.reminderId, groupId: item.groupId, active: false
    };
    return retired;
  }));
  pending.push(replacement);
  try {
    await writeRegistrations(context, pending);
  } catch (error) {
    await reminderAgentManager.cancelReminder(replacement.reminderId);
    throw new Error((error as Error).message);
  }
  for (const item of previous) {
    await cancelRegistration(item);
  }
  retained.push(replacement);
  await writeRegistrations(context, retained);
}

export function applyReminder(context: common.UIAbilityContext, userId: string | number,
  item: ReminderPreference): Promise<void> {
  return serialize(async () => {
    const scope: string = userScope(userId);
    const records = await readRegistrations(context);
    const matching = records.filter((record: ReminderRegistration) =>
      record.scope === scope && record.title === item.title);
    if (!item.enabled) {
      for (const record of matching) {
        await cancelRegistration(record);
      }
      await writeRegistrations(context, records.filter((record: ReminderRegistration) =>
        record.scope !== scope || record.title !== item.title));
      return;
    }
    if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(item.time) || item.title.trim().length === 0) {
      throw new Error('请选择有效的提醒名称和时间');
    }
    await requestNotificationPermission(context);
    const valid = await reminderAgentManager.getAllValidReminders();
    if (matching.length === 1 && matching[0].active && matching[0].time === item.time &&
      isRegistered(matching[0], valid)) {
      return;
    }
    const timeParts: string[] = item.time.split(':');
    const groupId: string = newGroupId(scope);
    const request: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: Number(timeParts[0]), minute: Number(timeParts[1]),
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      title: '养生提醒', content: item.title, expiredContent: item.title,
      groupId: groupId, notificationId: Math.floor(Math.random() * 2000000000),
      ringDuration: 1, snoozeTimes: 0, tapDismissed: true
    };
    const reminderId: number = await reminderAgentManager.publishReminder(request);
    const replacement: ReminderRegistration = {
      scope: scope, title: item.title, time: item.time,
      reminderId: reminderId, groupId: groupId, active: true
    };
    try {
      if (!isRegistered(replacement, await reminderAgentManager.getAllValidReminders())) {
        throw new Error('系统未确认提醒，请稍后重试');
      }
    } catch (error) {
      await reminderAgentManager.cancelReminder(reminderId);
      throw new Error((error as Error).message);
    }
    await commitReplacement(context, records, replacement);
  });
}

export function cancelUserReminders(context: common.UIAbilityContext,
  userId: string | number): Promise<void> {
  return serialize(async () => {
    const scope: string = userScope(userId);
    const records = await readRegistrations(context);
    for (const record of records) {
      if (record.scope === scope) {
        await cancelRegistration(record);
      }
    }
    await writeRegistrations(context, records.filter((record: ReminderRegistration) => record.scope !== scope));
  });
}

export function reconcileReminders(context: common.UIAbilityContext, userId: string | number,
  items: ReminderPreference[]): Promise<ReminderPreference[]> {
  return serialize(async () => {
    const scope: string = userScope(userId);
    const records = await readRegistrations(context);
    const permitted: boolean = await notificationManager.isNotificationEnabled();
    const valid = await reminderAgentManager.getAllValidReminders();
    const retained: ReminderRegistration[] = [];
    for (const record of records) {
      if (record.scope !== scope) {
        retained.push(record);
        continue;
      }
      const wanted: boolean = items.some((item: ReminderPreference) =>
        item.enabled && item.title === record.title && item.time === record.time);
      if (!record.active || !wanted) {
        await cancelRegistration(record);
      } else if (isRegistered(record, valid)) {
        retained.push(record);
      }
    }
    await writeRegistrations(context, retained);
    return items.map((item: ReminderPreference) => {
      const updated: ReminderPreference = {
        title: item.title, time: item.time,
        enabled: item.enabled && permitted && retained.some((record: ReminderRegistration) =>
          record.scope === scope && record.active && record.title === item.title &&
            record.time === item.time && isRegistered(record, valid))
      };
      return updated;
    });
  });
}

export function sendTestReminder(context: common.UIAbilityContext): Promise<void> {
  return serialize(async () => {
    await requestNotificationPermission(context);
    const records = await readRegistrations(context);
    const groupId: string = newGroupId('test');
    const request: reminderAgentManager.ReminderRequestTimer = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
      triggerTimeInSeconds: 10, title: '养生提醒测试', content: '系统提醒已送达',
      groupId: groupId, notificationId: Math.floor(Math.random() * 2000000000),
      ringDuration: 1, snoozeTimes: 0, tapDismissed: true
    };
    const reminderId: number = await reminderAgentManager.publishReminder(request);
    const replacement: ReminderRegistration = {
      scope: 'test', title: 'test', time: '', reminderId: reminderId,
      groupId: groupId, active: true
    };
    await commitReplacement(context, records, replacement);
  });
}

export function formatReminderSummary(enabledCount: number, totalCount: number): string {
  return `已开启${enabledCount}/${totalCount}个提醒`;
}
