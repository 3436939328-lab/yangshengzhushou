# Local Home Personalization Design

## Goal

Make the home tab reflect the saved local health profile instead of always showing the dashboard's fixed personal plan. This continues the offline-first product loop by making the first screen feel connected to the user's questionnaire, tongue notes, and manual indicators.

## Current Context

`HomeTab` currently receives a `PersonalPlan` from `WellnessDashboardViewModel`. That dashboard plan is generated with fixed values: constitution `气虚质`, goal `控糖`, and sleep `6.5`.

Other tabs already load `HealthProfile` locally:

- `AssistantTab` uses local profile context for answers.
- `DataTab` prefers saved indicators for metric cards.
- `ProfileTab` uses local profile for summary, reminders, records, and monthly report.

The home tab should follow the same component-level repository pattern for this phase.

## Scope

In scope:

- Add a pure local-home adapter that builds a `PersonalPlan` from `HealthProfile`.
- Load local profile inside `HomeTab`.
- Show the local plan in the existing `PersonalPlanCard`.
- Keep existing weather, solar term, daily plan rows, and quick actions unchanged.
- Add unit tests for profile-to-home-plan behavior.

Out of scope:

- Redesigning the home screen.
- Replacing weather or solar-term data.
- Real device ingestion.
- Cloud sync.
- Medical diagnosis.
- AI-generated plans.

## Local Plan Rules

The adapter should infer simple deterministic inputs:

- Constitution comes from `profile.constitution.name`.
- Goal defaults to `节气养护`.
- If the latest or any saved indicator name contains `血糖`, use goal `控糖`.
- If an indicator name contains `血压`, use goal `稳压`.
- Sleep hours default to `7.2`.
- If a saved sleep indicator exists, parse its numeric value and use it for the sleep segment.
- If a recent tongue note has `dryness` containing `干`, keep the plan gentle and hydration-oriented through the existing plan detail text.

The adapter should not invent clinical advice. It should reuse the existing `generatePersonalPlan()` structure so output remains familiar and testable.

## Architecture

Add home personalization helpers to `ProfileViewModel.ets` because that file already adapts `HealthProfile` into UI-ready data:

- `inferHomeGoal(profile): string`
- `inferSleepHours(profile): number`
- `buildLocalPersonalPlan(profile): PersonalPlan`

`HomeTab.ets` will:

1. Create default `localProfile`.
2. Load persisted profile via `createPreferencesHealthProfileRepository`.
3. Compute `localPersonalPlan = buildLocalPersonalPlan(this.localProfile)`.
4. Render `PersonalPlanCard(localPersonalPlan)` instead of the static prop.

The existing `personalPlan` prop can be removed from `HomeTab` and from `Index.ets`.

## Data Flow

1. App enters home tab.
2. `HomeTab.aboutToAppear()` loads local profile.
3. `buildLocalPersonalPlan(localProfile)` maps profile into a plan.
4. User sees the existing plan card populated with local constitution, goal, and sleep context.

## Error Handling

- Empty profile uses default constitution and a neutral goal.
- Unknown indicators do not affect the goal.
- Unparseable sleep values fall back to `7.2`.
- Repository read failure keeps the default local profile.

## Testing

Add tests for:

- Default profile creates a plan using the default constitution.
- Blood glucose indicators infer the `控糖` goal.
- Sleep indicators below 7 trigger the sleep-repair segment.

## Verification

Run:

- `rg -n "buildLocalPersonalPlan|inferHomeGoal|inferSleepHours" entry\src\main\ets entry\src\test`
- `rg -n "personalPlan:" entry\src\main\ets\pages\Index.ets entry\src\main\ets\components\tabs\HomeTab.ets`
- `hvigor test`
- `hvigor assembleHap`

If `hvigor` is unavailable in the current shell, report the exact limitation.
