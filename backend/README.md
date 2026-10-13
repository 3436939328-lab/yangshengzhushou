# SpringBootDemo

Spring Boot + MyBatis + MySQL backend for the wellness assistant platform.

## AI Convergence Rollout

This phase makes Spring Boot the only external AI entrypoint for APP and PC, while preserving the existing Node.js LLM / Prompt / LangGraph orchestration as an internal engine.

1. Start Node orchestration on `8787`.
2. Start Spring Boot on `8181`.
3. Confirm Spring Boot can call Node `/api/ai/chat` and `/api/ai/suggestions`.
4. Confirm APP AI requests target Spring Boot `/api/ai/chat`, not Node directly.
5. Confirm APP scene suggestions target Spring Boot `/api/ai/suggestions`, not Node directly.
6. Confirm PC `health-question` still returns AI answers through Spring Boot.
7. Only after this passes, begin Java-native migration of Prompt / LangGraph equivalents.

Runtime settings:

- `NODE_AI_BASE_URL`, default `http://127.0.0.1:8787`
- `NODE_AI_TIMEOUT_MS`, default `6000`

## AI Configuration

The Java-native fallback path still supports the DeepSeek/OpenAI-compatible client.

- `DEEPSEEK_API_KEY`, required for real Java fallback AI replies
- `DEEPSEEK_BASE_URL`, default `https://api.deepseek.com`
- `DEEPSEEK_MODEL`, default `deepseek-v4-pro`
- `DEEPSEEK_MEMORY_WINDOW`, default `4`
- `DEEPSEEK_TEMPERATURE`, default `0.2`

PowerShell example:

```powershell
$env:DEEPSEEK_API_KEY = "sk-xxx"
```

Persist for the current Windows user:

```powershell
setx DEEPSEEK_API_KEY "sk-xxx"
```

## Startup Checklist

1. MySQL is running and `yangsheng_db` exists.
2. `src/main/resources/application.yml` has the correct datasource account.
3. Node AI orchestration is running if you want the preserved LangGraph path.
4. Spring Boot is running on `8181`.
5. APP and PC call Spring Boot for AI and business APIs.
