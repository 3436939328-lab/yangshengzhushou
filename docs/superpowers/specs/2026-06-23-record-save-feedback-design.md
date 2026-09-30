# Record Save Feedback Design

## Goal

Make local record forms feel complete by showing a clear success message after saving tongue notes or health indicators.

## Current Context

`TongueNoteForm` and `HealthIndicatorForm` already validate required input and clear the text value after saving. The recent records list now shows saved entries in `ProfileTab`, but the form itself does not confirm that a save succeeded.

## Scope

In scope:

- Add a success message to `TongueNoteForm`.
- Add a success message to `HealthIndicatorForm`.
- Clear success message when the user edits input or switches a choice.
- Keep existing validation and save callbacks.

Out of scope:

- Delete record actions.
- Edit record actions.
- Toast APIs or native notification APIs.
- Repository changes.

## Behavior

Tongue note form:

- Empty note still shows `请填写一条简短备注`.
- Successful save clears the note text.
- Successful save shows `舌象记录已保存`.
- Changing color, coating, dryness, or note clears the success message.

Health indicator form:

- Empty value still shows `请填写指标数值`.
- Successful save clears the value text.
- Successful save shows `健康指标已保存`.
- Changing type or value clears the success message.

## Architecture

Keep this as local UI state inside each form:

- `@State successText: string = ''`

Render `successText` below `errorText` with `BRAND_GREEN`. This avoids global event plumbing and keeps the feature scoped to the form components.

## Testing

ArkUI component state cannot be exercised in the current shell, so verification is static for this phase:

- `successText` exists in both forms.
- Success text literals exist.
- Input and chip handlers clear `successText`.

## Verification

Run:

- `rg -n "successText|舌象记录已保存|健康指标已保存" entry\src\main\ets\components\profile`
- `hvigor test`
- `hvigor assembleHap`

If `hvigor` is unavailable, report the limitation.
