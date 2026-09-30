# Local Home Personalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the home tab's personal plan derive from saved local profile data.

**Architecture:** Add pure profile-to-home-plan helpers in `ProfileViewModel.ets`, then let `HomeTab.ets` load `HealthProfile` through the same repository pattern used by the assistant, data, and profile tabs. Remove the static `personalPlan` prop from `HomeTab` and `Index.ets`.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, local Preferences-backed profile repository, Hypium unit tests.

---

## File Structure

- Modify `entry/src/test/LocalUnit.test.ets`: import and test local home-plan helpers.
- Modify `entry/src/main/ets/viewmodel/ProfileViewModel.ets`: add `inferHomeGoal`, `inferSleepHours`, and `buildLocalPersonalPlan`.
- Modify `entry/src/main/ets/components/tabs/HomeTab.ets`: load local profile, compute local plan, and render it.
- Modify `entry/src/main/ets/pages/Index.ets`: stop passing `personalPlan` to `HomeTab`.

### Task 1: Profile-to-Home Plan Helpers

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`
- Modify: `entry/src/main/ets/viewmodel/ProfileViewModel.ets`

- [ ] **Step 1: Write the failing tests**

Update the `ProfileViewModel` import in `LocalUnit.test.ets`:

```ts
import {
  buildDisplayMetrics,
  buildLocalPersonalPlan,
  countEnabledReminderPreferences,
  createProfileSummary,
  inferHomeGoal,
  inferSleepHours,
  toggleReminderPreference
} from '../main/ets/viewmodel/ProfileViewModel';
```

Add these tests after the display metric tests:

```ts
    it('builds local home plan from default profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const plan = buildLocalPersonalPlan(profile);

      expect(inferHomeGoal(profile)).assertEqual('节气养护');
      expect(plan.exercise.reason).assertContain('平和质');
    });

    it('infers glucose goal for local home plan', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '空腹血糖',
        value: '7.2',
        unit: 'mmol/L',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const plan = buildLocalPersonalPlan(profile);

      expect(inferHomeGoal(profile)).assertEqual('控糖');
      expect(plan.diet.title).assertEqual('控糖健脾餐');
    });

    it('uses local sleep value for home plan', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '睡眠',
        value: '6.4',
        unit: '小时',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const plan = buildLocalPersonalPlan(profile);

      expect(inferSleepHours(profile)).assertEqual(6.4);
      expect(plan.sleep.title).assertEqual('睡眠修复计划');
    });
```

- [ ] **Step 2: Verify red state**

Run:

```powershell
hvigor test
rg -n "buildLocalPersonalPlan|inferHomeGoal|inferSleepHours" entry\src\main\ets\viewmodel\ProfileViewModel.ets
```

Expected in this shell: `hvigor` may be unavailable. Static search should have no production helper matches before implementation.

- [ ] **Step 3: Implement helpers**

In `ProfileViewModel.ets`, import `PersonalPlan` and `generatePersonalPlan`:

```ts
import { HealthMetric, PersonalPlan } from '../model/WellnessModels';
import { generatePersonalPlan } from '../services/PersonalPlanService';
```

Add:

```ts
function parsedIndicatorNumber(value: string): number {
  const parsed = Number.parseFloat(value);
  if (Number.isNaN(parsed)) {
    return 0;
  }
  return parsed;
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

export function buildLocalPersonalPlan(profile: HealthProfile): PersonalPlan {
  return generatePersonalPlan(profile.constitution.name, inferHomeGoal(profile), inferSleepHours(profile));
}
```

- [ ] **Step 4: Static verify helpers**

Run:

```powershell
rg -n "buildLocalPersonalPlan|inferHomeGoal|inferSleepHours" entry\src\main\ets\viewmodel\ProfileViewModel.ets entry\src\test\LocalUnit.test.ets
```

Expected: helper exports and tests are present.

### Task 2: Home Tab Wiring

**Files:**
- Modify: `entry/src/main/ets/components/tabs/HomeTab.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Load local profile in HomeTab**

Add imports to `HomeTab.ets`:

```ts
import { common } from '@kit.AbilityKit';
import { HealthProfile } from '../../model/ProfileModels';
import {
  HealthProfileRepository,
  createDefaultHealthProfile,
  createPreferencesHealthProfileRepository
} from '../../services/ProfileRepository';
import { buildLocalPersonalPlan } from '../../viewmodel/ProfileViewModel';
```

Remove `PersonalPlan` from the `WellnessModels` import and remove:

```ts
  @Prop personalPlan: PersonalPlan;
```

Add state and repository:

```ts
  @State localProfile: HealthProfile = createDefaultHealthProfile();
  private profileRepository?: HealthProfileRepository;
```

Add:

```ts
  aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    this.profileRepository = createPreferencesHealthProfileRepository(context);
    this.profileRepository.loadProfile().then((profile: HealthProfile) => {
      this.localProfile = profile;
    });
  }
```

Inside `build()`, before `Column`, add:

```ts
    const localPersonalPlan = buildLocalPersonalPlan(this.localProfile);
```

Replace:

```ts
      this.PersonalPlanCard(this.personalPlan)
```

with:

```ts
      this.PersonalPlanCard(localPersonalPlan)
```

- [ ] **Step 2: Remove static prop from Index**

In `Index.ets`, remove:

```ts
              personalPlan: this.dashboard.personalPlan,
```

from the `HomeTab` invocation. Keep `personalPlan` for `DataTab` in this phase because the data tab still uses its sleep segment.

- [ ] **Step 3: Static verify UI wiring**

Run:

```powershell
rg -n "personalPlan:" entry\src\main\ets\pages\Index.ets entry\src\main\ets\components\tabs\HomeTab.ets
rg -n "buildLocalPersonalPlan|localProfile|createPreferencesHealthProfileRepository" entry\src\main\ets\components\tabs\HomeTab.ets
```

Expected: no `personalPlan:` prop remains in the `HomeTab` invocation; `HomeTab` loads and uses local profile.

### Task 3: Final Verification

**Files:**
- No code edits.

- [ ] **Step 1: Static scope checks**

Run:

```powershell
rg -n "buildLocalPersonalPlan|inferHomeGoal|inferSleepHours" entry\src\main\ets entry\src\test
rg -n "真实 AI|AI API|联网搜索|Web search|云同步|诊断能力" entry\src\main\ets entry\src\test
```

Expected: helper terms are present; out-of-scope capability terms are absent.

- [ ] **Step 2: Attempt HarmonyOS verification**

Run:

```powershell
hvigor test
hvigor assembleHap
git status --short
```

Expected in a configured environment: tests and build pass. Expected in this shell if unchanged: `hvigor` unavailable and workspace is not a git repository.

## Self-Review

- Spec coverage: This plan covers helper functions, goal inference, sleep inference, HomeTab local profile loading, static prop removal, tests, and verification.
- Placeholder scan: No placeholder steps remain.
- Type consistency: `HealthProfile`, `PersonalPlan`, `HealthMetric`, `HomeTab`, and repository names match existing code.
