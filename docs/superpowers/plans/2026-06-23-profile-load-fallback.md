# Profile Load Fallback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a consistent notice when local profile loading fails, while continuing with default profile data.

**Architecture:** Reuse `EmptyStateService` for copy, add a small `LoadStateNotice` component, and wire `.catch(...)` handling into the four tabs that load `HealthProfile`.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, local Preferences-backed profile repository, Hypium unit tests.

---

## File Structure

- Modify `entry/src/main/ets/services/EmptyStateService.ets`: add `profileLoad` copy.
- Modify `entry/src/test/LocalUnit.test.ets`: add copy test.
- Create `entry/src/main/ets/components/cards/LoadStateNotice.ets`: notice component.
- Modify `entry/src/main/ets/components/tabs/HomeTab.ets`: load fallback state and notice.
- Modify `entry/src/main/ets/components/tabs/AssistantTab.ets`: load fallback state and notice.
- Modify `entry/src/main/ets/components/tabs/DataTab.ets`: load fallback state and notice.
- Modify `entry/src/main/ets/components/tabs/ProfileTab.ets`: load fallback state and notice.

### Task 1: Profile Load Empty-State Copy

**Files:**
- Modify: `entry/src/main/ets/services/EmptyStateService.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing test**

Add near empty-state tests:

```ts
    it('returns profile load fallback copy', 0, () => {
      const info = getEmptyStateInfo('profileLoad');

      expect(info.title).assertEqual('本地档案暂不可用');
      expect(info.detail).assertContain('默认档案');
    });
```

- [ ] **Step 2: Verify red state**

Run:

```powershell
hvigor test
rg -n "profileLoad|本地档案暂不可用" entry\src\main\ets\services\EmptyStateService.ets
```

Expected in this shell: `hvigor` may be unavailable. Static search should have no `profileLoad` service match before implementation.

- [ ] **Step 3: Add copy**

In `EmptyStateService.ets`, before the fallback return, add:

```ts
  if (key === 'profileLoad') {
    return {
      title: '本地档案暂不可用',
      detail: '已使用默认档案继续展示，稍后重新进入页面可再次尝试读取本地记录。'
    };
  }
```

### Task 2: Load State Notice Component

**Files:**
- Create: `entry/src/main/ets/components/cards/LoadStateNotice.ets`

- [ ] **Step 1: Create component**

Create:

```ts
import { getEmptyStateInfo } from '../../services/EmptyStateService';
import {
  CARD_BG,
  CARD_RADIUS,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

@Component
export struct LoadStateNotice {
  @Prop message: string;

  build() {
    if (this.message.length > 0) {
      Column({ space: 6 }) {
        Text(getEmptyStateInfo('profileLoad').title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(WARM_ACCENT)
        Text(this.message)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .lineHeight(18)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(14)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
  }
}
```

### Task 3: Tab Wiring

**Files:**
- Modify: `entry/src/main/ets/components/tabs/HomeTab.ets`
- Modify: `entry/src/main/ets/components/tabs/AssistantTab.ets`
- Modify: `entry/src/main/ets/components/tabs/DataTab.ets`
- Modify: `entry/src/main/ets/components/tabs/ProfileTab.ets`

- [ ] **Step 1: Add imports to each tab**

Add:

```ts
import { getEmptyStateInfo } from '../../services/EmptyStateService';
import { LoadStateNotice } from '../cards/LoadStateNotice';
```

- [ ] **Step 2: Add state to each tab**

Add near `localProfile`:

```ts
  @State profileLoadError: string = '';
```

- [ ] **Step 3: Add catch to each loadProfile call**

Change:

```ts
    this.profileRepository.loadProfile().then((profile: HealthProfile) => {
      this.localProfile = profile;
    });
```

to:

```ts
    this.profileRepository.loadProfile().then((profile: HealthProfile) => {
      this.localProfile = profile;
      this.profileLoadError = '';
    }).catch(() => {
      this.localProfile = createDefaultHealthProfile();
      this.profileLoadError = getEmptyStateInfo('profileLoad').detail;
    });
```

For `AssistantTab`, preserve setting `questionnaireScore` on success and set it to default profile constitution score on failure:

```ts
    this.profileRepository.loadProfile().then((profile: HealthProfile) => {
      this.localProfile = profile;
      this.questionnaireScore = profile.constitution.score;
      this.profileLoadError = '';
    }).catch(() => {
      const fallbackProfile = createDefaultHealthProfile();
      this.localProfile = fallbackProfile;
      this.questionnaireScore = fallbackProfile.constitution.score;
      this.profileLoadError = getEmptyStateInfo('profileLoad').detail;
    });
```

- [ ] **Step 4: Render notice near top**

In each tab `Column`, render after section title or first line:

```ts
      LoadStateNotice({ message: this.profileLoadError })
```

For `HomeTab`, render as the first child before weather card.

For `AssistantTab`, render after `SectionTitle('AI健康问答')`.

For `DataTab`, render after `SectionTitle('健康数据')`.

For `ProfileTab`, render before `ProfileSummary`.

### Task 4: Verification

**Files:**
- No code edits.

- [ ] **Step 1: Static verify wiring**

Run:

```powershell
rg -n "profileLoadError|LoadStateNotice|getEmptyStateInfo\\('profileLoad'\\)" entry\src\main\ets entry\src\test
rg -n "\\.catch\\(\\(\\) => \\{" entry\src\main\ets\components\tabs\HomeTab.ets entry\src\main\ets\components\tabs\AssistantTab.ets entry\src\main\ets\components\tabs\DataTab.ets entry\src\main\ets\components\tabs\ProfileTab.ets
```

Expected: four tabs have `profileLoadError`, `LoadStateNotice`, and `.catch(...)`.

- [ ] **Step 2: Scope checks**

Run:

```powershell
rg -n "重试|retry|网络异常|权限失败|云同步已开启" entry\src\main\ets\components\cards\LoadStateNotice.ets entry\src\main\ets\services\EmptyStateService.ets
```

Expected: no retry/network/fake capability claims.

- [ ] **Step 3: Attempt HarmonyOS verification**

Run:

```powershell
hvigor test
hvigor assembleHap
git status --short
```

Expected in this shell if unchanged: `hvigor` unavailable and workspace is not a git repository.

## Self-Review

- Spec coverage: This plan covers copy, notice UI, four profile-loading tabs, failure fallback, tests, and verification.
- Placeholder scan: No placeholder steps remain.
- Type consistency: `profileLoadError`, `LoadStateNotice`, and `getEmptyStateInfo('profileLoad')` names are used consistently.
