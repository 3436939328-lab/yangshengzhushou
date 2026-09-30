# Page Architecture Refactor Design

## Goal

Refactor the current HarmonyOS wellness assistant page architecture so the app is easier to extend with real questionnaire, AI chat, reminders, device data, and report workflows later.

The visible experience should remain equivalent to the current polished version.

## Current State

`entry/src/main/ets/pages/Index.ets` is about 966 lines and contains:

- Entry state.
- Onboarding UI.
- Header.
- Four tab pages.
- Bottom tab bar.
- Reusable card builders.
- Direct service and utility calls.

This works for a prototype, but the file is now too large for safe incremental feature work.

## Scope

This phase performs a structural refactor only:

- Split page-level UI into focused components.
- Move shared visual constants into a theme module.
- Add a dashboard view model that gathers existing deterministic mock data.
- Keep existing services and utilities as the source of business logic.
- Keep current visual style and user-facing copy.
- Keep current four tabs: `首页`, `AI助手`, `数据`, `我的`.

This phase does not add real backend APIs, login, persistence, device SDK integration, camera capture, notification scheduling, or new product workflows.

## Proposed File Structure

Create:

- `entry/src/main/ets/theme/WellnessTheme.ets`
- `entry/src/main/ets/viewmodel/WellnessDashboardViewModel.ets`
- `entry/src/main/ets/components/GuideView.ets`
- `entry/src/main/ets/components/AppHeader.ets`
- `entry/src/main/ets/components/TabBar.ets`
- `entry/src/main/ets/components/tabs/HomeTab.ets`
- `entry/src/main/ets/components/tabs/AssistantTab.ets`
- `entry/src/main/ets/components/tabs/DataTab.ets`
- `entry/src/main/ets/components/tabs/ProfileTab.ets`
- `entry/src/main/ets/components/cards/CommonCards.ets`

Modify:

- `entry/src/main/ets/pages/Index.ets`

Do not modify services/utils unless the split exposes a compile issue that cannot be solved in the component layer.

## Architecture

`Index.ets` remains the app entry page. It keeps only top-level UI state:

- `hasEnteredApp`
- `guideIndex`
- `currentTab`
- `questionnaireScore`

`WellnessDashboardViewModel.ets` becomes the single place that assembles current mock data from services and utilities:

- guide slides
- weather wellness
- solar term
- daily plans
- health metrics
- device status
- personal plan
- medical report
- monthly report
- archive summaries
- profile actions
- reminders

Components receive typed data and callbacks through `@Prop`, `@Link`, or simple method parameters, following ArkTS component patterns already used in the project.

## Component Responsibilities

`GuideView`
Renders onboarding slides and exposes enter/next/skip behavior through linked state or callbacks.

`AppHeader`
Renders app title, subtitle, and weather risk chip.

`TabBar`
Renders the four tabs and updates selected tab.

`HomeTab`
Renders weather, solar term, personalized plan, daily plans, and quick actions.

`AssistantTab`
Renders chat examples, questionnaire score controls, recommendation, generated answer, and knowledge cards.

`DataTab`
Renders health risk, report interpretation, health metrics, sleep analysis, and device sync.

`ProfileTab`
Renders archive summary, archive cards, monthly report, profile actions, and reminder toggles.

`CommonCards`
Holds card builders that are shared across tabs or too small to deserve separate files in this phase.

## Data Flow

1. `Index.ets` creates or reads dashboard data from `WellnessDashboardViewModel`.
2. `Index.ets` passes data into the selected tab component.
3. Tab components render only their assigned screen area.
4. Shared cards render typed model data.
5. Existing service and utility functions remain deterministic and testable.

The questionnaire score remains top-level state because it affects both AI assistant content and profile archive summary.

## Error Handling

This phase does not introduce network or persistence errors. Components should keep the current defensive checks around optional list content, especially in knowledge cards.

Generated AI and recommendation copy must continue to include safety language that avoids medical diagnosis claims.

## Testing And Verification

Verification should include:

- Existing Hypium unit tests.
- Static search for mojibake in `entry/src/main/ets` and `entry/src/test`.
- Static search for malformed interpolation patterns.
- File existence checks for the new component/theme/viewmodel modules.
- Manual or IDE build verification when HarmonyOS tooling is available.

If `hvigor` remains unavailable in the local shell, record the exact command failure and residual compile-risk.

## Migration Strategy

Use small behavior-preserving steps:

1. Extract theme constants.
2. Add dashboard view model.
3. Extract guide, header, and tab bar.
4. Extract tab components.
5. Extract shared cards.
6. Run verification after each meaningful step.

No step should intentionally change product behavior or visual hierarchy.
