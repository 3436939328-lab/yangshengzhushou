# Local Data Insights Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the data tab's risk summary and medical report reflect saved local health indicators.

**Architecture:** Add pure profile-to-insight helpers in `ProfileViewModel.ets`, reusing `summarizeHealthRisk()` and `interpretMedicalIndicators()`. `DataTab.ets` already loads `HealthProfile`, so it will compute local insights during render and keep dashboard report fallback for empty profiles.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, local Preferences-backed profile repository, Hypium unit tests.

---

## File Structure

- Modify `entry/src/test/LocalUnit.test.ets`: import and test data insight helpers.
- Modify `entry/src/main/ets/viewmodel/ProfileViewModel.ets`: add local vital parsing plus `buildLocalHealthRisk` and `buildLocalMedicalReport`.
- Modify `entry/src/main/ets/components/tabs/DataTab.ets`: replace fixed risk/report rendering with local helpers.

### Task 1: Local Data Insight Helpers

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`
- Modify: `entry/src/main/ets/viewmodel/ProfileViewModel.ets`

- [ ] **Step 1: Write the failing tests**

Update the `ProfileViewModel` import:

```ts
import {
  buildDisplayMetrics,
  buildLocalHealthRisk,
  buildLocalMedicalReport,
  buildLocalPersonalPlan,
  countEnabledReminderPreferences,
  createProfileSummary,
  inferHomeGoal,
  inferSleepHours,
  toggleReminderPreference
} from '../main/ets/viewmodel/ProfileViewModel';
```

Add these tests after the local home-plan tests:

```ts
    it('builds local health risk from saved blood pressure', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '血压',
        value: '146/94',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const risk = buildLocalHealthRisk(profile);

      expect(risk.level).assertEqual('需关注');
      expect(risk.message).assertContain('血压');
    });

    it('builds local medical report from saved indicators', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '血压',
        value: '146/94',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];
      const fallback = interpretMedicalIndicators(118, 76, 5.4, 7.2);

      const report = buildLocalMedicalReport(profile, fallback);

      expect(report.abnormalItems.length).assertEqual(2);
      expect(report.abnormalItems[0].name).assertEqual('收缩压');
    });

    it('keeps fallback medical report when local indicators are empty', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const fallback = interpretMedicalIndicators(146, 94, 5.6, 6.5);

      const report = buildLocalMedicalReport(profile, fallback);

      expect(report.summary).assertEqual(fallback.summary);
    });
```

- [ ] **Step 2: Verify red state**

Run:

```powershell
hvigor test
rg -n "buildLocalHealthRisk|buildLocalMedicalReport" entry\src\main\ets\viewmodel\ProfileViewModel.ets
```

Expected in this shell: `hvigor` may be unavailable. Static search should have no production helper matches before implementation.

- [ ] **Step 3: Implement helpers**

In `ProfileViewModel.ets`, update model imports:

```ts
import {
  HealthMetric,
  HealthRiskSummary,
  MedicalReportInterpretation,
  PersonalPlan
} from '../model/WellnessModels';
```

Add imports:

```ts
import { interpretMedicalIndicators } from '../services/ReportService';
import { summarizeHealthRisk } from '../utils/HealthRiskUtil';
```

Add helper interface and functions:

```ts
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
```

- [ ] **Step 4: Static verify helpers**

Run:

```powershell
rg -n "buildLocalHealthRisk|buildLocalMedicalReport" entry\src\main\ets\viewmodel\ProfileViewModel.ets entry\src\test\LocalUnit.test.ets
```

Expected: helper exports and tests are present.

### Task 2: Data Tab Wiring

**Files:**
- Modify: `entry/src/main/ets/components/tabs/DataTab.ets`

- [ ] **Step 1: Replace fixed risk/report source**

Remove:

```ts
import { summarizeHealthRisk } from '../../utils/HealthRiskUtil';
```

Replace:

```ts
import { buildDisplayMetrics } from '../../viewmodel/ProfileViewModel';
```

with:

```ts
import {
  buildDisplayMetrics,
  buildLocalHealthRisk,
  buildLocalMedicalReport
} from '../../viewmodel/ProfileViewModel';
```

Inside `build()`, replace:

```ts
    const risk = summarizeHealthRisk(146, 94, 5.6, 6.5);
    const displayMetrics = buildDisplayMetrics(this.localProfile, this.metrics);
```

with:

```ts
    const risk = buildLocalHealthRisk(this.localProfile);
    const displayMetrics = buildDisplayMetrics(this.localProfile, this.metrics);
    const localMedicalReport = buildLocalMedicalReport(this.localProfile, this.medicalReport);
```

Replace:

```ts
      this.MedicalReportCard(this.medicalReport)
```

with:

```ts
      this.MedicalReportCard(localMedicalReport)
```

- [ ] **Step 2: Static verify DataTab wiring**

Run:

```powershell
rg -n "summarizeHealthRisk\\(146, 94|MedicalReportCard\\(this.medicalReport\\)" entry\src\main\ets\components\tabs\DataTab.ets
rg -n "buildLocalHealthRisk|buildLocalMedicalReport|MedicalReportCard\\(localMedicalReport\\)" entry\src\main\ets\components\tabs\DataTab.ets
```

Expected: fixed static calls are absent; local helper calls are present.

### Task 3: Final Verification

**Files:**
- No code edits.

- [ ] **Step 1: Static scope checks**

Run:

```powershell
rg -n "buildLocalHealthRisk|buildLocalMedicalReport" entry\src\main\ets entry\src\test
rg -n "真实 AI|AI API|联网搜索|Web search|云同步|诊断能力" entry\src\main\ets entry\src\test
```

Expected: local helper terms are present; out-of-scope terms are absent.

- [ ] **Step 2: Attempt HarmonyOS verification**

Run:

```powershell
hvigor test
hvigor assembleHap
git status --short
```

Expected in this shell if unchanged: `hvigor` unavailable and workspace is not a git repository.

## Self-Review

- Spec coverage: This plan covers local vital parsing, risk summary, report interpretation, fallback behavior, data-tab wiring, tests, and verification.
- Placeholder scan: No placeholder steps remain.
- Type consistency: `HealthProfile`, `HealthRiskSummary`, `MedicalReportInterpretation`, `DataTab`, and helper names match existing code.
