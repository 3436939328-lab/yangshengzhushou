# APP Role Pages Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the HarmonyOS APP recognize login roles and show different tab structures for normal users, doctors, and administrators.

**Architecture:** The Spring Boot login response already includes role codes. APP auth parsing will persist roles in the local session, a new role experience service will normalize role codes and produce tab metadata, and `Index.ets` will render role-specific placeholder pages through the existing single-page structure.

**Tech Stack:** HarmonyOS ArkTS, Hypium local tests, existing APP services/components.

---

## Planned File Structure

- Modify: `D:\yangshengzhushou\entry\src\main\ets\services\AuthService.ets`
  Store `roles` and `primaryRole` in `AuthUser`, parse roles from Spring Boot auth payload.
- Create: `D:\yangshengzhushou\entry\src\main\ets\services\RoleExperienceService.ets`
  Normalize roles and return tab definitions for `USER`, `DOCTOR`, and `ADMIN`.
- Modify: `D:\yangshengzhushou\entry\src\main\ets\pages\Index.ets`
  Use role-specific tabs and placeholder pages.
- Modify: `D:\yangshengzhushou\entry\src\test\LocalUnit.test.ets`
  Add tests for auth role parsing and role tab generation.

### Task 1: Parse Roles From Login

- [ ] Add a failing test that parses `roles:["ADVISER"]` into APP primary role `DOCTOR`.
- [ ] Add `roles` and `primaryRole` fields to `AuthUser`.
- [ ] Update `buildAuthSessionFromBackendPayload`.
- [ ] Verify local tests when the HarmonyOS test runner is available.

### Task 2: Add Role Tab Helper

- [ ] Add a failing test for `getRoleTabs("USER")`, `getRoleTabs("DOCTOR")`, and `getRoleTabs("ADMIN")`.
- [ ] Create `RoleExperienceService.ets`.
- [ ] Verify helper output has stable tab keys and labels.

### Task 3: Render Role-Specific APP Tabs

- [ ] Update `Index.ets` to derive tab items from the current session role.
- [ ] Keep existing user pages for `USER` home, assistant, archive, and profile.
- [ ] Add placeholder builders for user consultation, doctor workbench, doctor consultation, admin overview, admin people, admin assistant logs, and admin consultations.
- [ ] Reset invalid tab index when role tab count changes.

### Task 4: Verification

- [ ] Run HarmonyOS local tests in DevEco/Hvigor if available.
- [ ] Static-check imports and role routing paths.
- [ ] Manually verify login as `USER`, `ADVISER/DOCTOR`, and `ADMIN` shows different tab labels.

## Known Constraint

The current command-line environment does not expose `hvigor` or `ohpm`, so APP tests may need to be run from DevEco Studio. Backend Maven tests are available, but this slice is APP-side.
