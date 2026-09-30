# Local Profile And Questionnaire Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first offline-first product loop: complete constitution questionnaire, saved local health profile, and profile-aware assistant/profile screens.

**Architecture:** Add a focused profile domain with pure models, pure questionnaire scoring, a repository boundary, and ArkUI components. Persistence is isolated behind `ProfileRepository` so tests can use an in-memory adapter and the app can later use HarmonyOS Preferences through the same API.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, Hypium unit tests, HarmonyOS Preferences-style key-value persistence via `@kit.ArkData` when runtime context is available.

---

## File Structure

- Create `entry/src/main/ets/model/ProfileModels.ets`: profile, questionnaire, indicator, tongue note, and reminder preference types.
- Create `entry/src/main/ets/services/QuestionnaireService.ets`: question definitions and pure scoring/submission logic.
- Create `entry/src/main/ets/services/ProfileRepository.ets`: default profile creation, JSON serialization, storage adapter interface, memory adapter, HarmonyOS Preferences adapter, and repository methods.
- Create `entry/src/main/ets/viewmodel/ProfileViewModel.ets`: UI-facing profile summary and helper functions.
- Create `entry/src/main/ets/components/questionnaire/QuestionnaireFlow.ets`: ArkUI questionnaire form.
- Create `entry/src/main/ets/components/profile/ProfileSummary.ets`: ArkUI local profile summary.
- Modify `entry/src/main/ets/components/tabs/AssistantTab.ets`: replace score stepper area with questionnaire flow.
- Modify `entry/src/main/ets/components/tabs/ProfileTab.ets`: render local profile summary above existing cards.
- Modify `entry/src/test/LocalUnit.test.ets`: add model/service/repository/view-model unit coverage.

## Task 1: Add Profile Models And Questionnaire Tests

**Files:**
- Create: `entry/src/main/ets/model/ProfileModels.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing imports and tests**

Add these imports to `entry/src/test/LocalUnit.test.ets`:

```ts
import {
  buildQuestionnaireRecord,
  getConstitutionQuestions,
  scoreConstitutionAnswers
} from '../main/ets/services/QuestionnaireService';
```

Add these tests after the constitution utility test:

```ts
    it('provides compact constitution questionnaire questions', 0, () => {
      const questions = getConstitutionQuestions();

      expect(questions.length).assertEqual(6);
      expect(questions[0].title).assertContain('精神');
      expect(questions[0].options.length).assertEqual(4);
    });

    it('scores questionnaire answers into qi deficiency result', 0, () => {
      const result = scoreConstitutionAnswers([
        { questionId: 'energy', score: 3, label: '经常' },
        { questionId: 'breath', score: 3, label: '经常' },
        { questionId: 'sweat', score: 2, label: '有时' },
        { questionId: 'appetite', score: 2, label: '有时' },
        { questionId: 'sleep', score: 1, label: '偶尔' },
        { questionId: 'cold', score: 0, label: '很少' }
      ]);

      expect(result.name).assertEqual('气虚质');
      expect(result.score).assertEqual(11);
      expect(result.suggestion).assertContain('温和运动');
    });

    it('builds questionnaire record with submitted result', 0, () => {
      const record = buildQuestionnaireRecord([
        { questionId: 'energy', score: 0, label: '很少' },
        { questionId: 'breath', score: 0, label: '很少' },
        { questionId: 'sweat', score: 0, label: '很少' },
        { questionId: 'appetite', score: 0, label: '很少' },
        { questionId: 'sleep', score: 0, label: '很少' },
        { questionId: 'cold', score: 0, label: '很少' }
      ], '2026-06-23T10:30:00.000Z');

      expect(record.submittedAt).assertEqual('2026-06-23T10:30:00.000Z');
      expect(record.constitution.name).assertEqual('平和质');
      expect(record.answers.length).assertEqual(6);
    });
```

- [ ] **Step 2: Run test to verify red**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: compile failure because `QuestionnaireService` does not exist yet. In the current Codex shell, expected limitation is `CommandNotFoundException` for `hvigor`; record it.

- [ ] **Step 3: Add profile model file**

Create `entry/src/main/ets/model/ProfileModels.ets`:

```ts
import { ConstitutionResult } from './WellnessModels';

export interface QuestionnaireOption {
  label: string;
  score: number;
}

export interface QuestionnaireQuestion {
  id: string;
  group: string;
  title: string;
  options: QuestionnaireOption[];
}

export interface QuestionnaireAnswer {
  questionId: string;
  score: number;
  label: string;
}

export interface QuestionnaireRecord {
  submittedAt: string;
  answers: QuestionnaireAnswer[];
  totalScore: number;
  constitution: ConstitutionResult;
  suggestion: string;
}

export interface HealthIndicatorEntry {
  name: string;
  value: string;
  unit: string;
  recordedAt: string;
}

export interface TongueObservationNote {
  color: string;
  coating: string;
  dryness: string;
  note: string;
  recordedAt: string;
}

export interface ReminderPreference {
  title: string;
  time: string;
  enabled: boolean;
}

export interface HealthProfile {
  id: string;
  displayName: string;
  constitution: ConstitutionResult;
  questionnaireRecords: QuestionnaireRecord[];
  healthIndicators: HealthIndicatorEntry[];
  tongueNotes: TongueObservationNote[];
  reminderPreferences: ReminderPreference[];
  updatedAt: string;
}
```

- [ ] **Step 4: Add questionnaire service**

Create `entry/src/main/ets/services/QuestionnaireService.ets`:

```ts
import {
  QuestionnaireAnswer,
  QuestionnaireOption,
  QuestionnaireQuestion,
  QuestionnaireRecord
} from '../model/ProfileModels';
import { ConstitutionResult } from '../model/WellnessModels';
import { calculateConstitution } from '../utils/ConstitutionUtil';

const OPTIONS: QuestionnaireOption[] = [
  { label: '很少', score: 0 },
  { label: '偶尔', score: 1 },
  { label: '有时', score: 2 },
  { label: '经常', score: 3 }
];

const QUESTIONS: QuestionnaireQuestion[] = [
  { id: 'energy', group: '精神体力', title: '你是否容易精神不足、疲乏无力？', options: OPTIONS },
  { id: 'breath', group: '精神体力', title: '你是否容易气短、说话声音偏低？', options: OPTIONS },
  { id: 'sweat', group: '日常表现', title: '你是否活动后容易出汗？', options: OPTIONS },
  { id: 'appetite', group: '脾胃状态', title: '你是否胃口一般或饭后容易困倦？', options: OPTIONS },
  { id: 'sleep', group: '睡眠恢复', title: '你是否睡醒后仍觉得恢复不够？', options: OPTIONS },
  { id: 'cold', group: '寒热感受', title: '你是否比别人更怕冷或手脚偏凉？', options: OPTIONS }
];

export function getConstitutionQuestions(): QuestionnaireQuestion[] {
  return QUESTIONS;
}

export function scoreConstitutionAnswers(answers: QuestionnaireAnswer[]): ConstitutionResult {
  const scores: number[] = [];
  for (let index = 0; index < answers.length; index++) {
    scores.push(answers[index].score);
  }
  return calculateConstitution(scores);
}

export function buildQuestionnaireRecord(answers: QuestionnaireAnswer[], submittedAt: string): QuestionnaireRecord {
  const constitution = scoreConstitutionAnswers(answers);
  return {
    submittedAt,
    answers,
    totalScore: constitution.score,
    constitution,
    suggestion: constitution.suggestion
  };
}
```

- [ ] **Step 5: Run test to verify green**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: questionnaire tests pass. In the current Codex shell, record `hvigor` unavailability.

## Task 2: Add Local Profile Repository

**Files:**
- Create: `entry/src/main/ets/services/ProfileRepository.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write repository tests**

Add this import:

```ts
import {
  createDefaultHealthProfile,
  deserializeHealthProfile,
  HealthProfileRepository,
  MemoryProfileStorageAdapter,
  serializeHealthProfile
} from '../main/ets/services/ProfileRepository';
```

Add these tests after the questionnaire tests:

```ts
    it('creates default local health profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');

      expect(profile.id).assertEqual('local-profile');
      expect(profile.constitution.name).assertEqual('平和质');
      expect(profile.questionnaireRecords.length).assertEqual(0);
    });

    it('serializes and deserializes health profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const serialized = serializeHealthProfile(profile);
      const restored = deserializeHealthProfile(serialized);

      expect(restored.updatedAt).assertEqual('2026-06-23T10:30:00.000Z');
      expect(restored.constitution.name).assertEqual('平和质');
    });

    it('falls back to default profile for malformed stored content', 0, () => {
      const restored = deserializeHealthProfile('{bad json');

      expect(restored.id).assertEqual('local-profile');
      expect(restored.constitution.name).assertEqual('平和质');
    });

    it('saves questionnaire record into local profile repository', async () => {
      const storage = new MemoryProfileStorageAdapter();
      const repository = new HealthProfileRepository(storage);
      const record = buildQuestionnaireRecord([
        { questionId: 'energy', score: 3, label: '经常' },
        { questionId: 'breath', score: 3, label: '经常' },
        { questionId: 'sweat', score: 2, label: '有时' },
        { questionId: 'appetite', score: 2, label: '有时' },
        { questionId: 'sleep', score: 1, label: '偶尔' },
        { questionId: 'cold', score: 0, label: '很少' }
      ], '2026-06-23T10:30:00.000Z');

      const profile = await repository.saveQuestionnaireRecord(record);

      expect(profile.questionnaireRecords.length).assertEqual(1);
      expect(profile.constitution.name).assertEqual('气虚质');
    });
```

- [ ] **Step 2: Run test to verify red**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: compile failure because `ProfileRepository` does not exist yet.

- [ ] **Step 3: Add repository implementation**

Create `entry/src/main/ets/services/ProfileRepository.ets`:

```ts
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import {
  HealthProfile,
  QuestionnaireRecord,
  ReminderPreference,
  TongueObservationNote
} from '../model/ProfileModels';
import { ConstitutionResult } from '../model/WellnessModels';

const PROFILE_KEY = 'health_profile';

export interface ProfileStorageAdapter {
  read(key: string): Promise<string>;
  write(key: string, value: string): Promise<void>;
}

function defaultConstitution(): ConstitutionResult {
  return {
    name: '平和质',
    score: 0,
    suggestion: '保持规律作息，饮食有节，继续维持稳定状态。'
  };
}

export function createDefaultHealthProfile(updatedAt: string = new Date().toISOString()): HealthProfile {
  return {
    id: 'local-profile',
    displayName: '本地用户',
    constitution: defaultConstitution(),
    questionnaireRecords: [],
    healthIndicators: [],
    tongueNotes: [],
    reminderPreferences: [
      { title: '饮水提醒', time: '10:00', enabled: true },
      { title: '久坐拉伸', time: '15:30', enabled: true },
      { title: '睡前泡脚', time: '21:40', enabled: false }
    ],
    updatedAt
  };
}

export function serializeHealthProfile(profile: HealthProfile): string {
  return JSON.stringify(profile);
}

function isValidProfile(value: HealthProfile): boolean {
  return value.id.length > 0 && value.constitution.name.length > 0 && value.updatedAt.length > 0;
}

export function deserializeHealthProfile(value: string): HealthProfile {
  try {
    const parsed = JSON.parse(value) as HealthProfile;
    if (isValidProfile(parsed)) {
      return parsed;
    }
  } catch (err) {
    return createDefaultHealthProfile();
  }
  return createDefaultHealthProfile();
}

export class MemoryProfileStorageAdapter implements ProfileStorageAdapter {
  private values: Map<string, string> = new Map<string, string>();

  async read(key: string): Promise<string> {
    return this.values.get(key) || '';
  }

  async write(key: string, value: string): Promise<void> {
    this.values.set(key, value);
  }
}

export class PreferencesProfileStorageAdapter implements ProfileStorageAdapter {
  private context: common.UIAbilityContext;
  private storeName: string;

  constructor(context: common.UIAbilityContext, storeName: string = 'wellness_profile') {
    this.context = context;
    this.storeName = storeName;
  }

  async read(key: string): Promise<string> {
    const store = await preferences.getPreferences(this.context, { name: this.storeName });
    const value = store.getSync(key, '');
    return typeof value === 'string' ? value : '';
  }

  async write(key: string, value: string): Promise<void> {
    const store = await preferences.getPreferences(this.context, { name: this.storeName });
    store.putSync(key, value);
    await store.flush();
  }
}

export class HealthProfileRepository {
  private storage: ProfileStorageAdapter;

  constructor(storage: ProfileStorageAdapter) {
    this.storage = storage;
  }

  async loadProfile(): Promise<HealthProfile> {
    const stored = await this.storage.read(PROFILE_KEY);
    if (stored.length === 0) {
      return createDefaultHealthProfile();
    }
    return deserializeHealthProfile(stored);
  }

  async saveProfile(profile: HealthProfile): Promise<HealthProfile> {
    const nextProfile: HealthProfile = {
      ...profile,
      updatedAt: new Date().toISOString()
    };
    await this.storage.write(PROFILE_KEY, serializeHealthProfile(nextProfile));
    return nextProfile;
  }

  async saveQuestionnaireRecord(record: QuestionnaireRecord): Promise<HealthProfile> {
    const profile = await this.loadProfile();
    const nextProfile: HealthProfile = {
      ...profile,
      constitution: record.constitution,
      questionnaireRecords: [record, ...profile.questionnaireRecords],
      updatedAt: record.submittedAt
    };
    await this.storage.write(PROFILE_KEY, serializeHealthProfile(nextProfile));
    return nextProfile;
  }

  async saveTongueNote(note: TongueObservationNote): Promise<HealthProfile> {
    const profile = await this.loadProfile();
    return this.saveProfile({
      ...profile,
      tongueNotes: [note, ...profile.tongueNotes]
    });
  }

  async updateReminderPreferences(reminderPreferences: ReminderPreference[]): Promise<HealthProfile> {
    const profile = await this.loadProfile();
    return this.saveProfile({
      ...profile,
      reminderPreferences
    });
  }
}

export function createPreferencesHealthProfileRepository(context: common.UIAbilityContext): HealthProfileRepository {
  return new HealthProfileRepository(new PreferencesProfileStorageAdapter(context));
}
```

- [ ] **Step 4: Run repository tests**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: repository tests pass.

## Task 3: Add Profile View Model

**Files:**
- Create: `entry/src/main/ets/viewmodel/ProfileViewModel.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write view model test**

Add this import:

```ts
import { createProfileSummary } from '../main/ets/viewmodel/ProfileViewModel';
```

Add this test after repository tests:

```ts
    it('creates profile summary from local health profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const summary = createProfileSummary(profile);

      expect(summary.constitutionName).assertEqual('平和质');
      expect(summary.recordCount).assertEqual(0);
      expect(summary.completenessText).assertContain('1/4');
    });
```

- [ ] **Step 2: Run test to verify red**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: compile failure because `ProfileViewModel` does not exist yet.

- [ ] **Step 3: Add view model implementation**

Create `entry/src/main/ets/viewmodel/ProfileViewModel.ets`:

```ts
import { HealthProfile } from '../model/ProfileModels';

export interface ProfileSummaryData {
  constitutionName: string;
  constitutionSuggestion: string;
  recordCount: number;
  tongueNoteCount: number;
  reminderEnabledCount: number;
  completenessText: string;
  updatedAt: string;
}

function countCompletedProfileSections(profile: HealthProfile): number {
  let completed = 1;
  if (profile.questionnaireRecords.length > 0) {
    completed += 1;
  }
  if (profile.healthIndicators.length > 0) {
    completed += 1;
  }
  if (profile.tongueNotes.length > 0) {
    completed += 1;
  }
  return completed;
}

function countEnabledReminders(profile: HealthProfile): number {
  let count = 0;
  for (let index = 0; index < profile.reminderPreferences.length; index++) {
    if (profile.reminderPreferences[index].enabled) {
      count += 1;
    }
  }
  return count;
}

export function createProfileSummary(profile: HealthProfile): ProfileSummaryData {
  const completedSections = countCompletedProfileSections(profile);
  return {
    constitutionName: profile.constitution.name,
    constitutionSuggestion: profile.constitution.suggestion,
    recordCount: profile.questionnaireRecords.length,
    tongueNoteCount: profile.tongueNotes.length,
    reminderEnabledCount: countEnabledReminders(profile),
    completenessText: `档案完整度 ${completedSections}/4`,
    updatedAt: profile.updatedAt
  };
}
```

- [ ] **Step 4: Run view model tests**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: view model tests pass.

## Task 4: Add Questionnaire Flow Component And Persist Submissions

**Files:**
- Create: `entry/src/main/ets/components/questionnaire/QuestionnaireFlow.ets`
- Modify: `entry/src/main/ets/components/tabs/AssistantTab.ets`

- [ ] **Step 1: Create questionnaire component**

Create `entry/src/main/ets/components/questionnaire/QuestionnaireFlow.ets`:

```ts
import {
  QuestionnaireAnswer,
  QuestionnaireQuestion,
  QuestionnaireRecord
} from '../../model/ProfileModels';
import {
  buildQuestionnaireRecord,
  getConstitutionQuestions
} from '../../services/QuestionnaireService';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

@Component
export struct QuestionnaireFlow {
  @State selectedScores: number[] = [0, 0, 0, 0, 0, 0];
  @State resultText: string = '';
  @State suggestionText: string = '';

  private questions: QuestionnaireQuestion[] = getConstitutionQuestions();
  onSubmit?: (record: QuestionnaireRecord) => void;

  build() {
    Column({ space: 12 }) {
      Text('体质问卷')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('根据近两周感受选择最接近的一项，结果仅用于日常养生参考。')
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .lineHeight(20)

      ForEach(this.questions, (question: QuestionnaireQuestion, index: number) => {
        this.QuestionBlock(question, index)
      }, (question: QuestionnaireQuestion) => question.id)

      Button('生成体质结果')
        .width('100%')
        .height(42)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor(BRAND_GREEN)
        .borderRadius(CARD_RADIUS)
        .onClick(() => {
          const answers: QuestionnaireAnswer[] = [];
          for (let index = 0; index < this.questions.length; index++) {
            const score = this.selectedScores[index];
            answers.push({
              questionId: this.questions[index].id,
              score,
              label: this.questions[index].options[score].label
            });
          }
          const record = buildQuestionnaireRecord(answers, new Date().toISOString());
          this.resultText = `问卷初筛：${record.constitution.name}`;
          this.suggestionText = record.suggestion;
          if (this.onSubmit) {
            this.onSubmit(record);
          }
        })

      if (this.resultText.length > 0) {
        Text(this.resultText)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(BRAND_GREEN)
        Text(this.suggestionText)
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .lineHeight(20)
        Text('本结果不能替代医生诊断，明显不适请及时就医。')
          .fontSize(12)
          .fontColor(WARM_ACCENT)
          .lineHeight(18)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  QuestionBlock(question: QuestionnaireQuestion, questionIndex: number) {
    Column({ space: 8 }) {
      Text(question.title)
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .lineHeight(20)
      Row({ space: 8 }) {
        ForEach(question.options, (option) => {
          Text(option.label)
            .fontSize(12)
            .fontColor(this.selectedScores[questionIndex] === option.score ? '#FFFFFF' : BRAND_GREEN)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(this.selectedScores[questionIndex] === option.score ? BRAND_GREEN : '#EEF7F1')
            .borderRadius(14)
            .onClick(() => {
              this.selectedScores[questionIndex] = option.score;
            })
        }, (option) => `${question.id}-${option.score}`)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
```

- [ ] **Step 2: Replace assistant score stepper area**

In `entry/src/main/ets/components/tabs/AssistantTab.ets`, add:

```ts
import { common } from '@kit.AbilityKit';
import { QuestionnaireFlow } from '../questionnaire/QuestionnaireFlow';
import { HealthProfileRepository, createPreferencesHealthProfileRepository } from '../../services/ProfileRepository';
```

Add a repository field and load saved constitution when the component appears:

```ts
  private profileRepository?: HealthProfileRepository;

  aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    this.profileRepository = createPreferencesHealthProfileRepository(context);
    this.profileRepository.loadProfile().then((profile) => {
      this.questionnaireScore = profile.constitution.score;
    });
  }
```

Inside `build()`, replace the current questionnaire score `Column({ space: 10 }) { ... }` block with:

```ts
      QuestionnaireFlow({
        onSubmit: (record) => {
          this.questionnaireScore = record.totalScore;
          if (this.profileRepository) {
            this.profileRepository.saveQuestionnaireRecord(record);
          }
        }
      })
```

- [ ] **Step 3: Remove unused assistant actions**

After replacing the stepper, remove the local `ActionChip('舌诊自测')` usage if it is only used by the removed block. Keep `SectionTitle` and the assistant cards.

- [ ] **Step 4: Static check assistant wiring**

Run:

```powershell
rg -n "Button\\('-'\\)|Button\\('\\+'\\)|当前分值|ActionChip\\('舌诊自测'\\)" entry\src\main\ets\components\tabs\AssistantTab.ets
```

Expected: no matches.

## Task 5: Add Profile Summary Component And Load Saved Profile

**Files:**
- Create: `entry/src/main/ets/components/profile/ProfileSummary.ets`
- Modify: `entry/src/main/ets/components/tabs/ProfileTab.ets`

- [ ] **Step 1: Create profile summary component**

Create `entry/src/main/ets/components/profile/ProfileSummary.ets`:

```ts
import { HealthProfile } from '../../model/ProfileModels';
import { createProfileSummary } from '../../viewmodel/ProfileViewModel';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

@Component
export struct ProfileSummary {
  @Prop profile: HealthProfile;

  build() {
    const summary = createProfileSummary(this.profile);

    Column({ space: 10 }) {
      Row() {
        Text('本地健康档案')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
        Text(summary.completenessText)
          .fontSize(12)
          .fontColor(BRAND_GREEN)
      }
      Text(`当前体质：${summary.constitutionName}`)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(DEEP_TEXT)
      Text(summary.constitutionSuggestion)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .lineHeight(20)
      Row({ space: 8 }) {
        this.StatChip(`问卷 ${summary.recordCount}`)
        this.StatChip(`舌象 ${summary.tongueNoteCount}`)
        this.StatChip(`提醒 ${summary.reminderEnabledCount}`)
      }
      Text(`更新于 ${summary.updatedAt}`)
        .fontSize(11)
        .fontColor(WARM_ACCENT)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  StatChip(label: string) {
    Text(label)
      .fontSize(12)
      .fontColor(BRAND_GREEN)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor('#EEF7F1')
      .borderRadius(14)
  }
}
```

- [ ] **Step 2: Add local profile to profile tab**

In `entry/src/main/ets/components/tabs/ProfileTab.ets`, add imports:

```ts
import { common } from '@kit.AbilityKit';
import { HealthProfile } from '../../model/ProfileModels';
import {
  HealthProfileRepository,
  createDefaultHealthProfile,
  createPreferencesHealthProfileRepository
} from '../../services/ProfileRepository';
import { ProfileSummary } from '../profile/ProfileSummary';
```

Add local profile state and repository fields inside `ProfileTab`:

```ts
  @State localProfile: HealthProfile = createDefaultHealthProfile();
  private profileRepository?: HealthProfileRepository;
```

Add lifecycle loading:

```ts
  aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    this.profileRepository = createPreferencesHealthProfileRepository(context);
    this.profileRepository.loadProfile().then((profile: HealthProfile) => {
      this.localProfile = profile;
    });
  }
```

At the top of the root `Column({ space: 14 })`, render:

```ts
      ProfileSummary({ profile: this.localProfile })
```

- [ ] **Step 3: Static check profile wiring**

Run:

```powershell
rg -n "ProfileSummary|createDefaultHealthProfile|localProfile" entry\src\main\ets\components\tabs\ProfileTab.ets entry\src\main\ets\components\profile\ProfileSummary.ets
```

Expected: imports and usages appear in the two files.

## Task 6: Verification And Cleanup

**Files:**
- Inspect all created and modified files.

- [ ] **Step 1: File existence check**

Run:

```powershell
Test-Path entry\src\main\ets\model\ProfileModels.ets
Test-Path entry\src\main\ets\services\QuestionnaireService.ets
Test-Path entry\src\main\ets\services\ProfileRepository.ets
Test-Path entry\src\main\ets\viewmodel\ProfileViewModel.ets
Test-Path entry\src\main\ets\components\questionnaire\QuestionnaireFlow.ets
Test-Path entry\src\main\ets\components\profile\ProfileSummary.ets
```

Expected: all output lines are `True`.

- [ ] **Step 2: Static scope check**

Run:

```powershell
rg -n "拍照识别|相机|Camera|camera|OCR|登录|云同步|真实 AI|AI API" entry\src\main\ets entry\src\test
```

Expected: no matches for camera, login, cloud sync, real AI, or AI API claims. An existing future-facing OCR line such as `支持后续接入 OCR` is acceptable only if it clearly says the capability is future work, not implemented in this phase.

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

Expected in a configured HarmonyOS shell: tests pass. In this Codex shell, record the exact `CommandNotFoundException` if `hvigor` is still unavailable.

- [ ] **Step 5: Run build**

Run:

```powershell
hvigor assembleHap
```

Expected in a configured HarmonyOS shell: build succeeds. In this Codex shell, record the exact `CommandNotFoundException` if `hvigor` is still unavailable.

- [ ] **Step 6: Version-control check**

Run:

```powershell
git status --short
```

Expected if this workspace remains outside a git repository: `fatal: not a git repository`. Do not claim commits were created.

## Self-Review Notes

- Spec coverage: Tasks cover profile models, complete questionnaire, local repository boundary, profile view model, assistant UI integration, profile UI integration, tests, and verification.
- Scope control: The plan does not implement real AI, login, cloud sync, OCR, camera capture, or real device SDKs.
- Type consistency: `HealthProfile`, `QuestionnaireRecord`, `QuestionnaireAnswer`, `ProfileSummaryData`, and repository method names are defined before later tasks reference them.
- Tooling limitation: `hvigor` has not been available in the current shell, so implementation must record exact command failures until DevEco/HarmonyOS tooling is available.
