# APP Role Pages Design

## Goal

Make the HarmonyOS APP show different page structures for three identities: normal user, doctor, and administrator.

## Current State

- APP entry page is `D:\yangshengzhushou\entry\src\main\ets\pages\Index.ets`.
- Current bottom tabs are fixed: home, assistant, data, profile.
- Spring Boot login already returns `roles` in the auth response.
- APP auth session currently stores only `id`, `phone`, and `createdAt`, so role routing is not active yet.
- Spring Boot already has consultation APIs:
  - `GET /api/consultation/list`
  - `POST /api/consultation`
  - `GET /api/consultation-message/list`
  - `POST /api/consultation-message`
- PC prototype already has role and consultation interaction examples in `D:\SpringBoot\SpringBootVue\Sprintvue\src\App.vue`.

## Role Model

The APP will use three final role codes:

- `USER`: normal user.
- `DOCTOR`: doctor. Backend `ADVISER` is treated as a doctor-compatible alias.
- `ADMIN`: administrator.

Role priority:

1. `ADMIN`
2. `DOCTOR` or `ADVISER`
3. `USER`

If no role is present, the APP falls back to `USER`.

## User Experience

### Normal User

Tabs:

- Home
- Assistant
- Consultation
- Archive
- Profile

User capabilities:

- Use all existing wellness assistant features.
- Select a registered doctor.
- Create a one-to-one consultation.
- Send and receive messages in a polished chat UI.

### Doctor

Tabs:

- Workbench
- Consultation
- Assistant
- Doctor Profile
- Profile

Doctor capabilities:

- See a login reminder when there are pending consultations.
- Consultation page only shows sessions where `doctorId` is the current doctor.
- If nobody has asked this doctor, the consultation page shows an empty state.
- Reply to user messages in the same chat-style UI.

### Administrator

Tabs:

- Overview
- People
- Assistant Logs
- Consultations
- Profile

Administrator capabilities:

- See all user, doctor, and admin records.
- Create, update, delete, and query personnel.
- See a global assistant Q&A record list.
- Open one user's assistant Q&A in a modal-style conversation view.
- See all consultations.

## Implementation Phases

### Phase 1: Role Routing And Navigation

- Parse and store roles from Spring Boot auth response.
- Add a small role experience service for role normalization, tab generation, and landing tab selection.
- Make `Index.ets` use role-specific tabs.
- Add placeholder pages for consultation, doctor workbench, admin overview, admin people, and admin assistant logs.

### Phase 2: Normal User Consultation

- Add doctor list service.
- Add consultation service.
- Add user consultation page with doctor selection, intake fields, thread list, and chat panel.

### Phase 3: Doctor Workbench

- Add doctor pending consultation summary.
- Show reminder on login when pending items exist.
- Show only consultations assigned to the doctor.
- Allow doctor replies.

### Phase 4: Admin Pages

- Add personnel management UI connected to Spring Boot user/role APIs.
- Add assistant Q&A global list.
- Add conversation popup when an admin selects one user's record.
- Add consultation overview and detail viewing for all one-to-one consultations.

## First Implementation Slice

The first coding slice is intentionally small:

1. Role parsing in `AuthService.ets`.
2. Role tab helper in a new `RoleExperienceService.ets`.
3. Role-aware bottom navigation and placeholder screens in `Index.ets`.
4. Unit tests in `LocalUnit.test.ets` for role parsing and tab selection.

This slice does not yet implement full consultation CRUD in the APP.

## 2026-06-25 Implementation Status

Completed in this pass:

1. APP auth session now stores `roles` and `primaryRole`.
2. Backend `ADVISER` is normalized to APP role `DOCTOR`.
3. APP bottom tabs now differ by role:
   - `USER`: Home, Assistant, Consultation, Archive, Profile
   - `DOCTOR`: Workbench, Consultation, Assistant, Doctor Profile, Profile
   - `ADMIN`: Overview, People, Assistant Logs, Consultations, Profile
4. Normal user consultation tab now calls Spring Boot:
   - doctor list
   - user consultation list
   - create consultation
   - consultation messages
   - send consultation message
5. Doctor workbench and doctor consultation tab now call Spring Boot by `doctorId`, and show a pending-consultation notice.
6. Admin people tab now calls Spring Boot user APIs for list, create, update, and delete.
7. Admin assistant logs tab now calls Spring Boot `GET /api/health-question/list`, groups all health assistant Q&A records by user, and opens a conversation-style detail panel for the selected user's records.
8. Admin consultation overview now calls Spring Boot `GET /api/consultation/list` without filters and opens message details with `GET /api/consultation-message/list`.
9. Doctor profile tab now calls Spring Boot `GET /api/doctor-profile?userId=...` and `POST /api/doctor-profile`, with editable doctor name, title, specialty, and introduction fields.
10. Admin people tab now also calls Spring Boot `GET /api/role/list`, `GET /api/user-role/list`, `POST /api/user-role`, and `DELETE /api/user-role` for role binding management.
11. Admin overview tab now aggregates users, role bindings, assistant logs, and consultation counts from existing Spring Boot APIs.

Still pending:

1. DevEco/Hvigor verification on device or emulator.
