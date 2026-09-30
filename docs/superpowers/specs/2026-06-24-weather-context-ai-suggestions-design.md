# Weather Context AI Suggestions Design

## Goal

Make every user-facing wellness suggestion in the app use the current location weather context when available. Weather context includes current location label, condition, temperature, humidity, risk level, source label, and whether the value is live or fallback. AI output should adapt advice to weather and humidity while preserving local fallback behavior.

## Current State

- The home weather card requests location and receives live weather from the backend when coordinates are available.
- Home daily plans, personal plans, questionnaire suggestions, report suggestions, knowledge cards, and some assistant example cards are generated from local static or rule-based code.
- Assistant chat can call the backend AI, but the request body currently includes only the question, profile, and recent chat history. It does not include weather context.
- The backend has a weather endpoint and an AI chat endpoint, but it does not yet expose a unified endpoint for page-level suggestions.

## Recommended Approach

Create a unified weather-aware suggestion flow:

1. The app keeps a single `WeatherWellness` state after location/weather loading.
2. The frontend sends this weather context to all suggestion requests.
3. The backend adds weather context to AI prompts and rule fallback generation.
4. Page-level suggestion groups are requested by scenario, such as `home`, `assistant`, `questionnaire`, `report`, `profile`, and `knowledge`.
5. The UI renders AI results when available and falls back to existing local suggestions when unavailable.

This keeps the app stable while making live weather the normal source for advice.

## Data Model

Add a shared weather context shape to frontend request payloads and backend prompt input:

```json
{
  "city": "当前位置",
  "condition": "多云",
  "temperature": "28℃",
  "humidity": "72%",
  "advice": "湿度偏高...",
  "riskLevel": "湿热提醒",
  "sourceLabel": "Open-Meteo",
  "isFallback": false
}
```

The existing `WeatherWellness` model already contains most fields. Add `isFallback?: boolean` only if needed to distinguish live weather from fallback defaults.

## Backend Design

Add a scenario-based suggestions endpoint:

- `POST /api/ai/suggestions`

Request body:

```json
{
  "scenario": "home",
  "weather": {},
  "profile": {},
  "records": {},
  "question": ""
}
```

Response body:

```json
{
  "source": "DeepSeek",
  "riskLevel": "normal",
  "summary": "今日湿度偏高，建议以健脾祛湿和低强度活动为主。",
  "suggestions": ["清淡饮食", "室内通风", "温和活动"],
  "plans": [],
  "disclaimer": "本建议不能替代医生诊断..."
}
```

The existing `/api/ai/chat` endpoint remains for chat, but its prompt also receives `weather`. The backend prompt should include a compact weather section:

- Current location and source.
- Temperature and humidity.
- Weather risk label.
- Explicit instruction to adapt food, exercise, sleep, and reminders to the weather context.

If DeepSeek is disabled or fails, the backend returns rule-based weather-aware suggestions instead of failing the UI.

## Frontend Design

Use the existing `currentWeather` state from `Index.ets` as the root weather context.

Pass it into:

- `HomeTab` for weather-aware daily plans and personal plan.
- `AssistantTab` so chat requests include weather.
- `DataTab` for report/metric suggestions.
- `ProfileTab` for questionnaire/profile suggestions.

Add a small frontend service, for example `SuggestionService.ets`, responsible for:

- Building request payloads with `weather`, `profile`, and scenario.
- Calling `/api/ai/suggestions`.
- Returning typed suggestion results.
- Falling back to current local services when backend or AI is unavailable.

Keep existing local services as fallback providers:

- `WellnessContentService`
- `PersonalPlanService`
- `ReportService`
- `QuestionnaireService`
- `RecommendationUtil`
- `AIService`

## Scenario Mapping

`home`
: Generates daily plan cards and the personal plan summary using weather, profile, sleep, and goal.

`assistant`
: Generates chat replies and attached plans using weather, profile, question, and history.

`questionnaire`
: Generates the post-questionnaire constitution suggestion using weather and questionnaire result.

`report`
: Generates data/report interpretation advice using weather, metrics, profile, and risk rules.

`knowledge`
: Generates food, acupoint, and contraindication recommendations using weather and profile.

`profile`
: Generates profile-level health archive suggestions and reminder suggestions using weather and saved preferences.

## Caching And Refresh

Avoid calling AI from every component independently.

- Refresh weather on app entry as it does today.
- Refresh page-level suggestions when weather changes from fallback to live data.
- Refresh relevant suggestions after profile/questionnaire changes.
- Chat remains real-time per user question.
- Cache scenario results in component state for the session.

## Error Handling

- If location permission is denied, use fallback weather and mark the source as fallback.
- If weather API fails, keep fallback weather and local suggestions.
- If AI suggestions fail, keep local suggestions and show no blocking error.
- Urgent symptom handling must remain rule-protected and must not depend on weather.

## Testing

Backend:

- Weather context is included in AI prompt construction.
- `/api/ai/suggestions` returns weather-aware rule fallback when LLM is disabled.
- `/api/ai/chat` accepts weather and includes it in LLM input.
- Urgent risk still overrides ordinary wellness advice.

Frontend:

- Assistant requests include current weather.
- Home renders fallback local plans before AI suggestions arrive.
- Home updates when live weather arrives.
- Data/Profile/Questionnaire screens can render local fallbacks if suggestion request fails.

## Out Of Scope

- Medical diagnosis or disease treatment plans.
- Continuous background location tracking.
- Paid weather API keys.
- Persisting AI-generated suggestions across app restarts.
- Replacing all local content permanently; local content remains the reliability fallback.
