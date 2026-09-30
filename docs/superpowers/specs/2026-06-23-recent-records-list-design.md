# Recent Records List Design

## Goal

Make saved local records visible in the profile tab after the user creates tongue notes or health indicator entries. This improves the recording loop from "save and update counters" to "save, see, and review recent entries".

## Current Context

`ProfileTab` already lets users save:

- Tongue observation notes through `TongueNoteForm`.
- Manual health indicators through `HealthIndicatorForm`.

The local profile summary counts these records, and reports/data tabs use them, but the profile tab does not show the actual saved entries. A user cannot confirm what was saved without inferring it from counters and generated summaries.

## Scope

In scope:

- Add view model helpers that format recent health indicators and tongue notes into UI rows.
- Add a `RecentRecordsList` profile component.
- Show up to 3 recent indicator records and up to 3 recent tongue records.
- Show a compact empty state when there are no local records.
- Insert the list into `ProfileTab` below the input forms.
- Add unit tests for formatting behavior.

Out of scope:

- Editing records.
- Deleting records.
- Full record history page.
- Sorting persisted data across types.
- Cloud sync or export.

## Display Rules

Health indicator rows:

- Title: indicator name.
- Detail: value plus unit.
- Tag: `指标`.
- Time: `recordedAt`.

Tongue note rows:

- Title: `舌象观察`.
- Detail: color, coating, dryness, and note when present.
- Tag: `舌象`.
- Time: `recordedAt`.

The repository prepends new records, so helpers can take the first N items as recent records.

## Architecture

Add to `ProfileViewModel.ets`:

- `RecentRecordItem`
- `buildRecentIndicatorRecords(profile, limit)`
- `buildRecentTongueRecords(profile, limit)`

Create `components/profile/RecentRecordsList.ets`:

- Accepts `profile: HealthProfile`.
- Calls both helpers.
- Renders empty state if both arrays are empty.
- Renders two compact sections when records exist.

`ProfileTab.ets` imports and renders `RecentRecordsList({ profile: this.localProfile })` after the two recording forms.

## Error Handling

- Empty arrays render a friendly empty state.
- Empty notes are omitted from tongue detail.
- Non-positive limits return no rows.
- Unknown indicator names are still shown because they are user-entered labels.

## Testing

Add unit tests for:

- Recent indicator formatting and limit behavior.
- Recent tongue formatting with note text.
- Empty limit returning no rows.

## Verification

Run:

- `rg -n "RecentRecordsList|buildRecentIndicatorRecords|buildRecentTongueRecords" entry\src\main\ets entry\src\test`
- `hvigor test`
- `hvigor assembleHap`

If `hvigor` is unavailable, report the limitation.
