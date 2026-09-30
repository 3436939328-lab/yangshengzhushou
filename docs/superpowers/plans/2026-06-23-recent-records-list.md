# Recent Records List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show recent locally saved tongue and indicator records in the profile tab.

**Architecture:** Add pure formatting helpers in `ProfileViewModel.ets`, create a small `RecentRecordsList.ets` component, and render it from `ProfileTab.ets` below the record forms.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, local `HealthProfile`, Hypium unit tests.

---

## File Structure

- Modify `entry/src/test/LocalUnit.test.ets`: import and test recent record formatting helpers.
- Modify `entry/src/main/ets/viewmodel/ProfileViewModel.ets`: add `RecentRecordItem`, `buildRecentIndicatorRecords`, and `buildRecentTongueRecords`.
- Create `entry/src/main/ets/components/profile/RecentRecordsList.ets`: UI component for empty state and recent rows.
- Modify `entry/src/main/ets/components/tabs/ProfileTab.ets`: render the new component.

### Task 1: Recent Record Formatting

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
  buildRecentIndicatorRecords,
  buildRecentTongueRecords,
  countEnabledReminderPreferences,
  createProfileSummary,
  inferHomeGoal,
  inferSleepHours,
  toggleReminderPreference
} from '../main/ets/viewmodel/ProfileViewModel';
```

Add these tests after the profile summary test:

```ts
    it('formats recent indicator records with limit', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [
        { name: '血压', value: '128/82', unit: 'mmHg', recordedAt: '2026-06-23T11:05:00.000Z' },
        { name: '睡眠', value: '6.8', unit: '小时', recordedAt: '2026-06-22T22:00:00.000Z' }
      ];

      const records = buildRecentIndicatorRecords(profile, 1);

      expect(records.length).assertEqual(1);
      expect(records[0].title).assertEqual('血压');
      expect(records[0].detail).assertEqual('128/82 mmHg');
      expect(records[0].tag).assertEqual('指标');
    });

    it('formats recent tongue records with note text', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.tongueNotes = [{
        color: '淡红',
        coating: '薄白',
        dryness: '适中',
        note: '晨起观察。',
        recordedAt: '2026-06-23T08:00:00.000Z'
      }];

      const records = buildRecentTongueRecords(profile, 3);

      expect(records.length).assertEqual(1);
      expect(records[0].title).assertEqual('舌象观察');
      expect(records[0].detail).assertContain('淡红');
      expect(records[0].detail).assertContain('晨起观察。');
      expect(records[0].tag).assertEqual('舌象');
    });

    it('returns no recent records for non-positive limit', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const records = buildRecentIndicatorRecords(profile, 0);

      expect(records.length).assertEqual(0);
    });
```

- [ ] **Step 2: Verify red state**

Run:

```powershell
hvigor test
rg -n "buildRecentIndicatorRecords|buildRecentTongueRecords" entry\src\main\ets\viewmodel\ProfileViewModel.ets
```

Expected in this shell: `hvigor` may be unavailable. Static search should have no production helper matches before implementation.

- [ ] **Step 3: Implement formatting helpers**

Add to `ProfileViewModel.ets`:

```ts
export interface RecentRecordItem {
  title: string;
  detail: string;
  tag: string;
  recordedAt: string;
}

export function buildRecentIndicatorRecords(profile: HealthProfile, limit: number): RecentRecordItem[] {
  if (limit <= 0) {
    return [];
  }
  const records: RecentRecordItem[] = [];
  const count = Math.min(profile.healthIndicators.length, limit);
  for (let index = 0; index < count; index++) {
    const item = profile.healthIndicators[index];
    records.push({
      title: item.name,
      detail: `${item.value} ${item.unit}`,
      tag: '指标',
      recordedAt: item.recordedAt
    });
  }
  return records;
}

export function buildRecentTongueRecords(profile: HealthProfile, limit: number): RecentRecordItem[] {
  if (limit <= 0) {
    return [];
  }
  const records: RecentRecordItem[] = [];
  const count = Math.min(profile.tongueNotes.length, limit);
  for (let index = 0; index < count; index++) {
    const item = profile.tongueNotes[index];
    const noteText = item.note.length > 0 ? `，${item.note}` : '';
    records.push({
      title: '舌象观察',
      detail: `${item.color}，${item.coating}，${item.dryness}${noteText}`,
      tag: '舌象',
      recordedAt: item.recordedAt
    });
  }
  return records;
}
```

- [ ] **Step 4: Static verify helpers**

Run:

```powershell
rg -n "RecentRecordItem|buildRecentIndicatorRecords|buildRecentTongueRecords" entry\src\main\ets\viewmodel\ProfileViewModel.ets entry\src\test\LocalUnit.test.ets
```

Expected: helper exports and tests are present.

### Task 2: Recent Records Component

**Files:**
- Create: `entry/src/main/ets/components/profile/RecentRecordsList.ets`
- Modify: `entry/src/main/ets/components/tabs/ProfileTab.ets`

- [ ] **Step 1: Create component**

Create `RecentRecordsList.ets` with:

```ts
import { HealthProfile } from '../../model/ProfileModels';
import {
  RecentRecordItem,
  buildRecentIndicatorRecords,
  buildRecentTongueRecords
} from '../../viewmodel/ProfileViewModel';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

@Component
export struct RecentRecordsList {
  @Prop profile: HealthProfile;

  build() {
    const indicatorRecords = buildRecentIndicatorRecords(this.profile, 3);
    const tongueRecords = buildRecentTongueRecords(this.profile, 3);

    Column({ space: 12 }) {
      Row() {
        Text('最近记录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
        Text(`${indicatorRecords.length + tongueRecords.length}条`)
          .fontSize(12)
          .fontColor(BRAND_GREEN)
      }

      if (indicatorRecords.length === 0 && tongueRecords.length === 0) {
        Text('暂无本地记录，保存舌象或健康指标后会显示在这里。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .lineHeight(20)
      } else {
        if (indicatorRecords.length > 0) {
          this.RecordSection('健康指标', indicatorRecords)
        }
        if (tongueRecords.length > 0) {
          this.RecordSection('舌象记录', tongueRecords)
        }
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  RecordSection(title: string, records: RecentRecordItem[]) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(13)
        .fontColor(WARM_ACCENT)
      ForEach(records, (item: RecentRecordItem) => {
        this.RecordRow(item)
      }, (item: RecentRecordItem) => `${item.tag}-${item.title}-${item.recordedAt}`)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  RecordRow(item: RecentRecordItem) {
    Row() {
      Column() {
        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(DEEP_TEXT)
        Text(item.detail)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .lineHeight(18)
          .margin({ top: 4 })
        Text(item.recordedAt)
          .fontSize(11)
          .fontColor(WARM_ACCENT)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(item.tag)
        .fontSize(11)
        .fontColor(BRAND_GREEN)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#EEF7F1')
        .borderRadius(10)
    }
    .width('100%')
  }
}
```

- [ ] **Step 2: Render from ProfileTab**

In `ProfileTab.ets`, import:

```ts
import { RecentRecordsList } from '../profile/RecentRecordsList';
```

Render after `HealthIndicatorForm`:

```ts
      RecentRecordsList({ profile: this.localProfile })
```

- [ ] **Step 3: Static verify component wiring**

Run:

```powershell
rg -n "RecentRecordsList" entry\src\main\ets\components\profile\RecentRecordsList.ets entry\src\main\ets\components\tabs\ProfileTab.ets
```

Expected: component file exports `RecentRecordsList`, and `ProfileTab` imports and renders it.

### Task 3: Final Verification

**Files:**
- No code edits.

- [ ] **Step 1: Static scope checks**

Run:

```powershell
rg -n "RecentRecordsList|buildRecentIndicatorRecords|buildRecentTongueRecords" entry\src\main\ets entry\src\test
rg -n "delete|remove|编辑|删除" entry\src\main\ets\components\profile\RecentRecordsList.ets entry\src\main\ets\viewmodel\ProfileViewModel.ets
```

Expected: recent record terms are present; delete/edit actions are absent for this phase.

- [ ] **Step 2: Attempt HarmonyOS verification**

Run:

```powershell
hvigor test
hvigor assembleHap
git status --short
```

Expected in this shell if unchanged: `hvigor` unavailable and workspace is not a git repository.

## Self-Review

- Spec coverage: This plan covers recent indicator rows, recent tongue rows, empty state, profile tab rendering, tests, and verification.
- Placeholder scan: No placeholder steps remain.
- Type consistency: `HealthProfile`, `RecentRecordItem`, `ProfileTab`, and component paths match existing code.
