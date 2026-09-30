# Privacy Settings Skeleton Design

## Goal

Add a visible privacy and data-safety section to the profile tab so users understand what health data is stored locally and which advanced capabilities are not enabled yet.

## Current Context

`getProfileActions()` includes `隐私设置`, but it is only a static action row. The app already stores sensitive wellness data locally: questionnaire results, tongue notes, health indicators, reminder preferences, and generated summaries. A health app should make this data boundary visible even before adding full settings flows.

## Scope

In scope:

- Add deterministic privacy status items.
- Add a profile card that explains current local-only behavior.
- Show privacy status in `ProfileTab`.
- Add unit tests for privacy status content.

Out of scope:

- Real permission requests.
- Cloud sync.
- Login/account.
- Export/download.
- Delete/clear all data.
- Legal policy document generation.

## Behavior

The card should show:

- Data location: local device storage.
- Cloud sync: not enabled.
- Device permissions: not requested in this phase.
- Data types: questionnaire, tongue notes, manual indicators, reminder preferences.

The card should use careful copy:

- Do not imply certified compliance.
- Do not claim encryption unless implemented.
- Do not imply cloud backup exists.
- Do not ask the user to grant permissions.

## Architecture

Add privacy content service:

- `PrivacyStatusItem` model in `WellnessModels.ets`.
- `getPrivacyStatusItems()` in a new `PrivacyService.ets`.
- `getPrivacySummary()` in `PrivacyService.ets`.

Add UI:

- `components/profile/PrivacyStatusCard.ets`.
- Import and render it in `ProfileTab.ets`, near the profile actions and reminder section.

## Error Handling

No async state or storage reads are required. This is deterministic static content, so failure handling is limited to rendering the predefined items.

## Testing

Add unit tests for:

- Privacy status includes local device storage.
- Privacy status includes cloud sync disabled.
- Privacy summary mentions local storage and no cloud sync.

## Verification

Run:

- `rg -n "PrivacyStatusCard|getPrivacyStatusItems|getPrivacySummary" entry\src\main\ets entry\src\test`
- `rg -n "云同步已开启|权限已授权|加密存储|合规认证" entry\src\main\ets entry\src\test`
- `hvigor test`
- `hvigor assembleHap`

If `hvigor` is unavailable, report the limitation.
