# Basic Experience Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore readable Chinese content and improve the first visible HarmonyOS wellness assistant experience without changing the app's core architecture.

**Architecture:** Keep the current ArkTS service-first structure. Update deterministic mock services and utility outputs first, then update the `Index.ets` UI text and small hierarchy details, then align Hypium unit tests with the corrected behavior.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, Hypium unit tests, local mock services.

---

## File Structure

- Modify `entry/src/main/ets/services/WellnessContentService.ets`: restore onboarding, weather, home plan, quick action, assistant message, health metric, profile action, and reminder text.
- Modify `entry/src/main/ets/services/AIService.ets`: restore safe AI answer copy and default question copy.
- Modify `entry/src/main/ets/services/DeviceService.ets`: restore device names, types, statuses, and sync summary.
- Modify `entry/src/main/ets/services/HealthDataService.ets`: restore archive summary and archive cards.
- Modify `entry/src/main/ets/services/KnowledgeService.ets`: restore recipes, contraindications, acupoints, and searchable keywords.
- Modify `entry/src/main/ets/services/NotificationService.ets`: restore reminder summary copy.
- Modify `entry/src/main/ets/services/PersonalPlanService.ets`: restore personalized diet, exercise, and sleep plan copy.
- Modify `entry/src/main/ets/services/ReportService.ets`: restore medical indicator names, statuses, advice, summary, and monthly report copy.
- Modify `entry/src/main/ets/utils/ConstitutionUtil.ets`: restore constitution names and suggestions.
- Modify `entry/src/main/ets/utils/RecommendationUtil.ets`: restore recipe, acupoint, and disclaimer copy.
- Modify `entry/src/main/ets/utils/HealthRiskUtil.ets`: restore health risk levels, summaries, and action copy.
- Modify `entry/src/main/ets/utils/SolarTermUtil.ets`: restore solar term names, foods, focus, and routine copy.
- Modify `entry/src/main/ets/pages/Index.ets`: restore visible labels and correct string interpolation mistakes in UI builders.
- Modify `entry/src/test/LocalUnit.test.ets`: update unit tests to assert corrected Chinese outputs.

## Task 1: Update Test Expectations First

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Replace garbled expected values with readable Chinese**

Update these assertions:

```ts
expect(result.name).assertEqual('气虚质');
expect(result.suggestion).assertContain('温和运动');
expect(result.name).assertEqual('夏至');
expect(result.focus).assertContain('养心');
expect(result.recipe.name).assertEqual('黄芪山药粥');
expect(result.acupoint.name).assertEqual('足三里');
expect(result.warning).assertContain('不替代诊疗');
expect(result.level).assertEqual('需关注');
expect(result.message).assertContain('血压');
expect(result).assertContain('气虚质');
expect(result).assertContain('不能替代医生诊断');
expect(result).assertContain('4项指标');
expect(result).assertContain('气虚质');
expect(result).assertEqual('已连接3台设备，1台待同步');
expect(result).assertEqual('已开启2/3个提醒');
expect(result[0].name).assertEqual('黄芪山药粥');
expect(result[0].warning).assertContain('谨慎');
expect(result[0].name).assertEqual('神门');
expect(result.diet.title).assertEqual('控糖健脾餐');
expect(result.exercise.detail).assertContain('八段锦');
expect(result.sleep.detail).assertContain('固定入睡时间');
expect(result.abnormalItems[0].name).assertEqual('收缩压');
expect(result.summary).assertContain('2项异常');
expect(result.title).assertEqual('月度养生报告');
expect(result.summary).assertContain('18天');
expect(result.suggestion).assertContain('气虚质');
```

- [ ] **Step 2: Run tests or record local limitation**

Run:

```powershell
hvigor test
```

Expected before implementation: tests fail because the app code still returns garbled text, or the command is unavailable in the local environment. If unavailable, record the exact error in the final verification notes.

## Task 2: Restore Service and Utility Text

**Files:**
- Modify: `entry/src/main/ets/services/AIService.ets`
- Modify: `entry/src/main/ets/services/DeviceService.ets`
- Modify: `entry/src/main/ets/services/HealthDataService.ets`
- Modify: `entry/src/main/ets/services/KnowledgeService.ets`
- Modify: `entry/src/main/ets/services/NotificationService.ets`
- Modify: `entry/src/main/ets/services/PersonalPlanService.ets`
- Modify: `entry/src/main/ets/services/ReportService.ets`
- Modify: `entry/src/main/ets/utils/ConstitutionUtil.ets`
- Modify: `entry/src/main/ets/utils/RecommendationUtil.ets`
- Modify: `entry/src/main/ets/utils/HealthRiskUtil.ets`
- Modify: `entry/src/main/ets/utils/SolarTermUtil.ets`

- [ ] **Step 1: Replace AI response copy**

Use this behavior:

```ts
const normalizedQuestion = question.trim().length > 0 ? question.trim() : '日常调理';
return `针对“${normalizedQuestion}”，当前体质倾向为${constitution}。建议先从规律作息、清淡饮食和温和运动入手，持续记录症状变化。本建议不能替代医生诊断，若症状持续、加重或伴随明显疼痛，请及时就医。`;
```

- [ ] **Step 2: Replace constitution outputs**

Use:

```ts
name: '平和质'
suggestion: '保持规律作息，饮食有节，继续维持稳定状态。'
name: '气虚质'
suggestion: '优先补气健脾，选择温和运动，避免过度劳累。'
```

- [ ] **Step 3: Replace health and report outputs**

Use readable medical labels:

```ts
'收缩压'
'舒张压'
'空腹血糖'
'睡眠时长'
'偏高'
'正常'
'不足'
```

Use summary copy:

```ts
`本次解读发现${abnormalItems.length}项异常，${normalItems.length}项处于参考范围。`
`本月记录${activeDays}天，发现${abnormalCount}类需要持续关注的健康信号。`
`结合${constitution}倾向，建议继续保持温和运动、规律饮食和睡眠修复。`
```

- [ ] **Step 4: Replace knowledge and recommendation outputs**

Use these stable seed names and keywords:

```ts
'黄芪山药粥'
'莲子百合饮'
'薏米赤豆汤'
'神门'
'足三里'
'合谷'
'气虚质'
'阴虚质'
'痰湿质'
'孕期'
'失眠'
'困倦'
```

Keep the disclaimer:

```ts
'以上建议用于日常养生参考，不替代诊疗；明显不适请及时就医。'
```

- [ ] **Step 5: Replace solar term outputs**

Use:

```ts
'芒种'
'夏至'
'小暑'
'清暑祛湿，健脾护胃'
'养心安神，清热生津'
'防暑化湿，少贪寒凉'
```

- [ ] **Step 6: Run targeted text search**

Run:

```powershell
rg -n "鏃|鍏|姘|琛|鐫|鍋|宸|榛|绁|瓒|灏|鎺|骞|闂|浣|椋|鏈|杩|妗|鎻|婀|澶|瀛|鈩|銆|€" entry\src\main\ets\services entry\src\main\ets\utils
```

Expected: no garbled Chinese remains in services or utils.

## Task 3: Restore Page Labels and UI Copy

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Replace top-level labels**

Use:

```ts
private tabTitles: string[] = ['首页', 'AI助手', '数据', '我的'];
private personalPlan: PersonalPlan = generatePersonalPlan('气虚质', '控糖', 6.5);
private monthlyReport: MonthlyReport = generateMonthlyReport(18, 3, '气虚质');
```

Visible app title and subtitle:

```ts
'养生助手'
'AI驱动的中医养生与健康管理平台'
```

- [ ] **Step 2: Replace home tab labels**

Use:

```ts
'今日方案'
'快捷入口'
'湿度'
`适宜：${this.solarTerm.foods.join('、')}`
'个性化调理计划'
'饮食'
'运动'
'睡眠'
```

- [ ] **Step 3: Replace assistant tab labels and sample question**

Use:

```ts
'AI健康问答'
const recommendation = recommendByProfile(constitution.name, '困倦');
const generatedAnswer = generateHealthAnswer('最近困倦、胃口一般', constitution.name);
const contraindications = searchFoodContraindications('孕期');
const acupoints = searchAcupoints('失眠');
`问卷初筛：${constitution.name}`
`当前分值 ${this.questionnaireScore}`
'舌诊自测'
'AI安全回复'
'本地知识库'
'药膳'
'宜忌'
'穴位'
'食疗与穴位建议'
```

- [ ] **Step 4: Replace data/profile tab labels**

Use:

```ts
'健康数据'
'睡眠分析'
'健康档案'
'提醒管理'
'体检指标解读'
'月度养生报告'
'风险摘要'
```

- [ ] **Step 5: Fix string interpolation bugs**

Ensure every interpolation uses `${...}` correctly, including:

```ts
Text(`适宜：${this.solarTerm.foods.join('、')}`)
Text(`问卷初筛：${constitution.name}`)
Text(`${item.value} · 参考 ${item.reference}`)
Text(`${device.type} · ${device.lastSync}`)
Text(`${plan.recipe.name}：${plan.recipe.ingredients}`)
Text(`${plan.acupoint.name}：${plan.acupoint.method}`)
```

- [ ] **Step 6: Replace status comparisons**

Use readable status comparisons:

```ts
device.status === '已同步'
risk.level === '平稳'
```

## Task 4: Home Experience Polish

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/services/WellnessContentService.ets`

- [ ] **Step 1: Shorten home card copy**

Keep each quick action description under 16 Chinese characters:

```ts
{ title: '体质问卷', description: '快速判断调理方向' }
{ title: '舌诊自测', description: '记录舌象特征' }
{ title: '食疗药膳', description: '按体质匹配茶饮' }
{ title: '穴位理疗', description: '常见不适居家按揉' }
```

- [ ] **Step 2: Make daily plan copy concise**

Use:

```ts
'晨间养气'
'八段锦8分钟，配合鼻吸口呼。'
'午后清心'
'莲子百合饮，减少冰饮和辛辣。'
'睡前安神'
'温水泡脚15分钟，按揉神门穴。'
```

- [ ] **Step 3: Keep visual styling restrained**

Do not introduce new colors beyond the current constants and existing pale green/warm backgrounds. Keep card radius at `8`.

## Task 5: Verify and Clean Up

**Files:**
- Inspect all modified files.

- [ ] **Step 1: Search for remaining garbled text**

Run:

```powershell
rg -n "鏃|鍏|姘|琛|鐫|鍋|宸|榛|绁|瓒|灏|鎺|骞|棣|闂|浣|椋|鏈|杩|妗|鎻|浠|婀|澶|瀛|鈩|銆|€" entry\src\main\ets entry\src\test
```

Expected: no matches that represent mojibake. Real Chinese characters such as `养`, `生`, `健康`, `血压`, `睡眠`, `气虚质` should remain.

- [ ] **Step 2: Run tests**

Run:

```powershell
hvigor test
```

Expected: Hypium tests pass. If the local command is unavailable, record the exact error.

- [ ] **Step 3: Run build if available**

Run:

```powershell
hvigor assembleHap
```

Expected: build succeeds. If the local command is unavailable, record the exact error.

- [ ] **Step 4: Check git status only if repository exists**

Run:

```powershell
git status --short
```

Expected: if this workspace is not a git repository, report that commits cannot be made here.

## Self-Review Notes

- Spec coverage: The plan restores Chinese copy, keeps local deterministic data, preserves the four-tab structure, improves home copy hierarchy, updates unit tests, and defines verification.
- Placeholder scan: No implementation placeholder steps are intentionally left open.
- Type consistency: All referenced interfaces and functions already exist in the current project.
