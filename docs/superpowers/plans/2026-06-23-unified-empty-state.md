# Unified Empty State Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add shared empty-state copy and UI, then use it in the recent records card.

**Architecture:** Add deterministic empty-state data in a small service and render it through a reusable card builder. Start by replacing the recent records empty text, leaving repository error handling for a later phase.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, deterministic local services, Hypium unit tests.

---

## File Structure

- Modify `entry/src/main/ets/model/WellnessModels.ets`: add `EmptyStateInfo`.
- Create `entry/src/main/ets/services/EmptyStateService.ets`: empty-state copy lookup.
- Modify `entry/src/test/LocalUnit.test.ets`: add empty-state service tests.
- Create `entry/src/main/ets/components/cards/EmptyStateBlock.ets`: reusable empty-state UI.
- Modify `entry/src/main/ets/components/profile/RecentRecordsList.ets`: use shared empty-state UI.

### Task 1: Empty State Service

**Files:**
- Modify: `entry/src/main/ets/model/WellnessModels.ets`
- Create: `entry/src/main/ets/services/EmptyStateService.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing tests**

Add import:

```ts
import { getEmptyStateInfo } from '../main/ets/services/EmptyStateService';
```

Add tests near other service tests:

```ts
    it('returns recent records empty state copy', 0, () => {
      const info = getEmptyStateInfo('records');

      expect(info.title).assertEqual('暂无本地记录');
      expect(info.detail).assertContain('保存舌象或健康指标');
    });

    it('returns generic empty state for unknown key', 0, () => {
      const info = getEmptyStateInfo('unknown');

      expect(info.title).assertEqual('暂无可显示内容');
      expect(info.detail).assertContain('继续使用');
    });
```

- [ ] **Step 2: Verify red state**

Run:

```powershell
hvigor test
rg -n "getEmptyStateInfo|EmptyStateInfo" entry\src\main\ets
```

Expected in this shell: `hvigor` may be unavailable. Static search should have no production matches before implementation.

- [ ] **Step 3: Add model**

In `WellnessModels.ets`, add:

```ts
export interface EmptyStateInfo {
  title: string;
  detail: string;
}
```

- [ ] **Step 4: Add service**

Create `EmptyStateService.ets`:

```ts
import { EmptyStateInfo } from '../model/WellnessModels';

export function getEmptyStateInfo(key: string): EmptyStateInfo {
  if (key === 'records') {
    return {
      title: '暂无本地记录',
      detail: '保存舌象或健康指标后，会在这里看到最近记录。'
    };
  }
  if (key === 'indicators') {
    return {
      title: '暂无本地指标',
      detail: '手动记录血压、血糖、睡眠或步数后，数据页会优先展示本地结果。'
    };
  }
  if (key === 'reminders') {
    return {
      title: '暂无提醒偏好',
      detail: '开启饮水、久坐或睡前提醒后，会在这里统一管理。'
    };
  }
  if (key === 'monthlyReport') {
    return {
      title: '暂无报告记录',
      detail: '完成问卷并记录舌象或指标后，月度报告会自动更新。'
    };
  }
  return {
    title: '暂无可显示内容',
    detail: '继续使用应用后，这里会显示与你相关的本地内容。'
  };
}
```

- [ ] **Step 5: Static verify service**

Run:

```powershell
rg -n "getEmptyStateInfo|EmptyStateInfo" entry\src\main\ets entry\src\test
```

Expected: model, service, and tests are present.

### Task 2: Empty State UI

**Files:**
- Create: `entry/src/main/ets/components/cards/EmptyStateBlock.ets`
- Modify: `entry/src/main/ets/components/profile/RecentRecordsList.ets`

- [ ] **Step 1: Create shared block**

Create:

```ts
import { EmptyStateInfo } from '../../model/WellnessModels';
import { MUTED_TEXT, WARM_ACCENT } from '../../theme/WellnessTheme';

@Component
export struct EmptyStateBlock {
  @Prop info: EmptyStateInfo;

  build() {
    Column({ space: 6 }) {
      Text(this.info.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(WARM_ACCENT)
      Text(this.info.detail)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .lineHeight(20)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}
```

- [ ] **Step 2: Replace RecentRecordsList empty text**

In `RecentRecordsList.ets`, add imports:

```ts
import { getEmptyStateInfo } from '../../services/EmptyStateService';
import { EmptyStateBlock } from '../cards/EmptyStateBlock';
```

Replace:

```ts
        Text('暂无本地记录，保存舌象或健康指标后会显示在这里。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .lineHeight(20)
```

with:

```ts
        EmptyStateBlock({ info: getEmptyStateInfo('records') })
```

- [ ] **Step 3: Static verify UI wiring**

Run:

```powershell
rg -n "EmptyStateBlock|getEmptyStateInfo\\('records'\\)" entry\src\main\ets\components
rg -n "暂无本地记录，保存舌象或健康指标后会显示在这里" entry\src\main\ets
```

Expected: shared block is used; old hardcoded sentence is absent from app code.

### Task 3: Final Verification

**Files:**
- No code edits.

- [ ] **Step 1: Scope checks**

Run:

```powershell
rg -n "retry|重试|加载失败|网络异常|权限失败" entry\src\main\ets\services\EmptyStateService.ets entry\src\main\ets\components\cards\EmptyStateBlock.ets
rg -n "EmptyStateBlock|getEmptyStateInfo|EmptyStateInfo" entry\src\main\ets entry\src\test
```

Expected: no fake error/retry behavior; empty-state terms are present.

- [ ] **Step 2: Attempt HarmonyOS verification**

Run:

```powershell
hvigor test
hvigor assembleHap
git status --short
```

Expected in this shell if unchanged: `hvigor` unavailable and workspace is not a git repository.

## Self-Review

- Spec coverage: This plan covers empty state model, copy service, UI block, recent records usage, tests, and scope checks.
- Placeholder scan: No placeholder steps remain.
- Type consistency: `EmptyStateInfo`, `getEmptyStateInfo`, and `EmptyStateBlock` are defined before use.
