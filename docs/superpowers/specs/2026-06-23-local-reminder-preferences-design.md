# Local Reminder Preferences Design

## Goal

Turn the profile reminder section from static mock display into locally saved reminder preferences.

This phase lets users toggle reminder preferences in the profile tab and persists those choices in the local health profile.

## Current State

The app already has:

- `ReminderPreference` in `ProfileModels.ets`.
- `HealthProfile.reminderPreferences`.
- Default reminder preferences in `createDefaultHealthProfile()`.
- `HealthProfileRepository.updateReminderPreferences()`.
- A profile tab reminder list that still reads mock `ReminderItem[]` from the dashboard.

The gap is that reminder toggles do not update or persist local profile state.

## Scope

This phase includes:

- Rendering reminders from `localProfile.reminderPreferences`.
- Toggling a reminder on or off.
- Saving updated preferences through `ProfileRepository.updateReminderPreferences()`.
- Refreshing profile summary and reminder summary from saved local state.
- Tests for reminder count and preference toggling.

This phase does not include:

- System notification scheduling.
- Background tasks.
- Permission prompts.
- Cloud sync.
- Login or account binding.

## Architecture

Use the existing local profile repository:

- `ProfileTab` owns loaded `localProfile`.
- Reminder rows read from `localProfile.reminderPreferences`.
- Toggle changes create a new preference array and call `updateReminderPreferences()`.
- The returned profile replaces `localProfile`.

Add pure helpers to `ProfileViewModel` if needed:

- `countEnabledReminderPreferences(profile)`
- `toggleReminderPreference(profile, title, enabled)`

The helper should not touch storage or ArkUI.

## User Flow

1. The user opens 我的.
2. The app loads local profile.
3. Reminder rows show saved enabled/disabled state.
4. The user toggles a reminder.
5. The app saves updated preferences locally.
6. Summary text updates from the saved profile.

## Error Handling

- If saving fails, keep the visible state unchanged and show a concise error message.
- If no local profile exists, default reminder preferences render.
- If the target reminder title is unknown, no preference is changed.

## UI Direction

- Keep the existing reminder row style.
- Use the existing HarmonyOS `Toggle`.
- Do not add scheduling copy or notification permission UI.
- The summary remains compact: `已开启2/3个提醒`.

## Testing

Unit tests should cover:

- Counting enabled reminder preferences.
- Toggling one reminder off.
- Toggling one reminder on.
- Unknown reminder title leaves preferences unchanged.

Verification should include:

- `hvigor test`
- `hvigor assembleHap`
- Static search for notification scheduling, permission, cloud, or login claims.
- Static search for mojibake and malformed interpolation.

If `hvigor` remains unavailable in the local shell, record the exact command failure.

## Migration Strategy

1. Add view-model tests for reminder preference helpers.
2. Add helper functions to `ProfileViewModel`.
3. Update `ProfileTab` reminder summary and rows to use `localProfile.reminderPreferences`.
4. Wire Toggle changes to repository saves.
5. Run static and toolchain verification.
