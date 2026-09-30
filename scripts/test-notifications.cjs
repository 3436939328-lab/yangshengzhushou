const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const Module = require('node:module');
const ts = require(process.env.TYPESCRIPT_PATH || 'D:/DevEcoStudio/DevEcoStudio/tools/ohpm/node_modules/typescript');
require.extensions['.ets'] = (module, filename) => module._compile(ts.transpileModule(fs.readFileSync(filename, 'utf8'), { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText, filename);
let registered = [], value = '', sequence = 0, enabled = true, prompts = 0, failFlush = false;
const events = [];
const agent = {
  ReminderType: { REMINDER_TYPE_ALARM: 2, REMINDER_TYPE_TIMER: 0 },
  async publishReminder(request) { const id = ++sequence; registered.push({ reminderId: id, reminderReq: request }); events.push(`publish:${id}`); return id; },
  async cancelReminder(id) { events.push(`cancel:${id}`); registered = registered.filter(item => item.reminderId !== id); },
  async getAllValidReminders() { return registered; }
};
const notifications = {
  async isNotificationEnabled() { return enabled; },
  async requestEnableNotification() { prompts++; enabled = true; }
};
const storage = { getSync() { return value; }, putSync(key, next) { value = next; }, async flush() { events.push('flush'); if (failFlush) { failFlush = false; throw new Error('disk full'); } } };
const load = Module._load;
Module._load = function(name, parent, main) {
  if (name === '@ohos.reminderAgentManager') return { default: agent };
  if (name === '@ohos.notificationManager') return { default: notifications };
  if (name === '@kit.ArkData') return { preferences: { async getPreferences() { return storage; } } };
  if (name === '@kit.AbilityKit') return {};
  return load.call(this, name, parent, main);
};
const service = require(path.resolve(__dirname, '../entry/src/main/ets/services/NotificationService.ets'));
const context = { abilityInfo: { bundleName: 'test.bundle' } };
const reminder = { title: 'Drink water', time: '08:30', enabled: true };
async function run() {
  await service.applyReminder(context, '1', reminder);
  assert.equal(registered.length, 1);
  assert.equal(registered[0].reminderReq.hour, 8);
  assert.equal(registered[0].reminderReq.minute, 30);
  assert.deepEqual(registered[0].reminderReq.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);
  await service.applyReminder(context, '1', reminder);
  assert.equal(registered.length, 1, 'repeated enable is idempotent');
  events.length = 0;
  await service.applyReminder(context, '1', { ...reminder, time: '09:30' });
  assert.ok(events.indexOf('flush') < events.indexOf('cancel:1'), 'replacement commits before old schedule cancellation');
  assert.equal(registered.length, 1);
  const previous = registered[0].reminderId;
  failFlush = true;
  await assert.rejects(service.applyReminder(context, '1', { ...reminder, time: '10:30' }));
  assert.equal(registered.length, 1, 'failed storage rolls back new schedule');
  assert.equal(registered[0].reminderId, previous, 'old schedule survives failed replacement');
  await service.applyReminder(context, '2', reminder);
  await service.cancelUserReminders(context, '1');
  assert.equal(registered.length, 1, 'logout cancels only the current user');
  enabled = false;
  const reconciled = await service.reconcileReminders(context, '2', [reminder]);
  assert.equal(reconciled[0].enabled, false);
  assert.equal(prompts, 0, 'reconciliation never prompts');
  await service.sendTestReminder(context);
  assert.equal(prompts, 1);
  assert.ok(registered.some(item => item.reminderReq.triggerTimeInSeconds === 10));
  console.log('PASS reminders: OS registration, idempotency, commit ordering, rollback, account isolation, permission reconciliation and timer');
}
run().catch(error => { console.error(error); process.exitCode = 1; });
