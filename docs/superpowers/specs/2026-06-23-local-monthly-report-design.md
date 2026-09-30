# Local Monthly Report Design

## Goal

Make the profile monthly report reflect the user's saved local records instead of a fixed mock report. This moves the app closer to a complete offline-first wellness loop: questionnaire, tongue notes, manual indicators, reminders, contextual assistant, and now local report review.

## Current Context

The app already persists a `HealthProfile` with questionnaire records, tongue observation notes, health indicators, and reminder preferences. `ProfileTab` loads this profile locally and refreshes it when the user saves new tongue or indicator entries.

The remaining gap is the monthly report card. It still receives a static `MonthlyReport` from `WellnessDashboardViewModel`, generated with fixed values such as 18 active days and 3 abnormal signals. That makes the report feel disconnected from records the user just saved.

## Scope

This phase adds deterministic local report generation only.

In scope:

- Generate a `MonthlyReport` from `HealthProfile`.
- Count active record days from questionnaire, tongue, and indicator records.
- Count attention signals from locally saved indicators and tongue notes.
- Prefer local report data in `ProfileTab`.
- Keep the existing `generateMonthlyReport(activeDays, abnormalCount, constitution)` API for compatibility.
- Add unit coverage for local report generation.

Out of scope:

- Real medical diagnosis.
- Cloud sync.
- AI-generated long reports.
- Device ingestion.
- PDF export or sharing.

## Report Rules

The local report uses simple, explainable rules:

- Active days are unique calendar dates across questionnaire submissions, tongue notes, and health indicator entries.
- Attention signals include:
  - Blood pressure entries whose systolic value is at least 140 or diastolic value is at least 90.
  - Blood glucose entries whose numeric value is at least 7.0.
  - Sleep entries whose numeric value is below 7.
  - Tongue notes with dryness marked dry or coating marked thick/yellow.
- Constitution comes from `profile.constitution.name`.
- If no records exist, the report says this month has no local records yet and suggests completing questionnaire plus one daily record.
- The report includes a non-diagnostic daily wellness suggestion, not clinical advice.

## Architecture

`ReportService.ets` remains responsible for report generation. It will import `HealthProfile` and expose:

- `generateMonthlyReport(activeDays, abnormalCount, constitution)` for existing dashboard mock data.
- `generateLocalMonthlyReport(profile)` for saved local profile data.

`ProfileTab.ets` will compute:

```ts
const localMonthlyReport = generateLocalMonthlyReport(this.localProfile);
```

and pass that report into the existing `MonthlyReportCard`. This keeps the UI change small and avoids adding another state field.

## Data Flow

1. `ProfileTab` loads `HealthProfile` from `ProfileRepository`.
2. User saves a questionnaire, tongue note, health indicator, or reminder preference.
3. Repository returns the updated profile.
4. `ProfileTab` updates `localProfile`.
5. `generateLocalMonthlyReport(localProfile)` recalculates the report during render.

## Error Handling

The report generator is pure and defensive:

- Empty arrays produce a useful zero-state report.
- Missing or unrecognized indicator names are counted as records but not attention signals.
- Unparseable numeric values are ignored for abnormal counting.
- Invalid dates fall back to the full timestamp string so records still count deterministically.

## Testing

Add unit tests for:

- Empty profile report.
- Active day counting across multiple record types.
- Attention signal detection for blood pressure, glucose, sleep, and tongue note.
- `ProfileTab` static dependency removal can be checked by static search because ArkUI rendering is not available in this shell.

## Verification

Run the available static checks and attempt HarmonyOS commands:

- `rg -n "generateLocalMonthlyReport" entry\src\main\ets entry\src\test`
- `rg -n "monthlyReport:" entry\src\main\ets\pages\Index.ets entry\src\main\ets\components\tabs\ProfileTab.ets`
- `hvigor test`
- `hvigor assembleHap`

If `hvigor` is not installed in the current shell, report that limitation clearly.
