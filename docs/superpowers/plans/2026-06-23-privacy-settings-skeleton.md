# Privacy Settings Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a visible local privacy and data-safety section to the profile tab.

**Architecture:** Define deterministic privacy status data in a small service, render it through a profile card component, and add unit tests for the status copy. This avoids fake permission/cloud behavior while making data boundaries visible.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, deterministic local services, Hypium unit tests.

---

## File Structure

- Modify `entry/src/main/ets/model/WellnessModels.ets`: add `PrivacyStatusItem`.
- Create `entry/src/main/ets/services/PrivacyService.ets`: expose privacy summary and status items.
- Modify `entry/src/test/LocalUnit.test.ets`: add privacy service tests.
- Create `entry/src/main/ets/components/profile/PrivacyStatusCard.ets`: render summary and status rows.
- Modify `entry/src/main/ets/components/tabs/ProfileTab.ets`: render privacy card.

### Task 1: Privacy Status Service

**Files:**
- Modify: `entry/src/main/ets/model/WellnessModels.ets`
- Create: `entry/src/main/ets/services/PrivacyService.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing tests**

Add import in `LocalUnit.test.ets`:

```ts
import { getPrivacyStatusItems, getPrivacySummary } from '../main/ets/services/PrivacyService';
```

Add tests near other service tests:

```ts
    it('lists local device storage in privacy status', 0, () => {
      const items = getPrivacyStatusItems();

      expect(items.length).assertEqual(4);
      expect(items[0].title).assertEqual('数据位置');
      expect(items[0].detail).assertContain('本机');
    });

    it('shows cloud sync disabled in privacy status', 0, () => {
      const items = getPrivacyStatusItems();

      expect(items[1].title).assertEqual('云同步');
      expect(items[1].status).assertEqual('未开启');
    });

    it('summarizes local privacy boundary', 0, () => {
      const summary = getPrivacySummary();

      expect(summary).assertContain('本地');
      expect(summary).assertContain('未开启云同步');
    });
```

- [ ] **Step 2: Verify red state**

Run:

```powershell
hvigor test
rg -n "getPrivacyStatusItems|getPrivacySummary|PrivacyStatusItem" entry\src\main\ets
```

Expected in this shell: `hvigor` may be unavailable. Static search should have no production matches before implementation.

- [ ] **Step 3: Add model**

In `WellnessModels.ets`, add:

```ts
export interface PrivacyStatusItem {
  title: string;
  detail: string;
  status: string;
}
```

- [ ] **Step 4: Add service**

Create `PrivacyService.ets`:

```ts
import { PrivacyStatusItem } from '../model/WellnessModels';

export function getPrivacySummary(): string {
  return '当前健康档案保存在本地设备，未开启云同步；问卷、舌象、指标和提醒偏好仅用于本机养生建议。';
}

export function getPrivacyStatusItems(): PrivacyStatusItem[] {
  return [
    {
      title: '数据位置',
      detail: '健康档案保存在本机应用数据中。',
      status: '本地'
    },
    {
      title: '云同步',
      detail: '当前版本不上传健康档案，也不提供云端备份。',
      status: '未开启'
    },
    {
      title: '设备权限',
      detail: '当前手动记录阶段未请求相机、定位或设备连接权限。',
      status: '未请求'
    },
    {
      title: '数据范围',
      detail: '包括体质问卷、舌象文字、手动指标和提醒偏好。',
      status: '本地使用'
    }
  ];
}
```

- [ ] **Step 5: Static verify service**

Run:

```powershell
rg -n "PrivacyStatusItem|getPrivacyStatusItems|getPrivacySummary" entry\src\main\ets entry\src\test
```

Expected: model, service, and tests are present.

### Task 2: Privacy Status Card

**Files:**
- Create: `entry/src/main/ets/components/profile/PrivacyStatusCard.ets`
- Modify: `entry/src/main/ets/components/tabs/ProfileTab.ets`

- [ ] **Step 1: Create component**

Create `PrivacyStatusCard.ets`:

```ts
import { PrivacyStatusItem } from '../../model/WellnessModels';
import { getPrivacyStatusItems, getPrivacySummary } from '../../services/PrivacyService';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

@Component
export struct PrivacyStatusCard {
  build() {
    const items = getPrivacyStatusItems();

    Column({ space: 12 }) {
      Text('隐私与数据安全')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(getPrivacySummary())
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .lineHeight(20)

      ForEach(items, (item: PrivacyStatusItem) => {
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
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(item.status)
            .fontSize(11)
            .fontColor(item.status === '未开启' || item.status === '未请求' ? WARM_ACCENT : BRAND_GREEN)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#EEF7F1')
            .borderRadius(10)
        }
        .width('100%')
      }, (item: PrivacyStatusItem) => item.title)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }
}
```

- [ ] **Step 2: Render from ProfileTab**

In `ProfileTab.ets`, import:

```ts
import { PrivacyStatusCard } from '../profile/PrivacyStatusCard';
```

Render before reminder management:

```ts
      PrivacyStatusCard()
```

- [ ] **Step 3: Static verify card wiring**

Run:

```powershell
rg -n "PrivacyStatusCard|getPrivacyStatusItems|getPrivacySummary" entry\src\main\ets
```

Expected: component is created and rendered by `ProfileTab`.

### Task 3: Final Verification

**Files:**
- No code edits.

- [ ] **Step 1: Scope checks**

Run:

```powershell
rg -n "云同步已开启|权限已授权|加密存储|合规认证|登录账号|云端备份已开启" entry\src\main\ets entry\src\test
rg -n "PrivacyStatusCard|getPrivacyStatusItems|getPrivacySummary" entry\src\main\ets entry\src\test
```

Expected: no fake capability claims; privacy skeleton terms are present.

- [ ] **Step 2: Attempt HarmonyOS verification**

Run:

```powershell
hvigor test
hvigor assembleHap
git status --short
```

Expected in this shell if unchanged: `hvigor` unavailable and workspace is not a git repository.

## Self-Review

- Spec coverage: This plan covers status data, summary, UI card, profile tab rendering, tests, and no-fake-capability verification.
- Placeholder scan: No placeholder steps remain.
- Type consistency: `PrivacyStatusItem`, `PrivacyService`, and `PrivacyStatusCard` names are defined before use.
