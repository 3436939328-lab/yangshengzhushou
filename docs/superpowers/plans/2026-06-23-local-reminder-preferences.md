# Local Reminder Preferences Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make reminder toggles in the profile tab read from and save to the local health profile.

**Architecture:** Add pure reminder helpers to `ProfileViewModel`, then update `ProfileTab` to render `localProfile.reminderPreferences` and persist toggle changes through `HealthProfileRepository.updateReminderPreferences()`.

**Tech Stack:** HarmonyOS ArkTS, ArkUI `Toggle`, Hypium unit tests, existing `HealthProfileRepository`.

---

## File Structure

- Modify `entry/src/test/LocalUnit.test.ets`: add reminder helper tests.
- Modify `entry/src/main/ets/viewmodel/ProfileViewModel.ets`: add count and toggle helpers.
- Modify `entry/src/main/ets/components/tabs/ProfileTab.ets`: switch reminder list from mock props to local profile preferences.

## Task 1: Add Reminder Helper Tests

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Add imports**

Merge these helpers into the existing `ProfileViewModel` import:

```ts
import {
  buildDisplayMetrics,
  countEnabledReminderPreferences,
  createProfileSummary,
  toggleReminderPreference
} from '../main/ets/viewmodel/ProfileViewModel';
```

- [ ] **Step 2: Add tests**

Add these tests after the existing profile summary test:

```ts
    it('counts enabled local reminder preferences', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');

      expect(countEnabledReminderPreferences(profile)).assertEqual(2);
    });

    it('toggles local reminder preference off', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const preferences = toggleReminderPreference(profile.reminderPreferences, '饮水提醒', false);

      expect(preferences[0].enabled).assertFalse();
    });

    it('leaves reminders unchanged for unknown title', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const preferences = toggleReminderPreference(profile.reminderPreferences, '不存在的提醒', false);

      expect(preferences[0].enabled).assertTrue();
      expect(preferences.length).assertEqual(3);
    });
```

- [ ] **Step 3: Run red test**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: compile failure because the two helper functions do not exist yet. In current Codex shell, record `CommandNotFoundException` if `hvigor` remains unavailable.

## Task 2: Implement Reminder Helpers

**Files:**
- Modify: `entry/src/main/ets/viewmodel/ProfileViewModel.ets`

- [ ] **Step 1: Add imports**

Change the model import to include `ReminderPreference`:

```ts
import { HealthProfile, ReminderPreference } from '../model/ProfileModels';
```

- [ ] **Step 2: Export enabled-count helper**

Change the existing private helper:

```ts
function countEnabledReminders(profile: HealthProfile): number {
```

to:

```ts
export function countEnabledReminderPreferences(profile: HealthProfile): number {
```

Update `createProfileSummary()` to call `countEnabledReminderPreferences(profile)`.

- [ ] **Step 3: Add toggle helper**

Add:

```ts
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
```

- [ ] **Step 4: Run green test**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: reminder helper tests pass.

## Task 3: Wire Local Reminder Preferences Into ProfileTab

**Files:**
- Modify: `entry/src/main/ets/components/tabs/ProfileTab.ets`

- [ ] **Step 1: Add imports**

Add:

```ts
import { ReminderPreference } from '../../model/ProfileModels';
import {
  countEnabledReminderPreferences,
  toggleReminderPreference
} from '../../viewmodel/ProfileViewModel';
```

- [ ] **Step 2: Use local reminders for summary**

Replace the current `reminders` and manual count block:

```ts
    const reminders = this.reminders;
    let enabledReminderCount = 0;
    for (let index = 0; index < reminders.length; index++) {
      if (reminders[index].enabled) {
        enabledReminderCount += 1;
      }
    }
    const reminderSummary = formatReminderSummary(enabledReminderCount, reminders.length);
```

with:

```ts
    const reminders = this.localProfile.reminderPreferences;
    const enabledReminderCount = countEnabledReminderPreferences(this.localProfile);
    const reminderSummary = formatReminderSummary(enabledReminderCount, reminders.length);
```

- [ ] **Step 3: Update reminder row type and toggle save**

Replace the reminder `ForEach` callback type from `ReminderItem` to `ReminderPreference`.

Replace:

```ts
          Toggle({ type: ToggleType.Switch, isOn: item.enabled })
            .selectedColor(BRAND_GREEN)
```

with:

```ts
          Toggle({ type: ToggleType.Switch, isOn: item.enabled })
            .selectedColor(BRAND_GREEN)
            .onChange((isOn: boolean) => {
              if (this.profileRepository) {
                const nextPreferences = toggleReminderPreference(this.localProfile.reminderPreferences, item.title, isOn);
                this.profileRepository.updateReminderPreferences(nextPreferences).then((profile: HealthProfile) => {
                  this.localProfile = profile;
                });
              }
            })
```

- [ ] **Step 4: Static check**

Run:

```powershell
rg -n "countEnabledReminderPreferences|toggleReminderPreference|ReminderPreference|updateReminderPreferences|this\\.reminders" entry\src\main\ets\components\tabs\ProfileTab.ets
```

Expected: helper imports and repository update appear; `this.reminders` should no longer be used in `ProfileTab`.

## Task 4: Final Verification

**Files:**
- Inspect modified files.

- [ ] **Step 1: Helper static check**

Run:

```powershell
rg -n "countEnabledReminderPreferences|toggleReminderPreference" entry\src\main\ets\viewmodel\ProfileViewModel.ets entry\src\test\LocalUnit.test.ets
```

Expected: helper implementation and tests appear.

- [ ] **Step 2: Scope check**

Run:

```powershell
rg -n "系统通知|通知调度|后台任务|权限申请|云同步|登录" entry\src\main\ets entry\src\test
```

Expected: no claims that system notification scheduling, background tasks, permission prompts, cloud sync, or login were implemented.

- [ ] **Step 3: Mojibake check**

Run:

```powershell
rg -n "閺|婢|鈧|�|\?\{" entry\src\main\ets entry\src\test
```

Expected: no matches.

- [ ] **Step 4: Run tests**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: tests pass. In current Codex shell, record `CommandNotFoundException` if `hvigor` remains unavailable.

- [ ] **Step 5: Run build**

Run:

```powershell
hvigor assembleHap
```

Expected in a configured HarmonyOS shell: build succeeds. In current Codex shell, record `CommandNotFoundException` if `hvigor` remains unavailable.

## Self-Review Notes

- Spec coverage: Tests, helpers, local reminder rendering, persistence, and verification are covered.
- Scope control: No system notification scheduling, permissions, background tasks, login, or cloud sync are introduced.
- Type consistency: `ReminderPreference` is already defined in `ProfileModels.ets`; repository method already exists.
