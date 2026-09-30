# Local Recording Loop Design

## Goal

Extend the offline-first wellness assistant so users can record daily health observations after completing the constitution questionnaire.

This phase adds text-based tongue observation records, manual health indicator entries, and data/profile screens that prefer saved local profile data over mock data.

## Current State

The app now has:

- Local profile models in `ProfileModels.ets`.
- Questionnaire scoring in `QuestionnaireService.ets`.
- Local profile repository and Preferences adapter in `ProfileRepository.ets`.
- Profile summary view model in `ProfileViewModel.ets`.
- Questionnaire UI in `QuestionnaireFlow.ets`.
- Profile summary UI in `ProfileSummary.ets`.

The remaining gap is daily recording. The data tab still mostly displays deterministic mock metrics, and the user has no UI for adding tongue notes or manual health indicators.

## Scope

This phase includes:

- A text-only tongue observation form.
- A manual health indicator form for blood pressure, blood glucose, sleep, and step count.
- Repository support for saving tongue notes and health indicator entries.
- Data tab support for rendering saved local profile indicators first, then falling back to mock metrics.
- Profile summary support for showing local record counts and latest update.
- Unit tests for repository save paths, summary counts, and fallback behavior.

This phase does not include:

- Camera capture.
- Image-based tongue recognition.
- OCR.
- Real device SDK sync.
- Login or cloud sync.
- Real AI API calls.

## Data Model

Reuse existing `ProfileModels.ets` types:

- `TongueObservationNote`
- `HealthIndicatorEntry`
- `HealthProfile`

No new persistent top-level model is required.

Tongue note fields:

- `color`
- `coating`
- `dryness`
- `note`
- `recordedAt`

Health indicator fields:

- `name`
- `value`
- `unit`
- `recordedAt`

## Architecture

Repository layer:

- `ProfileRepository.saveTongueNote(note)` already defines the needed write path.
- `ProfileRepository.saveHealthIndicator(entry)` already defines the needed write path.
- This phase adds tests and UI usage for those methods.

View model layer:

- Extend `ProfileViewModel` with helper functions that convert local indicators into UI metric cards.
- Keep fallback logic explicit: saved local entries win; mock metrics render only when no saved entries exist.

UI layer:

- Add `TongueNoteForm` under `components/profile`.
- Add `HealthIndicatorForm` under `components/profile`.
- Add both forms to `ProfileTab` below the local profile summary.
- Update `DataTab` to accept optional local profile indicators and render them above or instead of mock metrics.

## User Flow

1. The user opens 我的.
2. The app loads the local profile through `ProfileRepository`.
3. The user records tongue observation text and taps save.
4. The app saves the note locally and refreshes the profile summary.
5. The user records a health indicator and taps save.
6. The app saves the indicator locally and refreshes the profile summary.
7. 数据 reads saved indicators when available and shows them as metric cards.

## Error Handling

- If a form field is empty, show a concise inline message and do not save.
- If repository save fails, keep the current form values visible and show a concise failure message.
- If no saved indicator exists, keep rendering the current mock metric cards.
- Health copy remains non-diagnostic and descriptive.

## UI Direction

- Use the existing restrained card style.
- Keep form controls compact and scannable.
- Use simple text inputs and segmented choices.
- Do not introduce image upload, camera affordances, or OCR copy.
- Keep card radius at `8`.

## Testing

Unit tests should cover:

- Saving a tongue note appends to `HealthProfile.tongueNotes`.
- Saving a health indicator appends to `HealthProfile.healthIndicators`.
- Profile summary counts update when records exist.
- Local indicators convert to metric-card-friendly data.
- Fallback returns mock metrics when local indicators are empty.

Verification should include:

- `hvigor test`
- `hvigor assembleHap`
- Static search for camera/OCR/device/cloud claims.
- Static search for mojibake and malformed interpolation.

If `hvigor` remains unavailable in the local shell, record the exact command failure.

## Migration Strategy

1. Add repository tests for tongue notes and health indicators.
2. Add view model helpers for local indicator rendering and fallback.
3. Add tongue note and indicator form components.
4. Wire forms into profile tab.
5. Wire saved local indicators into data tab.
6. Run static and toolchain verification.
