# Local Profile And Questionnaire Design

## Goal

Turn the current HarmonyOS wellness assistant from a polished mock experience into a usable single-device health management loop.

This phase adds a local user health profile, a complete constitution questionnaire workflow, and local persistence. It keeps the app offline-first and prepares clean service boundaries for later AI API, device SDK, OCR, account, and cloud sync work.

## Current State

The app already has:

- A four-tab ArkUI structure: 首页, AI助手, 数据, 我的.
- Extracted page components under `entry/src/main/ets/components`.
- A dashboard view model under `entry/src/main/ets/viewmodel`.
- Local deterministic services under `entry/src/main/ets/services`.
- Utility modules for constitution, recommendations, solar terms, and risk summaries.

The main gap is that user state is not durable. The assistant tab uses a simple questionnaire score control, and profile/data screens render mock data instead of a saved personal record.

## Scope

This phase includes:

- A full constitution questionnaire with grouped questions, answer options, scoring, result explanation, and retake support.
- A local health profile containing constitution result, questionnaire history, basic health indicators, tongue observation notes, and reminder preferences.
- Local persistence so profile data survives app restart.
- UI integration in the AI assistant tab and profile tab.
- Service and repository boundaries that can later be backed by cloud APIs.

This phase does not include:

- Real AI API calls.
- Login, account binding, or cloud sync.
- Real device SDK integration.
- OCR.
- Camera capture or image-based tongue recognition.
- Medical diagnosis or treatment claims.

## Recommended Architecture

Add a local profile domain beside the existing mock services:

- `entry/src/main/ets/model/ProfileModels.ets`
- `entry/src/main/ets/services/QuestionnaireService.ets`
- `entry/src/main/ets/services/ProfileRepository.ets`
- `entry/src/main/ets/viewmodel/ProfileViewModel.ets`
- `entry/src/main/ets/components/questionnaire/QuestionnaireFlow.ets`
- `entry/src/main/ets/components/profile/ProfileSummary.ets`

`QuestionnaireService` owns pure scoring logic and question definitions. It should not know about ArkUI or persistence.

`ProfileRepository` owns local storage reads and writes. It provides a small API for loading, saving, and resetting the local profile. The first implementation should use HarmonyOS Preferences-style key-value persistence behind this repository boundary, with JSON serialization for the profile payload.

`ProfileViewModel` adapts repository data into UI-friendly state for profile and assistant screens.

UI components receive data and callbacks through ArkUI props and links. Existing service modules remain usable for recommendations and health guidance.

## Data Model

`HealthProfile` stores:

- `id`: local profile id.
- `displayName`: optional local name.
- `constitution`: latest constitution result.
- `questionnaireRecords`: historical questionnaire submissions.
- `healthIndicators`: saved blood pressure, blood glucose, sleep, and step entries.
- `tongueNotes`: text observations such as color, coating, dryness, and user note.
- `reminderPreferences`: local reminder settings.
- `updatedAt`: ISO timestamp.

`QuestionnaireQuestion` stores:

- `id`
- `group`
- `title`
- `options`

`QuestionnaireAnswer` stores:

- `questionId`
- `score`
- `label`

`QuestionnaireRecord` stores:

- `submittedAt`
- `answers`
- `totalScore`
- `constitution`
- `suggestion`

## User Flow

1. The user opens AI助手 and taps the constitution questionnaire entry.
2. The app shows grouped questions one at a time or in compact sections.
3. The user submits answers.
4. `QuestionnaireService` calculates the constitution result.
5. The app shows result, suggestion, and safety disclaimer.
6. The user saves the result into the local health profile.
7. 我的 shows the latest constitution, last questionnaire date, and profile completeness.
8. AI助手 and 数据 use the saved constitution instead of hardcoded mock assumptions when available.

## Error Handling

- If no saved profile exists, the app creates an empty local profile with safe defaults.
- If local storage read fails, the UI falls back to deterministic mock data and displays a concise recovery message.
- If questionnaire answers are incomplete, submit remains disabled or returns a clear inline validation message.
- If stored data is malformed, the repository ignores the invalid record and rebuilds defaults.
- All health copy keeps disclaimer language and avoids diagnosis claims.

## UI Direction

The current quiet wellness utility style stays in place:

- Green remains the primary color.
- Card radius stays at 8.
- The questionnaire should feel like a focused form, not a marketing flow.
- Profile summary should be dense and scannable: latest constitution, profile completion, recent records, and next useful action.
- Tongue observation in this phase is text-based recording only.

## Testing

Unit tests should cover:

- Questionnaire scoring for default, low, and high score paths.
- Profile repository default profile creation.
- Saving and loading a profile.
- Handling malformed or empty local storage content.
- View model fallback when no saved profile exists.
- Existing recommendation behavior using the saved constitution.

Verification should include:

- `hvigor test`
- `hvigor assembleHap`
- Static search for camera/OCR/API claims in this phase.
- Static search for mojibake and malformed interpolation.

If `hvigor` is unavailable in the local shell, record the exact command failure and rely on static checks until DevEco Studio or the HarmonyOS toolchain can run the project.

## Migration Strategy

1. Add pure questionnaire models and service tests.
2. Add local profile model and repository tests.
3. Add profile view model that loads saved data with defaults.
4. Replace assistant tab score stepper with `QuestionnaireFlow`.
5. Update profile tab to render `ProfileSummary`.
6. Wire saved constitution into recommendations and reports.
7. Run verification and record toolchain limitations.

## Explicit Constraints

- The storage choice for this phase is local key-value persistence through `ProfileRepository`; no UI component reads storage directly.
- The first questionnaire stays compact enough for a mobile screen and can expand later without changing the scoring service contract.
- Cloud sync and account identity remain intentionally out of scope for this phase.
