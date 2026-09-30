# Local Monthly Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate the profile monthly report from saved local health profile records instead of fixed mock values.

**Architecture:** Keep report logic in `ReportService.ets` as a pure deterministic service. `ProfileTab.ets` loads the local `HealthProfile` as it already does, then calls `generateLocalMonthlyReport(localProfile)` during render and feeds the result into the existing report card.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, local Preferences-backed profile repository, Hypium unit tests.

---

## File Structure

- Modify `entry/src/main/ets/services/ReportService.ets`: import `HealthProfile`, add helper functions for dates and attention signal counting, export `generateLocalMonthlyReport(profile)`.
- Modify `entry/src/main/ets/components/tabs/ProfileTab.ets`: remove the `monthlyReport` prop and generate the report from `localProfile`.
- Modify `entry/src/main/ets/pages/Index.ets`: stop passing the static dashboard monthly report into `ProfileTab`.
- Modify `entry/src/test/LocalUnit.test.ets`: add tests for empty local report and attention-signal counting.

### Task 1: Local Report Service

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`
- Modify: `entry/src/main/ets/services/ReportService.ets`

- [ ] **Step 1: Write the failing tests**

Add `generateLocalMonthlyReport` to the report-service import:

```ts
import {
  generateLocalMonthlyReport,
  generateMonthlyReport,
  interpretMedicalIndicators
} from '../main/ets/services/ReportService';
```

Add these tests after the existing monthly report test:

```ts
    it('generates empty local monthly report from saved profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const result = generateLocalMonthlyReport(profile);

      expect(result.title).assertEqual('本地月度养生报告');
      expect(result.summary).assertContain('本月暂无本地记录');
      expect(result.suggestion).assertContain('完成体质问卷');
    });

    it('generates local monthly report from profile records', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [
        { name: '血压', value: '146/94', unit: 'mmHg', recordedAt: '2026-06-20T08:00:00.000Z' },
        { name: '空腹血糖', value: '7.2', unit: 'mmol/L', recordedAt: '2026-06-20T09:00:00.000Z' },
        { name: '睡眠', value: '6.5', unit: '小时', recordedAt: '2026-06-21T08:00:00.000Z' }
      ];
      profile.tongueNotes = [{
        color: '淡红',
        coating: '厚黄',
        dryness: '偏干',
        note: '晨起观察。',
        recordedAt: '2026-06-22T08:00:00.000Z'
      }];

      const result = generateLocalMonthlyReport(profile);

      expect(result.summary).assertContain('3天');
      expect(result.summary).assertContain('4类需要关注');
      expect(result.suggestion).assertContain('平和质');
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```powershell
hvigor test
```

Expected in this workspace if `hvigor` is unavailable:

```text
CommandNotFoundException
```

Use static search as a fallback red check:

```powershell
rg -n "generateLocalMonthlyReport" entry\src\main\ets\services\ReportService.ets
```

Expected before implementation: no matches.

- [ ] **Step 3: Implement minimal report generation**

In `ReportService.ets`, add:

```ts
import { HealthProfile, HealthIndicatorEntry, TongueObservationNote } from '../model/ProfileModels';
```

Then add helpers and export:

```ts
function recordDay(timestamp: string): string {
  if (timestamp.length >= 10) {
    return timestamp.substring(0, 10);
  }
  return timestamp;
}

function numericValue(value: string): number {
  const parsed = Number.parseFloat(value);
  return Number.isNaN(parsed) ? 0 : parsed;
}

function countIndicatorAttentionSignal(entry: HealthIndicatorEntry): number {
  if (entry.name.indexOf('血压') >= 0 && entry.value.indexOf('/') >= 0) {
    const parts = entry.value.split('/');
    const systolic = numericValue(parts[0]);
    const diastolic = numericValue(parts[1]);
    return systolic >= 140 || diastolic >= 90 ? 1 : 0;
  }
  if (entry.name.indexOf('血糖') >= 0) {
    return numericValue(entry.value) >= 7.0 ? 1 : 0;
  }
  if (entry.name.indexOf('睡眠') >= 0) {
    return numericValue(entry.value) > 0 && numericValue(entry.value) < 7 ? 1 : 0;
  }
  return 0;
}

function countTongueAttentionSignal(note: TongueObservationNote): number {
  const coatingNeedsAttention = note.coating.indexOf('厚') >= 0 || note.coating.indexOf('黄') >= 0;
  const drynessNeedsAttention = note.dryness.indexOf('干') >= 0;
  return coatingNeedsAttention || drynessNeedsAttention ? 1 : 0;
}

export function generateLocalMonthlyReport(profile: HealthProfile): MonthlyReport {
  const days: string[] = [];
  let attentionSignals = 0;

  for (let index = 0; index < profile.questionnaireRecords.length; index++) {
    days.push(recordDay(profile.questionnaireRecords[index].submittedAt));
  }
  for (let index = 0; index < profile.healthIndicators.length; index++) {
    const entry = profile.healthIndicators[index];
    days.push(recordDay(entry.recordedAt));
    attentionSignals += countIndicatorAttentionSignal(entry);
  }
  for (let index = 0; index < profile.tongueNotes.length; index++) {
    const note = profile.tongueNotes[index];
    days.push(recordDay(note.recordedAt));
    attentionSignals += countTongueAttentionSignal(note);
  }

  const uniqueDays = Array.from(new Set(days));
  if (uniqueDays.length === 0) {
    return {
      title: '本地月度养生报告',
      summary: '本月暂无本地记录，报告将在你保存问卷、舌象或指标后自动更新。',
      suggestion: '建议先完成体质问卷，并记录一次舌象或常用健康指标，形成可复盘的基础档案。'
    };
  }

  return {
    title: '本地月度养生报告',
    summary: `本月已记录${uniqueDays.length}天，发现${attentionSignals}类需要关注的健康信号。`,
    suggestion: `结合${profile.constitution.name}倾向，建议保持规律作息，并优先复盘最近的舌象和指标变化。`
  };
}
```

- [ ] **Step 4: Run tests and static checks**

Run:

```powershell
hvigor test
rg -n "generateLocalMonthlyReport" entry\src\main\ets\services\ReportService.ets entry\src\test\LocalUnit.test.ets
```

Expected: `hvigor test` passes in a configured environment, or reports unavailable in this shell. Static search finds the service export and tests.

### Task 2: Profile Tab Wiring

**Files:**
- Modify: `entry/src/main/ets/components/tabs/ProfileTab.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Remove static monthly report prop from UI wiring**

In `ProfileTab.ets`, remove `MonthlyReport` from the model import and remove:

```ts
  @Prop monthlyReport: MonthlyReport;
```

Import:

```ts
import { generateLocalMonthlyReport } from '../../services/ReportService';
```

Inside `build()`, add:

```ts
    const localMonthlyReport = generateLocalMonthlyReport(this.localProfile);
```

Replace:

```ts
      this.MonthlyReportCard(this.monthlyReport)
```

with:

```ts
      this.MonthlyReportCard(localMonthlyReport)
```

- [ ] **Step 2: Stop passing dashboard monthly report**

In `Index.ets`, replace:

```ts
              monthlyReport: this.dashboard.monthlyReport,
```

with no property. The `ProfileTab` invocation should keep `questionnaireScore`, `metricCount`, `archiveSummaries`, and `profileActions`.

- [ ] **Step 3: Static verify the wiring**

Run:

```powershell
rg -n "monthlyReport:" entry\src\main\ets\pages\Index.ets entry\src\main\ets\components\tabs\ProfileTab.ets
rg -n "generateLocalMonthlyReport" entry\src\main\ets\components\tabs\ProfileTab.ets
```

Expected: no `monthlyReport:` prop remains in `Index.ets` or `ProfileTab.ets`; `ProfileTab.ets` imports and calls `generateLocalMonthlyReport`.

### Task 3: Final Verification

**Files:**
- No code edits.

- [ ] **Step 1: Run focused static checks**

Run:

```powershell
rg -n "generateLocalMonthlyReport|本地月度养生报告|4类需要关注" entry\src\main\ets entry\src\test
rg -n "真实 AI|AI API|联网搜索|Web search|云同步|PDF export" entry\src\main\ets entry\src\test
```

Expected: local report terms are present. Out-of-scope terms are absent from app and test code.

- [ ] **Step 2: Attempt HarmonyOS verification**

Run:

```powershell
hvigor test
hvigor assembleHap
```

Expected in a configured HarmonyOS/DevEco shell: both pass. Expected in the current unconfigured shell: `hvigor` is not recognized; report that limitation.

## Self-Review

- Spec coverage: This plan covers local report generation, active-day counting, attention-signal rules, profile-tab wiring, compatibility with existing mock report generation, tests, and verification.
- Placeholder scan: No placeholder implementation steps remain.
- Type consistency: `HealthProfile`, `HealthIndicatorEntry`, `TongueObservationNote`, and `MonthlyReport` match existing model names.
