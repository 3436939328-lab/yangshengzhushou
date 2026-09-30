# Real Permission Status Design

## Goal

Replace the static "设备权限未请求" privacy copy with real permission status display. The app should show whether relevant permissions are granted, not granted, not configured, or not currently used, without requesting new permissions on page load.

## Scope

This milestone covers status display only:

- Location permission for weather.
- Camera permission reserved for future tongue photo capture.
- Notification permission for reminders.
- Bluetooth/device permissions reserved for future device management.

It does not implement device pairing, cloud sync, account login, data upload, or automatic health device data import.

## Current State

`PrivacyService.ets` returns static privacy rows. It says cloud sync is disabled and device permissions are not requested. `PrivacyStatusCard.ets` renders those static rows. `WeatherService.ets` already requests location permission when loading located weather, so the static "未请求" copy can become inaccurate.

## Design

Add a permission status service that can build privacy status items from observed permission state.

The service should expose:

- A local fallback function that returns conservative static rows when runtime permission APIs cannot be used.
- A runtime function that accepts a `UIAbilityContext`, checks permission state, and returns `PrivacyStatusItem[]`.

The UI should:

- Render fallback rows immediately.
- Load runtime permission rows in `aboutToAppear`.
- Never request permissions from this card.
- Keep cloud sync and device management marked as not connected/not enabled.

## Status Labels

Use these labels:

- `已授权`: permission is granted.
- `未授权`: permission is declared or checkable but not granted.
- `未配置`: permission is not configured or cannot be checked in this build.
- `当前未使用`: capability is planned but no permission is currently requested by this feature.
- `未开启`: cloud sync remains disabled.

## Rows

The privacy card should show:

- Data location: local app storage.
- Cloud sync: disabled.
- Location permission: real status, used for weather.
- Camera permission: planned for tongue photos, currently not used if unavailable.
- Notification permission: used for reminders when configured.
- Device/Bluetooth permission: planned for device management, currently not connected.
- Data scope: questionnaire, tongue text, manual indicators, reminder preferences.

## Error Handling

If permission checking fails, keep fallback rows and show a safe status such as `未配置` or `当前未使用`. The card must not crash or block the profile page.

## Testing

Unit-test pure row builders by injecting permission states. Runtime permission API calls can stay thin wrappers so they are easy to inspect manually in DevEco/Hvigor builds.

## Out Of Scope

- Prompting for permissions from the privacy card.
- Bluetooth scanning or device pairing.
- Cloud backup or account login.
- Camera capture for tongue photos.
