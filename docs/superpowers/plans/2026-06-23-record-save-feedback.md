# Record Save Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show inline success feedback after saving local tongue and health indicator records.

**Architecture:** Keep feedback as local ArkUI component state in the two form components. No repository, model, or tab-level state changes are required.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, local profile forms.

---

## File Structure

- Modify `entry/src/main/ets/components/profile/TongueNoteForm.ets`: add success state, render success text, clear it on edits, set it after save.
- Modify `entry/src/main/ets/components/profile/HealthIndicatorForm.ets`: add success state, render success text, clear it on edits/type changes, set it after save.

### Task 1: Tongue Note Save Feedback

**Files:**
- Modify: `entry/src/main/ets/components/profile/TongueNoteForm.ets`

- [ ] **Step 1: Add success state**

Add:

```ts
  @State successText: string = '';
```

after `errorText`.

- [ ] **Step 2: Clear success on user edits**

In color, coating, and dryness choice callbacks, add:

```ts
        this.successText = '';
```

In `TextInput.onChange`, add:

```ts
          this.successText = '';
```

- [ ] **Step 3: Render success message**

After the `errorText` block, add:

```ts
      if (this.successText.length > 0) {
        Text(this.successText)
          .fontSize(12)
          .fontColor(BRAND_GREEN)
      }
```

- [ ] **Step 4: Set success after save**

After `this.note = '';`, add:

```ts
          this.errorText = '';
          this.successText = '舌象记录已保存';
```

### Task 2: Health Indicator Save Feedback

**Files:**
- Modify: `entry/src/main/ets/components/profile/HealthIndicatorForm.ets`

- [ ] **Step 1: Add success state**

Add:

```ts
  @State successText: string = '';
```

after `errorText`.

- [ ] **Step 2: Clear success on user edits**

In `TextInput.onChange`, add:

```ts
          this.successText = '';
```

In `TypeChip.onClick`, add:

```ts
        this.successText = '';
```

- [ ] **Step 3: Render success message**

After the `errorText` block, add:

```ts
      if (this.successText.length > 0) {
        Text(this.successText)
          .fontSize(12)
          .fontColor(BRAND_GREEN)
      }
```

- [ ] **Step 4: Set success after save**

After `this.value = '';`, add:

```ts
          this.errorText = '';
          this.successText = '健康指标已保存';
```

### Task 3: Verification

**Files:**
- No code edits.

- [ ] **Step 1: Static verify feedback wiring**

Run:

```powershell
rg -n "successText|舌象记录已保存|健康指标已保存" entry\src\main\ets\components\profile\TongueNoteForm.ets entry\src\main\ets\components\profile\HealthIndicatorForm.ets
```

Expected: both forms define, clear, render, and set `successText`.

- [ ] **Step 2: Scope check**

Run:

```powershell
rg -n "delete|remove|编辑|删除" entry\src\main\ets\components\profile\TongueNoteForm.ets entry\src\main\ets\components\profile\HealthIndicatorForm.ets
```

Expected: no delete/edit record behavior was introduced.

- [ ] **Step 3: Attempt HarmonyOS verification**

Run:

```powershell
hvigor test
hvigor assembleHap
git status --short
```

Expected in this shell if unchanged: `hvigor` unavailable and workspace is not a git repository.

## Self-Review

- Spec coverage: This plan covers success state, rendering, clearing, and save behavior for both forms.
- Placeholder scan: No placeholder steps remain.
- Type consistency: Existing form component names and state names match current code.
