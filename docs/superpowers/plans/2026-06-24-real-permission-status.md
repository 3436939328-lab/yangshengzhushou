# Real Permission Status Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show real permission status in the privacy card without requesting new permissions from that card.

**Architecture:** Add pure permission-row builders to `PrivacyService.ets`, then add a thin runtime loader that checks permissions through HarmonyOS ability access control. Update `PrivacyStatusCard.ets` to render fallback rows first and replace them with runtime rows after `aboutToAppear`.

**Tech Stack:** HarmonyOS ArkTS, `@kit.AbilityKit` permission APIs, existing `PrivacyStatusItem` model and Hypium local unit tests.

---

### Task 1: Pure Permission Row Builder

**Files:**
- Modify: `D:\yangshengzhushou\entry\src\main\ets\services\PrivacyService.ets`
- Modify: `D:\yangshengzhushou\entry\src\test\LocalUnit.test.ets`

- [ ] **Step 1: Write failing unit test**

In `LocalUnit.test.ets`, update the PrivacyService import:

```ts
import { buildPrivacyStatusItemsFromPermissionStates, getPrivacyStatusItems, getPrivacySummary } from '../main/ets/services/PrivacyService';
```

Add this test near the existing privacy tests:

```ts
    it('builds privacy status from permission states', 0, () => {
      const items = buildPrivacyStatusItemsFromPermissionStates({
        location: 'granted',
        camera: 'notGranted',
        notification: 'notConfigured',
        bluetooth: 'notUsed'
      });

      expect(items.length).assertEqual(7);
      expect(items[2].title).assertEqual('定位权限');
      expect(items[2].status).assertEqual('已授权');
      expect(items[3].title).assertEqual('相机权限');
      expect(items[3].status).assertEqual('未授权');
      expect(items[4].title).assertEqual('通知权限');
      expect(items[4].status).assertEqual('未配置');
      expect(items[5].title).assertEqual('设备连接权限');
      expect(items[5].status).assertEqual('当前未使用');
    });
```

- [ ] **Step 2: Run test if local ArkTS tests are available**

Run the existing HarmonyOS unit test command from DevEco/Hvigor. Expected: FAIL because `buildPrivacyStatusItemsFromPermissionStates` does not exist.

- [ ] **Step 3: Implement pure builder**

In `PrivacyService.ets`, add:

```ts
export type PermissionState = 'granted' | 'notGranted' | 'notConfigured' | 'notUsed';

export interface PrivacyPermissionStates {
  location: PermissionState;
  camera: PermissionState;
  notification: PermissionState;
  bluetooth: PermissionState;
}

function permissionStatusText(state: PermissionState): string {
  if (state === 'granted') {
    return '已授权';
  }
  if (state === 'notGranted') {
    return '未授权';
  }
  if (state === 'notConfigured') {
    return '未配置';
  }
  return '当前未使用';
}

export function buildPrivacyStatusItemsFromPermissionStates(states: PrivacyPermissionStates): PrivacyStatusItem[] {
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
      title: '定位权限',
      detail: '用于获取当前位置天气，辅助生成本地化养生建议。',
      status: permissionStatusText(states.location)
    },
    {
      title: '相机权限',
      detail: '预留给舌象拍照能力；当前舌象仍以文字记录为主。',
      status: permissionStatusText(states.camera)
    },
    {
      title: '通知权限',
      detail: '用于饮水、久坐和睡前提醒等本机通知。',
      status: permissionStatusText(states.notification)
    },
    {
      title: '设备连接权限',
      detail: '预留给蓝牙设备管理；当前健康指标仍以手动记录为主。',
      status: permissionStatusText(states.bluetooth)
    },
    {
      title: '数据范围',
      detail: '包括体质问卷、舌象文字、手动指标和提醒偏好。',
      status: '本地使用'
    }
  ];
}
```

Change `getPrivacyStatusItems()` to return:

```ts
return buildPrivacyStatusItemsFromPermissionStates({
  location: 'notConfigured',
  camera: 'notUsed',
  notification: 'notConfigured',
  bluetooth: 'notUsed'
});
```

- [ ] **Step 4: Run test again**

Expected: privacy builder test passes.

### Task 2: Runtime Permission Status Loader

**Files:**
- Modify: `D:\yangshengzhushou\entry\src\main\ets\services\PrivacyService.ets`

- [ ] **Step 1: Add runtime checker**

Import ability APIs:

```ts
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
```

Add:

```ts
function authResultToPermissionState(result: abilityAccessCtrl.GrantStatus): PermissionState {
  return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ? 'granted' : 'notGranted';
}

function checkPermissionState(
  atManager: abilityAccessCtrl.AtManager,
  context: common.UIAbilityContext,
  permission: Permissions,
  fallback: PermissionState
): Promise<PermissionState> {
  try {
    return atManager.checkAccessToken(context.applicationInfo.accessTokenId, permission).then((result: abilityAccessCtrl.GrantStatus) => {
      return authResultToPermissionState(result);
    }).catch(() => {
      return fallback;
    });
  } catch (error) {
    return Promise.resolve(fallback);
  }
}

export function getRuntimePrivacyStatusItems(context: common.UIAbilityContext): Promise<PrivacyStatusItem[]> {
  const atManager = abilityAccessCtrl.createAtManager();
  return Promise.all([
    checkPermissionState(atManager, context, 'ohos.permission.LOCATION', 'notConfigured'),
    checkPermissionState(atManager, context, 'ohos.permission.CAMERA', 'notUsed'),
    checkPermissionState(atManager, context, 'ohos.permission.NOTIFICATION_CONTROLLER', 'notConfigured'),
    Promise.resolve('notUsed' as PermissionState)
  ]).then((values: PermissionState[]) => {
    return buildPrivacyStatusItemsFromPermissionStates({
      location: values[0],
      camera: values[1],
      notification: values[2],
      bluetooth: values[3]
    });
  }).catch(() => {
    return getPrivacyStatusItems();
  });
}
```

- [ ] **Step 2: Build in DevEco/Hvigor**

Expected: compiles. If the notification permission identifier or `applicationInfo.accessTokenId` is not supported in this SDK, replace only that check with fallback `notConfigured` and keep location/camera checks.

### Task 3: Privacy Card Uses Runtime Rows

**Files:**
- Modify: `D:\yangshengzhushou\entry\src\main\ets\components\profile\PrivacyStatusCard.ets`

- [ ] **Step 1: Add runtime state**

Update imports:

```ts
import { common } from '@kit.AbilityKit';
import { getPrivacyStatusItems, getPrivacySummary, getRuntimePrivacyStatusItems } from '../../services/PrivacyService';
```

Add state inside `PrivacyStatusCard`:

```ts
  @State privacyItems: PrivacyStatusItem[] = getPrivacyStatusItems();
```

Add:

```ts
  aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    getRuntimePrivacyStatusItems(context).then((items: PrivacyStatusItem[]) => {
      this.privacyItems = items;
    }).catch(() => {
      this.privacyItems = getPrivacyStatusItems();
    });
  }
```

Change `private items()` to:

```ts
  private items(): PrivacyStatusItem[] {
    return this.privacyItems;
  }
```

- [ ] **Step 2: Build in DevEco/Hvigor**

Expected: compiles and privacy card opens without requesting any permission prompt.

### Task 4: Verification

**Files:**
- No edits.

- [ ] **Step 1: Backend regression**

Run:

```powershell
npm test
```

from `D:\yangshengzhushou\yangshengzhushou_db`.

Expected: `llm tests passed`, `graph tests passed`, `server tests passed`.

- [ ] **Step 2: Static search**

Run:

```powershell
rg -n "requestPermissionsFromUser|checkAccessToken|getRuntimePrivacyStatusItems|buildPrivacyStatusItemsFromPermissionStates" entry\src\main\ets
```

Expected: Privacy card only uses `checkAccessToken`; permission prompts remain in feature-specific services such as weather.

- [ ] **Step 3: Manual app check**

In DevEco, open the profile/privacy card:

- It renders immediately with fallback rows.
- It updates permission rows after page load.
- It does not trigger a permission request dialog.
- Location status reflects whether weather/location permission has been granted.
