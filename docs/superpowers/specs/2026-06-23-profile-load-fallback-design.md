# Profile Load Fallback Design

## Goal

Show a consistent, lightweight notice when loading the local health profile fails, while keeping the app usable with the default local profile.

## Current Context

Four tabs load `HealthProfile` through `createPreferencesHealthProfileRepository(context)`:

- `HomeTab`
- `AssistantTab`
- `DataTab`
- `ProfileTab`

Each currently calls `loadProfile().then(...)` without a `.catch(...)`. If Preferences read fails, the UI may silently keep defaults without explaining why local records are missing.

## Scope

In scope:

- Add a shared load-fallback empty-state copy.
- Add a small `LoadStateNotice` UI component.
- Add `profileLoadError` state to the four tabs.
- On `loadProfile()` failure, keep default profile and show the notice.
- Add unit tests for the new empty-state copy.

Out of scope:

- Retry buttons.
- Logging infrastructure.
- Repository API changes.
- Save failure handling.
- Global error boundary.

## Behavior

When profile loading succeeds:

- `profileLoadError` is empty.
- No notice is shown.

When profile loading fails:

- The tab keeps `createDefaultHealthProfile()` state.
- `profileLoadError` is set to the shared detail text.
- The tab renders a compact notice near the top of its content.

Copy:

- Title: `本地档案暂不可用`
- Detail: `已使用默认档案继续展示，稍后重新进入页面可再次尝试读取本地记录。`

## Architecture

Extend `EmptyStateService.ets` with key:

- `profileLoad`

Create `components/cards/LoadStateNotice.ets`:

- Receives `message: string`.
- Renders nothing if the message is empty.
- Renders the shared title/detail if message exists.

Update each tab:

- Add `@State profileLoadError: string = ''`.
- On successful load, clear the error.
- On failed load, set error to `getEmptyStateInfo('profileLoad').detail`.
- Render `LoadStateNotice({ message: this.profileLoadError })` near the top.

## Testing

Add unit test:

- `getEmptyStateInfo('profileLoad')` returns the expected title and mentions default profile.

UI catch wiring is verified by static search because component lifecycle is not executable in the current shell.

## Verification

Run:

- `rg -n "profileLoadError|LoadStateNotice|getEmptyStateInfo\\('profileLoad'\\)" entry\src\main\ets entry\src\test`
- `rg -n "\\.catch\\(.*profileLoadError|profileLoadError" entry\src\main\ets\components\tabs`
- `hvigor test`
- `hvigor assembleHap`

If `hvigor` is unavailable, report the limitation.
