# Basic Experience Polish Design

## Goal

Improve the current HarmonyOS wellness assistant app so the first visible experience is coherent, readable, and demo-ready before deeper feature work begins.

## Current State

The app is an ArkTS HarmonyOS project with a single main page at `entry/src/main/ets/pages/Index.ets`. It already has an onboarding flow and four tabs: home, AI assistant, data, and profile. Most data is provided by local mock services under `entry/src/main/ets/services`.

The main experience problem is that user-facing Chinese text is garbled across UI code, mock data, utility outputs, and unit test expectations. This makes the product look broken even though the app structure is already present.

## Scope

This phase focuses on basic product quality:

- Restore readable Chinese copy for onboarding, headers, tabs, cards, mock content, reminders, reports, recommendations, and health guidance.
- Keep the current four-tab structure: `首页`, `AI助手`, `数据`, `我的`.
- Slightly improve home-page information hierarchy while preserving the existing layout model.
- Keep all data local and deterministic.
- Update unit tests so they assert the corrected product text and service behavior.

This phase does not include login, persistence, real AI API calls, device integration, camera capture, or notification scheduling.

## Architecture

The existing service-first structure stays in place:

- `Index.ets` remains the UI entry point for this phase.
- Mock content stays in service files such as `WellnessContentService.ets`, `PersonalPlanService.ets`, `ReportService.ets`, and related utilities.
- Data interfaces stay in `WellnessModels.ets`.
- Existing utility modules continue to calculate constitution, risks, recommendations, and solar term guidance.

Large component extraction is intentionally deferred. The goal is to stabilize the visible app first, then split components in a later phase when the desired UI shape is clearer.

## UI Design

The visual direction is a calm wellness utility:

- Green remains the primary brand color.
- White cards stay on a soft page background.
- Card radius remains modest.
- Text hierarchy becomes clearer through concise titles, shorter descriptions, and consistent tag labels.
- The home tab emphasizes weather advice, solar term guidance, personalized plan, daily tasks, and quick actions in that order.

No new navigation pattern is introduced in this phase.

## Data Flow

All screen content continues to be generated locally:

1. `Index.ets` calls service and utility functions.
2. Services return typed mock data.
3. Builders render the data into cards, rows, chips, and charts.
4. Simple state such as current tab, onboarding step, and questionnaire score remains in `@State`.

## Error Handling

Because this phase uses local deterministic data, error handling is limited to safe UI assumptions:

- Lists should render only when content exists.
- Generated copy should include health disclaimers where medical advice is implied.
- Risk and recommendation text should avoid overclaiming diagnosis or treatment.

## Testing

Update existing Hypium unit tests to match corrected Chinese strings and current behavior. Verification should include:

- Constitution calculation.
- Solar term guidance.
- Recommendation lookup.
- Risk summary.
- AI safety answer disclaimer.
- Archive, device, reminder, personal plan, report, and knowledge service outputs.

If local HarmonyOS build tooling is unavailable, record that limitation and rely on static file checks plus any runnable project test command available in the workspace.
