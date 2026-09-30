# Unified Empty State Design

## Goal

Create a reusable empty-state foundation so local no-data moments use consistent copy and styling across the app.

## Current Context

The app already has several no-data or fallback states:

- Recent records list shows `暂无本地记录...`.
- Monthly report has a no-record summary.
- Data tab falls back to mock metrics when no local indicators exist.
- Reminders can theoretically be empty after future settings changes.

The copy and rendering are currently scattered. A small shared foundation will make future empty and error states easier to implement consistently.

## Scope

In scope:

- Add an `EmptyStateInfo` model.
- Add deterministic empty-state copy helpers.
- Add a reusable `EmptyStateBlock` UI builder/component.
- Replace the recent-records empty text with the shared block.
- Add unit tests for empty-state copy.

Out of scope:

- Repository load error handling.
- Retry buttons.
- Global error boundary.
- Navigation actions.
- Network or permission states.

## Empty State Keys

Initial keys:

- `records`: no tongue or indicator records.
- `indicators`: no local health indicators.
- `reminders`: no reminder preferences.
- `monthlyReport`: no records for report.

Unknown keys return a generic local empty state.

## Architecture

Add to `WellnessModels.ets`:

- `EmptyStateInfo`

Create `EmptyStateService.ets`:

- `getEmptyStateInfo(key: string): EmptyStateInfo`

Create `components/cards/EmptyStateBlock.ets`:

- Receives `info: EmptyStateInfo`.
- Renders title and detail in a quiet shared style.

Update `RecentRecordsList.ets`:

- Import `getEmptyStateInfo`.
- Import `EmptyStateBlock`.
- Render `EmptyStateBlock({ info: getEmptyStateInfo('records') })` when both record arrays are empty.

## Testing

Add tests for:

- `records` empty-state title and detail.
- Unknown key fallback.

## Verification

Run:

- `rg -n "EmptyStateBlock|getEmptyStateInfo|EmptyStateInfo" entry\src\main\ets entry\src\test`
- `rg -n "暂无本地记录，保存舌象或健康指标后会显示在这里" entry\src\main\ets`
- `hvigor test`
- `hvigor assembleHap`

If `hvigor` is unavailable, report the limitation.
