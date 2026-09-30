# Page Architecture Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the current 966-line `Index.ets` into focused ArkTS theme, view model, component, tab, and card modules while preserving the current visible wellness assistant experience.

**Architecture:** `Index.ets` remains the entry page and owns only top-level UI state. New components render guide, header, tab bar, tabs, and cards. A dashboard view model gathers existing deterministic service data so UI modules no longer call every service directly.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, existing local services/utils, Hypium unit tests.

---

## File Structure

Create:

- `entry/src/main/ets/theme/WellnessTheme.ets`: shared color constants and small style constants.
- `entry/src/main/ets/viewmodel/WellnessDashboardViewModel.ets`: typed dashboard data assembly from existing services/utils.
- `entry/src/main/ets/components/GuideView.ets`: onboarding view.
- `entry/src/main/ets/components/AppHeader.ets`: title/subtitle/risk header.
- `entry/src/main/ets/components/TabBar.ets`: bottom tab selector.
- `entry/src/main/ets/components/tabs/HomeTab.ets`: home tab composition.
- `entry/src/main/ets/components/tabs/AssistantTab.ets`: AI assistant tab composition.
- `entry/src/main/ets/components/tabs/DataTab.ets`: data tab composition.
- `entry/src/main/ets/components/tabs/ProfileTab.ets`: profile tab composition.
- `entry/src/main/ets/components/cards/CommonCards.ets`: shared card builders and small repeated UI pieces.

Modify:

- `entry/src/main/ets/pages/Index.ets`: reduce to entry state and page composition.

Do not intentionally modify:

- `entry/src/main/ets/services/*.ets`
- `entry/src/main/ets/utils/*.ets`
- `entry/src/test/LocalUnit.test.ets`

## Task 1: Extract Theme Constants

**Files:**
- Create: `entry/src/main/ets/theme/WellnessTheme.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Create the theme module**

Create `entry/src/main/ets/theme/WellnessTheme.ets`:

```ts
export const BRAND_GREEN: string = '#2F7D57';
export const DEEP_TEXT: string = '#17231D';
export const MUTED_TEXT: string = '#66756D';
export const PAGE_BG: string = '#F6F8F5';
export const CARD_BG: string = '#FFFFFF';
export const LINE_BG: string = '#E4EBE6';
export const WARM_ACCENT: string = '#C7743D';

export const CARD_RADIUS: number = 8;
```

- [ ] **Step 2: Import theme constants in `Index.ets`**

Add:

```ts
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  LINE_BG,
  MUTED_TEXT,
  PAGE_BG,
  WARM_ACCENT
} from '../theme/WellnessTheme';
```

Remove the local constant declarations for the same color names from `Index.ets`.

- [ ] **Step 3: Replace card radius literals where safe**

Replace card-surface `.borderRadius(8)` with `.borderRadius(CARD_RADIUS)` in `Index.ets`. Leave pill/chip radii such as `14`, `10`, `4`, and `2` unchanged.

- [ ] **Step 4: Verify no local duplicate theme constants remain**

Run:

```powershell
rg -n "const BRAND_GREEN|const DEEP_TEXT|const MUTED_TEXT|const PAGE_BG|const CARD_BG|const LINE_BG|const WARM_ACCENT" entry\src\main\ets\pages\Index.ets
```

Expected: no matches.

- [ ] **Step 5: Verify existing tests or record tooling limitation**

Run:

```powershell
hvigor test
```

Expected: tests pass. If `hvigor` is unavailable, record the exact `CommandNotFoundException`.

## Task 2: Add Dashboard View Model

**Files:**
- Create: `entry/src/main/ets/viewmodel/WellnessDashboardViewModel.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Create dashboard data types**

Create `entry/src/main/ets/viewmodel/WellnessDashboardViewModel.ets`:

```ts
import {
  ArchiveSummary,
  DeviceStatus,
  GuideSlide,
  HealthMetric,
  MedicalReportInterpretation,
  MonthlyReport,
  PersonalPlan,
  ProfileAction,
  QuickAction,
  ReminderItem,
  SolarTermInfo,
  WeatherWellness,
  WellnessPlan
} from '../model/WellnessModels';
import { getDeviceStatuses } from '../services/DeviceService';
import { getArchiveSummaries } from '../services/HealthDataService';
import { generatePersonalPlan } from '../services/PersonalPlanService';
import { generateMonthlyReport, interpretMedicalIndicators } from '../services/ReportService';
import {
  getDailyPlans,
  getGuideSlides,
  getHealthMetrics,
  getProfileActions,
  getQuickActions,
  getReminderItems,
  getWeatherWellness
} from '../services/WellnessContentService';
import { getCurrentSolarTerm } from '../utils/SolarTermUtil';

export interface WellnessDashboardData {
  guideSlides: GuideSlide[];
  weather: WeatherWellness;
  solarTerm: SolarTermInfo;
  plans: WellnessPlan[];
  quickActions: QuickAction[];
  metrics: HealthMetric[];
  devices: DeviceStatus[];
  personalPlan: PersonalPlan;
  medicalReport: MedicalReportInterpretation;
  monthlyReport: MonthlyReport;
  archiveSummaries: ArchiveSummary[];
  profileActions: ProfileAction[];
  reminders: ReminderItem[];
}

export function createWellnessDashboardData(): WellnessDashboardData {
  return {
    guideSlides: getGuideSlides(),
    weather: getWeatherWellness(),
    solarTerm: getCurrentSolarTerm(),
    plans: getDailyPlans(),
    quickActions: getQuickActions(),
    metrics: getHealthMetrics(),
    devices: getDeviceStatuses(),
    personalPlan: generatePersonalPlan('气虚质', '控糖', 6.5),
    medicalReport: interpretMedicalIndicators(146, 94, 5.6, 6.5),
    monthlyReport: generateMonthlyReport(18, 3, '气虚质'),
    archiveSummaries: getArchiveSummaries(),
    profileActions: getProfileActions(),
    reminders: getReminderItems()
  };
}
```

- [ ] **Step 2: Use the view model in `Index.ets`**

Import:

```ts
import { createWellnessDashboardData, WellnessDashboardData } from '../viewmodel/WellnessDashboardViewModel';
```

Add:

```ts
private dashboard: WellnessDashboardData = createWellnessDashboardData();
```

Replace direct fields:

```ts
this.guideSlides -> this.dashboard.guideSlides
this.weather -> this.dashboard.weather
this.solarTerm -> this.dashboard.solarTerm
this.plans -> this.dashboard.plans
this.metrics -> this.dashboard.metrics
this.devices -> this.dashboard.devices
this.personalPlan -> this.dashboard.personalPlan
this.medicalReport -> this.dashboard.medicalReport
this.monthlyReport -> this.dashboard.monthlyReport
```

Replace direct service calls in UI:

```ts
getQuickActions() -> this.dashboard.quickActions
getArchiveSummaries() -> this.dashboard.archiveSummaries
getProfileActions() -> this.dashboard.profileActions
getReminderItems() -> this.dashboard.reminders
```

- [ ] **Step 3: Remove now-unused imports from `Index.ets`**

Remove direct imports for services now handled by the view model:

```ts
getDeviceStatuses
getArchiveSummaries
generatePersonalPlan
generateMonthlyReport
interpretMedicalIndicators
getDailyPlans
getGuideSlides
getHealthMetrics
getProfileActions
getQuickActions
getReminderItems
getWeatherWellness
getCurrentSolarTerm
```

Keep imports still used directly by builders, such as `getDeviceSyncSummary`, `buildHealthArchiveSummary`, `formatReminderSummary`, `generateHealthAnswer`, `searchAcupoints`, `searchFoodContraindications`, `searchHerbalRecipes`, `calculateConstitution`, `summarizeHealthRisk`, and `recommendByProfile`.

- [ ] **Step 4: Verify dashboard wiring**

Run:

```powershell
rg -n "getQuickActions|getArchiveSummaries|getProfileActions|getReminderItems|getGuideSlides|getDailyPlans|getHealthMetrics|getWeatherWellness|getCurrentSolarTerm|generatePersonalPlan|generateMonthlyReport|interpretMedicalIndicators|getDeviceStatuses" entry\src\main\ets\pages\Index.ets
```

Expected: no matches.

## Task 3: Extract Entry Shell Components

**Files:**
- Create: `entry/src/main/ets/components/GuideView.ets`
- Create: `entry/src/main/ets/components/AppHeader.ets`
- Create: `entry/src/main/ets/components/TabBar.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Extract `GuideView`**

Create `GuideView.ets` as a component that receives:

```ts
@Link guideIndex: number;
@Link hasEnteredApp: boolean;
@Prop guideSlides: GuideSlide[];
```

Move the current `GuideView()` builder body from `Index.ets` into this component's `build()`.

- [ ] **Step 2: Extract `AppHeader`**

Create `AppHeader.ets` as a component that receives:

```ts
@Prop riskLevel: string;
```

Move the current `Header()` builder body into this component's `build()`.

- [ ] **Step 3: Extract `TabBar`**

Create `TabBar.ets` as a component that receives:

```ts
@Link currentTab: number;
@Prop tabTitles: string[];
```

Move the current `TabBar()` builder body into this component's `build()`.

- [ ] **Step 4: Replace shell builders in `Index.ets`**

Import the new components:

```ts
import { GuideView } from '../components/GuideView';
import { AppHeader } from '../components/AppHeader';
import { WellnessTabBar } from '../components/TabBar';
```

Use:

```ts
GuideView({
  guideIndex: $guideIndex,
  hasEnteredApp: $hasEnteredApp,
  guideSlides: this.dashboard.guideSlides
})

AppHeader({ riskLevel: this.dashboard.weather.riskLevel })

WellnessTabBar({
  currentTab: $currentTab,
  tabTitles: this.tabTitles
})
```

Remove `GuideView()`, `Header()`, and `TabBar()` builders from `Index.ets`.

- [ ] **Step 5: Verify shell extraction**

Run:

```powershell
rg -n "@Builder\\s*(GuideView|Header|TabBar)|this\\.GuideView\\(|this\\.Header\\(|this\\.TabBar\\(" entry\src\main\ets\pages\Index.ets
```

Expected: no matches.

## Task 4: Extract Tab Components

**Files:**
- Create: `entry/src/main/ets/components/tabs/HomeTab.ets`
- Create: `entry/src/main/ets/components/tabs/AssistantTab.ets`
- Create: `entry/src/main/ets/components/tabs/DataTab.ets`
- Create: `entry/src/main/ets/components/tabs/ProfileTab.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Extract `HomeTab`**

Create `HomeTab.ets` with props:

```ts
@Prop weather: WeatherWellness;
@Prop solarTerm: SolarTermInfo;
@Prop personalPlan: PersonalPlan;
@Prop plans: WellnessPlan[];
@Prop quickActions: QuickAction[];
```

Move `HomeTab`, `WeatherCard`, `SolarTermCard`, `PersonalPlanCard`, `PlanSegmentLine`, and `PlanRow` builders from `Index.ets` into the component or local builders in `HomeTab.ets`.

- [ ] **Step 2: Extract `AssistantTab`**

Create `AssistantTab.ets` with:

```ts
@Link questionnaireScore: number;
```

Move `AssistantTab`, `RecommendationCard`, `GeneratedAnswerCard`, `KnowledgeCards`, `KnowledgeLine`, `ActionChip`, and `SectionTitle` usage needed by this tab. This component may continue calling assistant-specific services/utils directly:

```ts
getAssistantMessages
generateHealthAnswer
searchHerbalRecipes
searchFoodContraindications
searchAcupoints
calculateConstitution
recommendByProfile
```

- [ ] **Step 3: Extract `DataTab`**

Create `DataTab.ets` with props:

```ts
@Prop medicalReport: MedicalReportInterpretation;
@Prop metrics: HealthMetric[];
@Prop personalPlan: PersonalPlan;
@Prop devices: DeviceStatus[];
```

Move `DataTab`, `RiskCard`, `MedicalReportCard`, `MetricCard`, `SleepAnalysisCard`, and `DeviceSyncCard` builders. This component may call `summarizeHealthRisk` and `getDeviceSyncSummary`.

- [ ] **Step 4: Extract `ProfileTab`**

Create `ProfileTab.ets` with props:

```ts
@Prop questionnaireScore: number;
@Prop metricCount: number;
@Prop archiveSummaries: ArchiveSummary[];
@Prop monthlyReport: MonthlyReport;
@Prop profileActions: ProfileAction[];
@Prop reminders: ReminderItem[];
```

Move `ProfileTab` and `MonthlyReportCard` if it is not already shared. This component may call `calculateConstitution`, `buildHealthArchiveSummary`, and `formatReminderSummary`.

- [ ] **Step 5: Replace tab rendering in `Index.ets`**

Import:

```ts
import { HomeTab } from '../components/tabs/HomeTab';
import { AssistantTab } from '../components/tabs/AssistantTab';
import { DataTab } from '../components/tabs/DataTab';
import { ProfileTab } from '../components/tabs/ProfileTab';
```

Replace the current `this.HomeTab()` / `this.AssistantTab()` / `this.DataTab()` / `this.ProfileTab()` calls with component instantiation and explicit props.

- [ ] **Step 6: Verify tab builders are removed from `Index.ets`**

Run:

```powershell
rg -n "@Builder\\s*(HomeTab|AssistantTab|DataTab|ProfileTab|WeatherCard|SolarTermCard|PersonalPlanCard|PlanRow|RiskCard|MetricCard|DeviceSyncCard|KnowledgeCards|RecommendationCard)" entry\src\main\ets\pages\Index.ets
```

Expected: no matches.

## Task 5: Extract Shared Card Helpers

**Files:**
- Create: `entry/src/main/ets/components/cards/CommonCards.ets`
- Modify: `entry/src/main/ets/components/tabs/HomeTab.ets`
- Modify: `entry/src/main/ets/components/tabs/AssistantTab.ets`
- Modify: `entry/src/main/ets/components/tabs/DataTab.ets`
- Modify: `entry/src/main/ets/components/tabs/ProfileTab.ets`

- [ ] **Step 1: Create `SectionTitle` and `ActionChip` shared helpers**

Create `CommonCards.ets` with:

```ts
import { BRAND_GREEN, DEEP_TEXT, MUTED_TEXT } from '../../theme/WellnessTheme';

@Builder
export function SectionTitle(title: string) {
  Text(title)
    .fontSize(18)
    .fontWeight(FontWeight.Bold)
    .fontColor(DEEP_TEXT)
    .width('100%')
    .margin({ top: 4 })
}

@Builder
export function ActionChip(label: string) {
  Text(label)
    .fontSize(12)
    .fontColor(BRAND_GREEN)
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .backgroundColor('#EEF7F1')
    .borderRadius(14)
}
```

- [ ] **Step 2: Use shared helpers in tab components**

Replace local or duplicated section/chip builders with:

```ts
SectionTitle('健康数据')
ActionChip('舌诊自测')
```

- [ ] **Step 3: Move small reusable report cards if duplication exists**

If `MonthlyReportCard`, `GeneratedAnswerCard`, or other small card builders are duplicated across tab files, move them into `CommonCards.ets`. If each card is used by only one tab, keep it local to avoid premature abstraction.

- [ ] **Step 4: Verify shared helper imports**

Run:

```powershell
rg -n "SectionTitle|ActionChip" entry\src\main\ets\components
```

Expected: usages are in tab components and definitions are in `components/cards/CommonCards.ets`.

## Task 6: Final Verification And Cleanup

**Files:**
- Inspect all new and modified files.

- [ ] **Step 1: Verify `Index.ets` is reduced to composition**

Run:

```powershell
(Get-Content entry\src\main\ets\pages\Index.ets).Count
```

Expected: substantially lower than 966 lines. A target under 180 lines is preferred.

- [ ] **Step 2: Verify new files exist**

Run:

```powershell
Test-Path entry\src\main\ets\theme\WellnessTheme.ets
Test-Path entry\src\main\ets\viewmodel\WellnessDashboardViewModel.ets
Test-Path entry\src\main\ets\components\GuideView.ets
Test-Path entry\src\main\ets\components\AppHeader.ets
Test-Path entry\src\main\ets\components\TabBar.ets
Test-Path entry\src\main\ets\components\tabs\HomeTab.ets
Test-Path entry\src\main\ets\components\tabs\AssistantTab.ets
Test-Path entry\src\main\ets\components\tabs\DataTab.ets
Test-Path entry\src\main\ets\components\tabs\ProfileTab.ets
Test-Path entry\src\main\ets\components\cards\CommonCards.ets
```

Expected: all output lines are `True`.

- [ ] **Step 3: Search for mojibake**

Run:

```powershell
rg -n "鏃|鍏|姘|琛|鐫|鍋|宸|榛|绁|瓒|灏|鎺|骞|棣|闂|浣|椋|鏈|杩|妗|鎻|浠|婀|澶|瀛|鈩|銆|€" entry\src\main\ets entry\src\test
```

Expected: no matches.

- [ ] **Step 4: Search for malformed interpolation**

Run:

```powershell
rg -n "\\?\\{|锛|鈥|濓|Text\\(`[^`]*\\{[A-Za-z_]" entry\src\main\ets
```

Expected: no matches that indicate broken template interpolation or mojibake.

- [ ] **Step 5: Run tests**

Run:

```powershell
hvigor test
```

Expected: tests pass. If unavailable, record the exact `CommandNotFoundException`.

- [ ] **Step 6: Run build**

Run:

```powershell
hvigor assembleHap
```

Expected: build succeeds. If unavailable, record the exact `CommandNotFoundException`.

- [ ] **Step 7: Check git status**

Run:

```powershell
git status --short
```

Expected: if this workspace is not a git repository, record that commits/diffs cannot be produced.

## Self-Review Notes

- Spec coverage: This plan extracts theme, view model, shell components, tab components, and shared helpers while keeping services/utils stable and preserving visual behavior.
- Scope control: The plan does not add APIs, login, persistence, device SDKs, camera capture, notification scheduling, or new product workflows.
- Type consistency: All referenced model names come from `WellnessModels.ets`; all proposed services already exist.
- Verification limitation: The current shell has previously lacked `hvigor`, so the plan records exact command failures when tooling is unavailable.
