# Local Data Insights Design

## Goal

Make the data tab's risk summary and medical indicator interpretation use saved local health indicators when available, instead of always using fixed dashboard values.

## Current Context

`DataTab` already loads `HealthProfile` locally and prefers saved indicators for metric cards through `buildDisplayMetrics(profile, fallbackMetrics)`.

Two cards still use static values:

- `RiskCard` calls `summarizeHealthRisk(146, 94, 5.6, 6.5)`.
- `MedicalReportCard` renders `medicalReport` passed from the dashboard, which is also generated from fixed values.

This creates a mismatch: metric cards can show the user's saved blood pressure, glucose, or sleep, while the risk and report cards still describe mock values.

## Scope

In scope:

- Extract local vital values from `HealthProfile.healthIndicators`.
- Build a local `HealthRiskSummary`.
- Build a local `MedicalReportInterpretation`.
- Keep fallback behavior when no local indicators exist.
- Wire `DataTab` to render local insights.
- Add unit tests for local risk and local report behavior.

Out of scope:

- New charts or visual redesign.
- Real medical diagnosis.
- Device sync ingestion.
- Cloud sync.
- AI-generated interpretation.

## Local Insight Rules

Use deterministic daily-wellness rules:

- Default fallback values: systolic `118`, diastolic `76`, glucose `5.4`, sleep `7.2`.
- If an indicator name contains `血压` and value looks like `128/82`, parse systolic and diastolic.
- If an indicator name contains `血糖`, parse numeric glucose.
- If an indicator name contains `睡眠`, parse numeric sleep hours.
- Latest saved matching indicator wins because records are appended over time.
- If no local indicators exist, keep the existing dashboard medical report fallback.
- Risk summary uses the same `summarizeHealthRisk()` utility.
- Medical report uses the same `interpretMedicalIndicators()` service.

## Architecture

Add profile-to-insight helpers to `ProfileViewModel.ets`:

- `buildLocalHealthRisk(profile): HealthRiskSummary`
- `buildLocalMedicalReport(profile, fallbackReport): MedicalReportInterpretation`

These helpers reuse existing `summarizeHealthRisk()` and `interpretMedicalIndicators()` so the product keeps one interpretation rule set.

`DataTab.ets` will compute:

```ts
const risk = buildLocalHealthRisk(this.localProfile);
const localMedicalReport = buildLocalMedicalReport(this.localProfile, this.medicalReport);
```

and render `MedicalReportCard(localMedicalReport)`.

## Error Handling

- Unknown indicator names are ignored for risk/report calculation.
- Invalid numeric values fall back to defaults.
- Blood pressure values without `/` are ignored.
- Empty local indicators keep the existing dashboard report fallback.

## Testing

Add tests for:

- Local blood pressure produces a `需关注` risk.
- Local blood pressure produces abnormal medical report items.
- Empty profile keeps the passed fallback medical report.

## Verification

Run:

- `rg -n "buildLocalHealthRisk|buildLocalMedicalReport" entry\src\main\ets entry\src\test`
- `rg -n "summarizeHealthRisk\\(146, 94|MedicalReportCard\\(this.medicalReport\\)" entry\src\main\ets\components\tabs\DataTab.ets`
- `hvigor test`
- `hvigor assembleHap`

If `hvigor` is unavailable, report that limitation.
