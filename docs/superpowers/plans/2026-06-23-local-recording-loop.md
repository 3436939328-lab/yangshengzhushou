# Local Recording Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add local tongue observation and manual health indicator recording, then make profile and data screens prefer saved local records over mock data.

**Architecture:** Reuse the existing `HealthProfile` model and `HealthProfileRepository`. Add small view-model helpers for local metric conversion and fallback, then add two focused ArkUI form components under `components/profile`.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, Hypium unit tests, existing HarmonyOS Preferences repository boundary.

---

## File Structure

- Modify `entry/src/test/LocalUnit.test.ets`: add repository and view-model tests for local records.
- Modify `entry/src/main/ets/viewmodel/ProfileViewModel.ets`: add local indicator conversion and fallback helpers.
- Create `entry/src/main/ets/components/profile/TongueNoteForm.ets`: text-only tongue observation form.
- Create `entry/src/main/ets/components/profile/HealthIndicatorForm.ets`: manual health indicator form.
- Modify `entry/src/main/ets/components/tabs/ProfileTab.ets`: wire forms into local profile repository and refresh summary.
- Modify `entry/src/main/ets/components/tabs/DataTab.ets`: accept optional local profile and render saved indicators first.
- Modify `entry/src/main/ets/pages/Index.ets`: pass profile data into `DataTab` if needed by the final component contract.

## Task 1: Add Repository Tests For Local Records

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing repository tests**

Add these tests after the existing profile repository tests:

```ts
    it('saves tongue observation note into local profile repository', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const repository = new HealthProfileRepository(storage);

      const profile = await repository.saveTongueNote({
        color: '淡红',
        coating: '薄白',
        dryness: '适中',
        note: '晨起观察，精神尚可。',
        recordedAt: '2026-06-23T11:00:00.000Z'
      });

      expect(profile.tongueNotes.length).assertEqual(1);
      expect(profile.tongueNotes[0].color).assertEqual('淡红');
    });

    it('saves health indicator into local profile repository', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const repository = new HealthProfileRepository(storage);

      const profile = await repository.saveHealthIndicator({
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      });

      expect(profile.healthIndicators.length).assertEqual(1);
      expect(profile.healthIndicators[0].name).assertEqual('血压');
    });
```

- [ ] **Step 2: Run test to verify behavior**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: tests pass because repository methods already exist. In the current Codex shell, record `CommandNotFoundException` if `hvigor` remains unavailable.

## Task 2: Add ViewModel Helpers For Local Metrics

**Files:**
- Modify: `entry/src/main/ets/viewmodel/ProfileViewModel.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing view-model tests**

Add import:

```ts
import { buildDisplayMetrics } from '../main/ets/viewmodel/ProfileViewModel';
```

If `createProfileSummary` is already imported from the same file, merge the import:

```ts
import { buildDisplayMetrics, createProfileSummary } from '../main/ets/viewmodel/ProfileViewModel';
```

Add tests after the existing profile summary test:

```ts
    it('uses local health indicators before mock metrics', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const metrics = buildDisplayMetrics(profile, []);

      expect(metrics.length).assertEqual(1);
      expect(metrics[0].value).assertEqual('128/82');
    });

    it('falls back to mock metrics when local indicators are empty', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const metrics = buildDisplayMetrics(profile, [
        { name: '睡眠', value: '7.1', unit: '小时', status: '可改善', trend: [35, 48] }
      ]);

      expect(metrics.length).assertEqual(1);
      expect(metrics[0].name).assertEqual('睡眠');
    });
```

- [ ] **Step 2: Run test to verify red**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: compile failure because `buildDisplayMetrics` does not exist yet.

- [ ] **Step 3: Implement view-model helper**

In `entry/src/main/ets/viewmodel/ProfileViewModel.ets`, add imports:

```ts
import { HealthMetric } from '../model/WellnessModels';
```

Add this function:

```ts
export function buildDisplayMetrics(profile: HealthProfile, fallbackMetrics: HealthMetric[]): HealthMetric[] {
  if (profile.healthIndicators.length === 0) {
    return fallbackMetrics;
  }

  const metrics: HealthMetric[] = [];
  for (let index = 0; index < profile.healthIndicators.length; index++) {
    const indicator = profile.healthIndicators[index];
    metrics.push({
      name: indicator.name,
      value: indicator.value,
      unit: indicator.unit,
      status: '本地记录',
      trend: [42, 48, 52, 50, 56]
    });
  }
  return metrics;
}
```

- [ ] **Step 4: Run test to verify green**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: local metric tests pass.

## Task 3: Add Tongue Note Form

**Files:**
- Create: `entry/src/main/ets/components/profile/TongueNoteForm.ets`

- [ ] **Step 1: Create form component**

Create `entry/src/main/ets/components/profile/TongueNoteForm.ets`:

```ts
import { TongueObservationNote } from '../../model/ProfileModels';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

@Component
export struct TongueNoteForm {
  @State color: string = '淡红';
  @State coating: string = '薄白';
  @State dryness: string = '适中';
  @State note: string = '';
  @State errorText: string = '';

  onSave?: (note: TongueObservationNote) => void;

  build() {
    Column({ space: 10 }) {
      Text('舌象文字记录')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('仅记录观察文字，不涉及拍照或识别。')
        .fontSize(12)
        .fontColor(MUTED_TEXT)

      this.ChoiceRow('舌色', ['淡红', '偏红', '偏淡'], this.color, (value: string) => {
        this.color = value;
      })
      this.ChoiceRow('舌苔', ['薄白', '厚腻', '少苔'], this.coating, (value: string) => {
        this.coating = value;
      })
      this.ChoiceRow('干湿', ['适中', '偏干', '偏湿'], this.dryness, (value: string) => {
        this.dryness = value;
      })

      TextInput({ placeholder: '补充备注', text: this.note })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => {
          this.note = value;
          this.errorText = '';
        })

      if (this.errorText.length > 0) {
        Text(this.errorText)
          .fontSize(12)
          .fontColor(WARM_ACCENT)
      }

      Button('保存舌象记录')
        .width('100%')
        .height(40)
        .fontColor('#FFFFFF')
        .backgroundColor(BRAND_GREEN)
        .borderRadius(CARD_RADIUS)
        .onClick(() => {
          if (this.note.trim().length === 0) {
            this.errorText = '请填写一条简短备注';
            return;
          }
          if (this.onSave) {
            this.onSave({
              color: this.color,
              coating: this.coating,
              dryness: this.dryness,
              note: this.note.trim(),
              recordedAt: new Date().toISOString()
            });
          }
          this.note = '';
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  ChoiceRow(label: string, options: string[], selected: string, onSelect: (value: string) => void) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
      Row({ space: 8 }) {
        ForEach(options, (option: string) => {
          Text(option)
            .fontSize(12)
            .fontColor(selected === option ? '#FFFFFF' : BRAND_GREEN)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(selected === option ? BRAND_GREEN : '#EEF7F1')
            .borderRadius(14)
            .onClick(() => {
              onSelect(option);
            })
        }, (option: string) => `${label}-${option}`)
      }
    }
    .alignItems(HorizontalAlign.Start)
  }
}
```

- [ ] **Step 2: Static check component**

Run:

```powershell
rg -n "TongueNoteForm|保存舌象记录|拍照|识别" entry\src\main\ets\components\profile\TongueNoteForm.ets
```

Expected: form definitions appear; no claim that image recognition is implemented.

## Task 4: Add Health Indicator Form

**Files:**
- Create: `entry/src/main/ets/components/profile/HealthIndicatorForm.ets`

- [ ] **Step 1: Create form component**

Create `entry/src/main/ets/components/profile/HealthIndicatorForm.ets`:

```ts
import { HealthIndicatorEntry } from '../../model/ProfileModels';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

@Component
export struct HealthIndicatorForm {
  @State name: string = '血压';
  @State value: string = '';
  @State unit: string = 'mmHg';
  @State errorText: string = '';

  onSave?: (entry: HealthIndicatorEntry) => void;

  build() {
    Column({ space: 10 }) {
      Text('健康指标手动录入')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('先支持手动记录，后续可替换为设备同步。')
        .fontSize(12)
        .fontColor(MUTED_TEXT)

      Row({ space: 8 }) {
        this.TypeChip('血压', 'mmHg')
        this.TypeChip('血糖', 'mmol/L')
        this.TypeChip('睡眠', '小时')
        this.TypeChip('步数', '步')
      }

      TextInput({ placeholder: `请输入${this.name}数值`, text: this.value })
        .height(42)
        .fontSize(14)
        .onChange((input: string) => {
          this.value = input;
          this.errorText = '';
        })

      if (this.errorText.length > 0) {
        Text(this.errorText)
          .fontSize(12)
          .fontColor(WARM_ACCENT)
      }

      Button('保存健康指标')
        .width('100%')
        .height(40)
        .fontColor('#FFFFFF')
        .backgroundColor(BRAND_GREEN)
        .borderRadius(CARD_RADIUS)
        .onClick(() => {
          if (this.value.trim().length === 0) {
            this.errorText = '请填写指标数值';
            return;
          }
          if (this.onSave) {
            this.onSave({
              name: this.name,
              value: this.value.trim(),
              unit: this.unit,
              recordedAt: new Date().toISOString()
            });
          }
          this.value = '';
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  TypeChip(nextName: string, nextUnit: string) {
    Text(nextName)
      .fontSize(12)
      .fontColor(this.name === nextName ? '#FFFFFF' : BRAND_GREEN)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor(this.name === nextName ? BRAND_GREEN : '#EEF7F1')
      .borderRadius(14)
      .onClick(() => {
        this.name = nextName;
        this.unit = nextUnit;
      })
  }
}
```

- [ ] **Step 2: Static check component**

Run:

```powershell
rg -n "HealthIndicatorForm|保存健康指标|设备同步" entry\src\main\ets\components\profile\HealthIndicatorForm.ets
```

Expected: manual form appears; any device wording must describe future replacement, not current SDK integration.

## Task 5: Wire Forms Into Profile Tab

**Files:**
- Modify: `entry/src/main/ets/components/tabs/ProfileTab.ets`

- [ ] **Step 1: Add imports**

Add:

```ts
import { HealthIndicatorForm } from '../profile/HealthIndicatorForm';
import { TongueNoteForm } from '../profile/TongueNoteForm';
```

- [ ] **Step 2: Render forms below `ProfileSummary`**

After:

```ts
      ProfileSummary({ profile: this.localProfile })
```

Add:

```ts
      TongueNoteForm({
        onSave: (note) => {
          if (this.profileRepository) {
            this.profileRepository.saveTongueNote(note).then((profile: HealthProfile) => {
              this.localProfile = profile;
            });
          }
        }
      })

      HealthIndicatorForm({
        onSave: (entry) => {
          if (this.profileRepository) {
            this.profileRepository.saveHealthIndicator(entry).then((profile: HealthProfile) => {
              this.localProfile = profile;
            });
          }
        }
      })
```

- [ ] **Step 3: Static check profile wiring**

Run:

```powershell
rg -n "TongueNoteForm|HealthIndicatorForm|saveTongueNote|saveHealthIndicator" entry\src\main\ets\components\tabs\ProfileTab.ets
```

Expected: imports, component usage, and repository calls all appear.

## Task 6: Wire Local Metrics Into Data Tab

**Files:**
- Modify: `entry/src/main/ets/components/tabs/DataTab.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Add local profile prop to `DataTab`**

In `DataTab.ets`, add imports:

```ts
import { HealthProfile } from '../../model/ProfileModels';
import { createDefaultHealthProfile } from '../../services/ProfileRepository';
import { buildDisplayMetrics } from '../../viewmodel/ProfileViewModel';
```

Add property:

```ts
  @Prop localProfile: HealthProfile = createDefaultHealthProfile();
```

In `build()`, add:

```ts
    const displayMetrics = buildDisplayMetrics(this.localProfile, this.metrics);
```

Replace:

```ts
      ForEach(this.metrics, (metric: HealthMetric) => {
```

with:

```ts
      ForEach(displayMetrics, (metric: HealthMetric) => {
```

- [ ] **Step 2: Pass default profile from `Index.ets`**

In `Index.ets`, import:

```ts
import { createDefaultHealthProfile } from '../services/ProfileRepository';
import { HealthProfile } from '../model/ProfileModels';
```

Add field:

```ts
  private localProfile: HealthProfile = createDefaultHealthProfile();
```

Pass it into `DataTab`:

```ts
              localProfile: this.localProfile,
```

- [ ] **Step 3: Static check data wiring**

Run:

```powershell
rg -n "buildDisplayMetrics|localProfile|createDefaultHealthProfile" entry\src\main\ets\components\tabs\DataTab.ets entry\src\main\ets\pages\Index.ets
```

Expected: helper import, prop, and `DataTab` prop pass appear.

## Task 7: Final Verification

**Files:**
- Inspect all created and modified files.

- [ ] **Step 1: File existence check**

Run:

```powershell
Test-Path entry\src\main\ets\components\profile\TongueNoteForm.ets
Test-Path entry\src\main\ets\components\profile\HealthIndicatorForm.ets
```

Expected: both output lines are `True`.

- [ ] **Step 2: Static scope check**

Run:

```powershell
rg -n "拍照识别|相机|Camera|camera|OCR|真实设备|设备 SDK|云同步|登录|真实 AI|AI API" entry\src\main\ets entry\src\test
```

Expected: no claim that this phase implemented camera, OCR, real device SDK, cloud sync, login, or real AI. Future-facing text is acceptable only when it clearly says later replacement.

- [ ] **Step 3: Mojibake and interpolation check**

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

Expected in a configured HarmonyOS shell: tests pass. In the current Codex shell, record `CommandNotFoundException` if `hvigor` remains unavailable.

- [ ] **Step 5: Run build**

Run:

```powershell
hvigor assembleHap
```

Expected in a configured HarmonyOS shell: build succeeds. In the current Codex shell, record `CommandNotFoundException` if `hvigor` remains unavailable.

## Self-Review Notes

- Spec coverage: The plan covers tongue note recording, manual health indicators, local repository usage, profile summary refresh, data tab fallback, tests, and verification.
- Scope control: The plan does not add camera capture, OCR, real device SDKs, cloud sync, login, or real AI.
- Type consistency: `HealthIndicatorEntry`, `TongueObservationNote`, `HealthProfile`, and `HealthMetric` are defined before use.
