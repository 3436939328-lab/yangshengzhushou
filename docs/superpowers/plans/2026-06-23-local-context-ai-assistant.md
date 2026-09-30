# Local Context AI Assistant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the assistant answer use the saved local health profile without calling a real AI API.

**Architecture:** Add a deterministic `generateContextualHealthAnswer(question, profile)` function to `AIService`, then update `AssistantTab` to store and refresh the loaded `HealthProfile`.

**Tech Stack:** HarmonyOS ArkTS, local service functions, Hypium unit tests, existing `HealthProfileRepository`.

---

## File Structure

- Modify `entry/src/test/LocalUnit.test.ets`: add contextual AI answer tests.
- Modify `entry/src/main/ets/services/AIService.ets`: add local profile-aware answer generator.
- Modify `entry/src/main/ets/components/tabs/AssistantTab.ets`: use local profile for generated answer and refresh after questionnaire save.

## Task 1: Add Contextual AI Tests

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Add import**

Merge into the existing AI import:

```ts
import { generateContextualHealthAnswer, generateHealthAnswer } from '../main/ets/services/AIService';
```

- [ ] **Step 2: Add tests**

Add these tests after the existing safe AI answer test:

```ts
    it('generates contextual answer with constitution from local profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const result = generateContextualHealthAnswer('最近有点困', profile);

      expect(result).assertContain('平和质');
      expect(result).assertContain('不能替代医生诊断');
    });

    it('includes latest tongue note in contextual answer', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.tongueNotes = [{
        color: '淡红',
        coating: '薄白',
        dryness: '适中',
        note: '晨起观察，精神尚可。',
        recordedAt: '2026-06-23T11:00:00.000Z'
      }];

      const result = generateContextualHealthAnswer('今天怎么调理', profile);

      expect(result).assertContain('淡红');
      expect(result).assertContain('薄白');
    });

    it('includes latest health indicator in contextual answer', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const result = generateContextualHealthAnswer('', profile);

      expect(result).assertContain('日常调理');
      expect(result).assertContain('血压 128/82mmHg');
    });
```

- [ ] **Step 3: Run red test**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: compile failure because `generateContextualHealthAnswer` does not exist yet. In current Codex shell, record `CommandNotFoundException` if `hvigor` remains unavailable.

## Task 2: Implement Contextual AI Generator

**Files:**
- Modify: `entry/src/main/ets/services/AIService.ets`

- [ ] **Step 1: Add model import**

Add:

```ts
import { HealthProfile } from '../model/ProfileModels';
```

- [ ] **Step 2: Add helper functions and export**

Add below `generateHealthAnswer()`:

```ts
function latestTongueContext(profile: HealthProfile): string {
  if (profile.tongueNotes.length === 0) {
    return '';
  }
  const note = profile.tongueNotes[0];
  return `最近舌象记录为${note.color}、${note.coating}、${note.dryness}`;
}

function latestIndicatorContext(profile: HealthProfile): string {
  if (profile.healthIndicators.length === 0) {
    return '';
  }
  const indicator = profile.healthIndicators[0];
  return `最近指标为${indicator.name} ${indicator.value}${indicator.unit}`;
}

export function generateContextualHealthAnswer(question: string, profile: HealthProfile): string {
  const normalizedQuestion = question.trim().length > 0 ? question.trim() : '日常调理';
  const contexts: string[] = [`当前体质倾向为${profile.constitution.name}`];
  const tongueContext = latestTongueContext(profile);
  const indicatorContext = latestIndicatorContext(profile);
  if (tongueContext.length > 0) {
    contexts.push(tongueContext);
  }
  if (indicatorContext.length > 0) {
    contexts.push(indicatorContext);
  }

  return `针对“${normalizedQuestion}”，${contexts.join('，')}。建议继续保持规律作息、清淡饮食和温和运动，并结合每日记录观察变化。本建议不能替代医生诊断，若症状持续、加重或伴随明显疼痛，请及时就医。`;
}
```

- [ ] **Step 3: Run green test**

Run:

```powershell
hvigor test
```

Expected in a configured HarmonyOS shell: contextual AI tests pass.

## Task 3: Wire AssistantTab To Local Profile

**Files:**
- Modify: `entry/src/main/ets/components/tabs/AssistantTab.ets`

- [ ] **Step 1: Update imports**

Add:

```ts
import { HealthProfile } from '../../model/ProfileModels';
import { createDefaultHealthProfile } from '../../services/ProfileRepository';
```

Change the AI import:

```ts
import { generateContextualHealthAnswer } from '../../services/AIService';
```

- [ ] **Step 2: Add local profile state**

Inside `AssistantTab`, add:

```ts
  @State localProfile: HealthProfile = createDefaultHealthProfile();
```

- [ ] **Step 3: Update profile load**

Inside `aboutToAppear()`, replace the profile load body with:

```ts
    this.profileRepository.loadProfile().then((profile: HealthProfile) => {
      this.localProfile = profile;
      this.questionnaireScore = profile.constitution.score;
    });
```

- [ ] **Step 4: Use contextual answer**

Replace:

```ts
    const generatedAnswer = generateHealthAnswer('最近困倦、胃口一般', constitution.name);
```

with:

```ts
    const generatedAnswer = generateContextualHealthAnswer('最近困倦、胃口一般', this.localProfile);
```

- [ ] **Step 5: Refresh profile after questionnaire save**

Replace:

```ts
            this.profileRepository.saveQuestionnaireRecord(record);
```

with:

```ts
            this.profileRepository.saveQuestionnaireRecord(record).then((profile: HealthProfile) => {
              this.localProfile = profile;
            });
```

- [ ] **Step 6: Static check**

Run:

```powershell
rg -n "generateContextualHealthAnswer|localProfile|saveQuestionnaireRecord\\(record\\)\\.then|generateHealthAnswer" entry\src\main\ets\components\tabs\AssistantTab.ets
```

Expected: contextual generator and local profile appear; `generateHealthAnswer` no longer appears in `AssistantTab`.

## Task 4: Final Verification

**Files:**
- Inspect modified files.

- [ ] **Step 1: Helper static check**

Run:

```powershell
rg -n "generateContextualHealthAnswer|latestTongueContext|latestIndicatorContext" entry\src\main\ets\services\AIService.ets entry\src\test\LocalUnit.test.ets
```

Expected: implementation and tests appear.

- [ ] **Step 2: Scope check**

Run:

```powershell
rg -n "真实 AI|AI API|联网搜索|Web search|诊断能力|云同步" entry\src\main\ets entry\src\test
```

Expected: no claims that real AI, web search, diagnosis, or cloud sync were implemented.

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

- Spec coverage: Contextual answer, fallback, tongue note, health indicator, disclaimer, and AssistantTab wiring are covered.
- Scope control: No real AI API, streaming chat, web search, diagnosis, or cloud sync are added.
- Type consistency: `HealthProfile` exists in `ProfileModels.ets`; repository and AssistantTab already load saved profiles.
