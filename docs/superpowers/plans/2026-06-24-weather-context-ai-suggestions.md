# Weather Context AI Suggestions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all user-facing wellness suggestions receive current location weather context and prefer backend AI generation with local fallback.

**Architecture:** Keep weather as a single app-level context loaded by `Index.ets`, pass it into tabs, and centralize scenario suggestion calls in a new frontend service. Extend the backend AI prompt and add `POST /api/ai/suggestions` for page-level weather-aware advice while preserving existing rule fallbacks.

**Tech Stack:** HarmonyOS ArkTS frontend, Node.js backend, built-in `fetch`, existing DeepSeek client, existing local service fallbacks.

---

### Task 1: Backend Weather Context In AI Prompt

**Files:**
- Modify: `D:\yangshengzhushou\yangshengzhushou_db\src\llmClient.js`
- Modify: `D:\yangshengzhushou\yangshengzhushou_db\test\llm.test.js`

- [ ] **Step 1: Write failing prompt test**

Add this assertion block near the existing `buildLlmPrompt` prompt assertions in `test/llm.test.js`:

```js
  const weatherPrompt = buildLlmPrompt({
    message: '今天怎么安排',
    profile: { constitution: { name: '气虚质' } },
    weather: {
      city: '当前位置',
      condition: '多云',
      temperature: '29℃',
      humidity: '78%',
      riskLevel: '湿热提醒',
      sourceLabel: 'Open-Meteo'
    }
  });
  assert.ok(weatherPrompt.includes('当前天气：当前位置，多云，29℃，湿度78%'));
  assert.ok(weatherPrompt.includes('天气风险：湿热提醒'));
  assert.ok(weatherPrompt.includes('请结合当前温度、湿度和天气风险调整饮食、运动、睡眠和提醒建议'));
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
node test/llm.test.js
```

Expected: FAIL because the prompt does not include weather context.

- [ ] **Step 3: Implement prompt weather summary**

In `src/llmClient.js`, add:

```js
function buildWeatherSummary(weather) {
  if (!weather || typeof weather !== 'object') {
    return '当前天气：未获取';
  }
  const city = typeof weather.city === 'string' && weather.city.length > 0 ? weather.city : '当前位置';
  const condition = typeof weather.condition === 'string' && weather.condition.length > 0 ? weather.condition : '未知';
  const temperature = typeof weather.temperature === 'string' && weather.temperature.length > 0 ? weather.temperature : '--℃';
  const humidity = typeof weather.humidity === 'string' && weather.humidity.length > 0 ? weather.humidity : '--';
  const riskLevel = typeof weather.riskLevel === 'string' && weather.riskLevel.length > 0 ? weather.riskLevel : '天气未明';
  const sourceLabel = typeof weather.sourceLabel === 'string' && weather.sourceLabel.length > 0 ? weather.sourceLabel : '未知来源';
  return [
    `当前天气：${city}，${condition}，${temperature}，湿度${humidity}`,
    `天气风险：${riskLevel}`,
    `天气来源：${sourceLabel}`,
    '请结合当前温度、湿度和天气风险调整饮食、运动、睡眠和提醒建议。'
  ].join('\n');
}
```

Then include `buildWeatherSummary(body.weather)` in the array returned by `buildLlmPrompt`, before `用户问题`.

Export `buildWeatherSummary` from `module.exports`.

- [ ] **Step 4: Run test to verify it passes**

Run:

```powershell
node test/llm.test.js
```

Expected: `llm tests passed`.

### Task 2: Backend Weather-Aware Rule Suggestions Endpoint

**Files:**
- Modify: `D:\yangshengzhushou\yangshengzhushou_db\src\server.js`
- Modify: `D:\yangshengzhushou\yangshengzhushou_db\test\server.test.js`

- [ ] **Step 1: Write failing endpoint test**

In `test/server.test.js`, after the weather endpoint assertions and before chat assertions, add:

```js
    const suggestions = await requestJson(server, 'POST', '/api/ai/suggestions', {
      scenario: 'home',
      weather: {
        city: '当前位置',
        condition: '多云',
        temperature: '29℃',
        humidity: '78%',
        riskLevel: '湿热提醒',
        sourceLabel: 'Open-Meteo'
      },
      profile: { constitution: { name: '气虚质' } }
    });
    assert.strictEqual(suggestions.status, 200);
    assert.strictEqual(suggestions.data.source, '规则兜底');
    assert.strictEqual(suggestions.data.riskLevel, 'normal');
    assert.ok(suggestions.data.summary.includes('湿度偏高'));
    assert.ok(suggestions.data.suggestions.includes('室内通风'));
    assert.ok(Array.isArray(suggestions.data.plans));
    assert.ok(suggestions.data.plans[0].action.includes('湿度'));
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
node test/server.test.js
```

Expected: FAIL with 404 for `/api/ai/suggestions`.

- [ ] **Step 3: Implement endpoint and fallback builder**

In `src/server.js`, add a helper:

```js
function parseHumidityValue(weather = {}) {
  const humidityText = typeof weather.humidity === 'string' ? weather.humidity.replace('%', '') : '';
  const humidity = Number(humidityText);
  return Number.isFinite(humidity) ? humidity : NaN;
}

function buildWeatherAwareSuggestions(body = {}) {
  const weather = body.weather || {};
  const scenario = typeof body.scenario === 'string' ? body.scenario : 'home';
  const humidity = parseHumidityValue(weather);
  const constitution = body.profile && body.profile.constitution && body.profile.constitution.name
    ? body.profile.constitution.name
    : '平和质';
  const humid = Number.isFinite(humidity) && humidity >= 75;
  const dry = Number.isFinite(humidity) && humidity <= 35;
  const summary = humid
    ? `当前${weather.city || '位置'}湿度偏高，建议${constitution}以健脾祛湿、清淡饮食和温和活动为主。`
    : dry
    ? `当前空气偏干，建议${constitution}注意补水润燥，减少辛辣和熬夜。`
    : `当前温湿度较平稳，建议${constitution}保持规律作息、温和活动和清淡饮食。`;
  const suggestions = humid
    ? ['清淡饮食', '室内通风', '温和活动']
    : dry
    ? ['少量多次饮水', '润燥饮食', '减少辛辣']
    : ['规律作息', '清淡饮食', '温和运动'];
  return {
    source: '规则兜底',
    riskLevel: 'normal',
    scenario,
    summary,
    suggestions,
    plans: [
      {
        timeOfDay: 'morning',
        title: suggestions[0],
        action: `结合${weather.temperature || '--℃'}、湿度${weather.humidity || '--'}，早餐清淡并安排 5-10 分钟舒缓活动。`,
        reason: '晨间计划随天气负担调整，避免过度消耗。'
      },
      {
        timeOfDay: 'afternoon',
        title: suggestions[1],
        action: humid ? '午后保持室内通风，减少冰饮和油腻。' : '午后短时散步或闭目休息，保持节律稳定。',
        reason: '午后容易受湿度和疲劳影响，轻量调整更稳妥。'
      },
      {
        timeOfDay: 'evening',
        title: suggestions[2],
        action: '睡前减少屏幕刺激，可做缓慢呼吸或温水泡脚。',
        reason: '稳定睡前节律，有助于恢复体力。'
      }
    ],
    disclaimer: '本建议不能替代医生诊断，若症状持续或加重，请及时就医。'
  };
}
```

Then in `createAppServer`, add before `/api/ai/chat`:

```js
    if (request.method === 'POST' && parsedUrl.pathname === '/api/ai/suggestions') {
      const body = await readJsonBody(request);
      sendJson(response, 200, buildWeatherAwareSuggestions(body));
      return;
    }
```

Export `buildWeatherAwareSuggestions`.

- [ ] **Step 4: Run test to verify it passes**

Run:

```powershell
node test/server.test.js
```

Expected: `server tests passed`.

### Task 3: Backend Chat Receives Weather Context

**Files:**
- Modify: `D:\yangshengzhushou\yangshengzhushou_db\test\graph.test.js`
- Modify: `D:\yangshengzhushou\yangshengzhushou_db\src\agent\healthAssistantGraph.js`

- [ ] **Step 1: Write failing graph test**

In `test/graph.test.js`, inside the captured input test, add `weather` to the graph input:

```js
    weather: {
      city: '当前位置',
      condition: '多云',
      temperature: '29℃',
      humidity: '78%',
      riskLevel: '湿热提醒',
      sourceLabel: 'Open-Meteo'
    },
```

Then add after `capturedInput` assertions:

```js
  assert.strictEqual(capturedInput.weather.temperature, '29℃');
  assert.strictEqual(capturedInput.weather.humidity, '78%');
```

- [ ] **Step 2: Run test to verify current pass-through**

Run:

```powershell
node test/graph.test.js
```

Expected: PASS if the spread already passes weather through. If it fails, continue to Step 3.

- [ ] **Step 3: Ensure graph preserves weather**

In `src/agent/healthAssistantGraph.js`, in `generateReply`, keep using:

```js
      const llmInput = {
        ...state.input,
        memoryContext: state.memoryContext
      };
```

No implementation change is needed if Step 2 passed. The test documents the behavior.

- [ ] **Step 4: Run backend tests**

Run:

```powershell
npm test
```

Expected: `llm tests passed`, `graph tests passed`, `server tests passed`.

### Task 4: Frontend Models And Suggestion Service

**Files:**
- Modify: `D:\yangshengzhushou\entry\src\main\ets\model\WellnessModels.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\services\ApiConfig.ets`
- Create: `D:\yangshengzhushou\entry\src\main\ets\services\SuggestionService.ets`
- Modify: `D:\yangshengzhushou\entry\src\test\LocalUnit.test.ets`

- [ ] **Step 1: Write failing unit tests**

In `LocalUnit.test.ets`, import the new service:

```ts
import { buildSuggestionRequestPayload, buildSuggestionResultFromBackendPayload } from '../main/ets/services/SuggestionService';
```

Add tests near assistant service tests:

```ts
    it('builds weather-aware suggestion request payload', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const weather = getCurrentWeatherWellness();
      const payload = buildSuggestionRequestPayload('home', weather, profile);

      expect(payload.scenario).assertEqual('home');
      expect(payload.weather.temperature).assertEqual('27℃');
      expect(payload.profile.constitution.name).assertEqual('平和质');
    });

    it('builds suggestion result from backend payload', 0, () => {
      const result = buildSuggestionResultFromBackendPayload('{"source":"规则兜底","riskLevel":"normal","summary":"湿度偏高","suggestions":["室内通风"],"plans":[{"timeOfDay":"morning","title":"清淡饮食","action":"少油腻","reason":"湿度偏高"}],"disclaimer":"不能替代医生诊断"}');

      expect(result.source).assertEqual('规则兜底');
      expect(result.summary).assertContain('湿度');
      expect(result.suggestions[0]).assertEqual('室内通风');
      expect(result.plans[0].title).assertEqual('清淡饮食');
    });
```

- [ ] **Step 2: Add model fields and API path**

In `WellnessModels.ets`, add optional fallback flag and suggestion result:

```ts
export interface WeatherWellness {
  city: string;
  condition: string;
  temperature: string;
  humidity: string;
  advice: string;
  riskLevel: string;
  sourceLabel: string;
  isFallback?: boolean;
}

export interface SuggestionResult {
  source: string;
  riskLevel: string;
  scenario: string;
  summary: string;
  suggestions: string[];
  plans: WellnessPlanItem[];
  disclaimer: string;
}
```

In `ApiConfig.ets`, add:

```ts
suggestionsPath: string;
```

and set:

```ts
suggestionsPath: '/api/ai/suggestions',
```

- [ ] **Step 3: Create service implementation**

Create `SuggestionService.ets`:

```ts
import { http } from '@kit.NetworkKit';
import { HealthProfile } from '../model/ProfileModels';
import { SuggestionResult, WeatherWellness, WellnessPlanItem } from '../model/WellnessModels';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { checkBackendHealth } from './BackendStatusService';

export interface SuggestionRequestPayload {
  scenario: string;
  weather: WeatherWellness;
  profile: HealthProfile;
}

interface BackendSuggestionPayload {
  source?: string;
  riskLevel?: string;
  scenario?: string;
  summary?: string;
  suggestions?: string[];
  plans?: WellnessPlanItem[];
  disclaimer?: string;
}

export function buildSuggestionRequestPayload(
  scenario: string,
  weather: WeatherWellness,
  profile: HealthProfile
): SuggestionRequestPayload {
  return {
    scenario,
    weather,
    profile
  };
}

export function buildSuggestionResultFromBackendPayload(payload: string): SuggestionResult {
  const data = JSON.parse(payload) as BackendSuggestionPayload;
  return {
    source: data.source ? data.source : '后端',
    riskLevel: data.riskLevel ? data.riskLevel : 'normal',
    scenario: data.scenario ? data.scenario : 'home',
    summary: data.summary ? data.summary : '',
    suggestions: data.suggestions ? data.suggestions : [],
    plans: data.plans ? data.plans : [],
    disclaimer: data.disclaimer ? data.disclaimer : ''
  };
}

export function requestWeatherAwareSuggestions(
  scenario: string,
  weather: WeatherWellness,
  profile: HealthProfile
): Promise<SuggestionResult> {
  return checkBackendHealth().then(() => {
    const config = getApiConfig();
    const request = http.createHttp();
    const body = JSON.stringify(buildSuggestionRequestPayload(scenario, weather, profile));
    return request.request(buildApiUrl(config.suggestionsPath), {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json'
      },
      extraData: body,
      connectTimeout: config.timeoutMs,
      readTimeout: config.timeoutMs
    }).then((response: http.HttpResponse) => {
      request.destroy();
      return buildSuggestionResultFromBackendPayload(`${response.result}`);
    }).catch((error: Error) => {
      request.destroy();
      return Promise.reject(error);
    });
  });
}
```

- [ ] **Step 4: Run frontend unit tests if available**

Run the existing HarmonyOS unit test command used by the project. If no local command exists, run backend tests and record that ArkTS unit tests were not runnable from this shell.

### Task 5: Assistant Chat Sends Weather

**Files:**
- Modify: `D:\yangshengzhushou\entry\src\main\ets\services\AssistantReplyService.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\components\tabs\AssistantTab.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\pages\Index.ets`
- Modify: `D:\yangshengzhushou\entry\src\test\LocalUnit.test.ets`

- [ ] **Step 1: Extend assistant request API**

Modify `requestAssistantReplyRemoteFirst` signature:

```ts
export function requestAssistantReplyRemoteFirst(
  question: string,
  profile: HealthProfile,
  messages: ChatMessage[] = [],
  weather?: WeatherWellness
): Promise<AssistantReplyResult> {
```

Include weather in the request body:

```ts
    const body = JSON.stringify({
      message: question,
      profile,
      weather,
      history: buildBackendHistory(messages)
    });
```

Import `WeatherWellness`.

- [ ] **Step 2: Pass weather from page to assistant tab**

In `AssistantTab.ets`, add:

```ts
  @Prop weather: WeatherWellness;
```

Import `WeatherWellness`. In `sendLocalQuestion`, call:

```ts
    requestAssistantReplyRemoteFirst(question, this.localProfile, this.messages, this.weather).then((reply: AssistantReplyResult) => {
```

In `Index.ets`, change:

```ts
            AssistantTab({ questionnaireScore: $questionnaireScore })
```

to:

```ts
            AssistantTab({ questionnaireScore: $questionnaireScore, weather: this.currentWeather })
```

- [ ] **Step 3: Add payload unit test helper if practical**

If `AssistantReplyService.ets` keeps the body construction inline, extract:

```ts
export function buildAssistantRequestPayload(
  question: string,
  profile: HealthProfile,
  messages: ChatMessage[] = [],
  weather?: WeatherWellness
): string {
  return JSON.stringify({
    message: question,
    profile,
    weather,
    history: buildBackendHistory(messages)
  });
}
```

Use it inside `requestAssistantReplyRemoteFirst`. Add a unit test:

```ts
    it('includes weather in assistant request payload', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const weather = getCurrentWeatherWellness();
      const payload = buildAssistantRequestPayload('今天怎么吃', profile, [], weather);

      expect(payload).assertContain('"weather"');
      expect(payload).assertContain('"humidity":"68%"');
      expect(payload).assertContain('"temperature":"27℃"');
    });
```

### Task 6: Home Uses Weather-Aware Suggestions

**Files:**
- Modify: `D:\yangshengzhushou\entry\src\main\ets\pages\Index.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\components\tabs\HomeTab.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\viewmodel\WellnessDashboardViewModel.ets`

- [ ] **Step 1: Add home suggestion state**

In `Index.ets`, add:

```ts
  @State weatherAwarePlans: WellnessPlan[] = createWellnessDashboardData().plans;
```

When live weather arrives, call `requestWeatherAwareSuggestions('home', weather, createDefaultHealthProfile())`, map returned `plans` into `WellnessPlan[]`, and update `weatherAwarePlans`.

Mapping:

```ts
function mapPlanItemsToWellnessPlans(items: WellnessPlanItem[]): WellnessPlan[] {
  return items.map((item: WellnessPlanItem) => {
    return {
      title: item.title,
      time: item.timeOfDay === 'morning' ? '07:30' : item.timeOfDay === 'afternoon' ? '13:00' : '22:00',
      detail: item.action,
      tag: item.timeOfDay === 'morning' ? '运动' : item.timeOfDay === 'afternoon' ? '食疗' : '作息'
    };
  });
}
```

- [ ] **Step 2: Render weather-aware plans**

In `HomeTab` invocation, change:

```ts
              plans: this.dashboard.plans,
```

to:

```ts
              plans: this.weatherAwarePlans,
```

- [ ] **Step 3: Keep fallback behavior**

If suggestions request fails or returns no plans, keep `this.dashboard.plans`.

### Task 7: Data And Profile Receive Weather Context

**Files:**
- Modify: `D:\yangshengzhushou\entry\src\main\ets\pages\Index.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\components\tabs\DataTab.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\components\tabs\ProfileTab.ets`

- [ ] **Step 1: Add weather props**

Add `@Prop weather: WeatherWellness;` to `DataTab` and `ProfileTab`, with imports.

- [ ] **Step 2: Pass weather from Index**

In `Index.ets`, pass:

```ts
              weather: this.currentWeather,
```

to both `DataTab` and `ProfileTab`.

- [ ] **Step 3: Add visible weather-aware summary text without replacing all local cards**

In `DataTab`, add a compact line near report content:

```ts
Text(`已结合${this.weather.temperature}、湿度${this.weather.humidity}生成建议`)
  .fontSize(12)
  .fontColor(MUTED_TEXT)
```

In `ProfileTab`, add a compact line near profile actions:

```ts
Text(`当前建议参考天气：${this.weather.condition} · ${this.weather.temperature} · 湿度${this.weather.humidity}`)
  .fontSize(12)
  .fontColor(MUTED_TEXT)
```

This ensures these tabs receive and expose the weather context while keeping their existing local fallbacks.

### Task 8: Final Verification

**Files:**
- No edits.

- [ ] **Step 1: Run backend tests**

Run:

```powershell
npm test
```

Expected from `D:\yangshengzhushou\yangshengzhushou_db`: `llm tests passed`, `graph tests passed`, `server tests passed`.

- [ ] **Step 2: Search for remaining assistant calls without weather**

Run:

```powershell
rg -n "requestAssistantReplyRemoteFirst\\(" entry\\src\\main\\ets
```

Expected: call sites pass `this.weather` or an explicit weather value.

- [ ] **Step 3: Search for tab invocations without weather**

Run:

```powershell
rg -n "AssistantTab\\(|DataTab\\(|ProfileTab\\(" entry\\src\\main\\ets\\pages\\Index.ets
```

Expected: all three include `weather: this.currentWeather`.

- [ ] **Step 4: Record limitations**

If ArkTS/HarmonyOS unit tests cannot run in this shell, note that backend tests passed and frontend changes were statically checked by file inspection only.
