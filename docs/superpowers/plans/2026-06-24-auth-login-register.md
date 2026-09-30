# Login Register Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add phone/password registration and login before entering the HarmonyOS app.

**Architecture:** Backend exposes `/api/auth/register` and `/api/auth/login`, stores users locally with hashed passwords, and returns a lightweight token. Frontend saves the session in Preferences, shows login/register before the main app, and exposes logout from profile.

**Tech Stack:** Node.js `http` backend, Node `crypto`, ArkTS UI, HarmonyOS Preferences.

---

### Task 1: Backend Auth

**Files:**
- Create: `yangshengzhushou_db/src/authService.js`
- Modify: `yangshengzhushou_db/src/server.js`
- Modify: `yangshengzhushou_db/test/server.test.js`

- [ ] Write failing server tests for register, duplicate register, login, and wrong password.
- [ ] Implement phone/password validation, PBKDF2 password hashing, user JSON storage, token generation.
- [ ] Wire `/api/auth/register` and `/api/auth/login`.
- [ ] Run `npm test`.

### Task 2: Frontend Auth Session

**Files:**
- Create: `entry/src/main/ets/services/AuthService.ets`
- Create: `entry/src/main/ets/components/AuthView.ets`
- Modify: `entry/src/main/ets/services/ApiConfig.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] Add typed request/response builders and local session persistence.
- [ ] Add tests for request payload/session serialization.
- [ ] Build login/register form that calls backend and stores session.

### Task 3: App Gate And Logout

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/components/tabs/ProfileTab.ets`

- [ ] Load saved auth session before showing app.
- [ ] Show auth form before guide/main app when no session exists.
- [ ] Add profile logout callback and clear session.
- [ ] Run available backend tests; ask user to compile in DevEco for ArkTS.
