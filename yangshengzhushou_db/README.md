# yangshengzhushou_db

轻量后端服务，提供养生助手 APP 的健康检查、天气模拟和聊天接口。

## 启动

```powershell
npm start
```

启动后终端会显示：

```text
Local access: http://127.0.0.1:8787/api/health
APP access: http://你的电脑IP:8787/api/health
```

## DeepSeek 配置

复制 `.env.example` 为 `.env`，填入：

```text
DEEPSEEK_API_KEY=你的DeepSeekKey
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_BASE_URL=https://api.deepseek.com/chat/completions
```

Local OpenAI-compatible model example:

```text
LOCAL_LLM_BASE_URL=http://127.0.0.1:11434/v1/chat/completions
LOCAL_LLM_MODEL=qwen2.5:7b
LOCAL_LLM_API_KEY=
```

没有 `DEEPSEEK_API_KEY` 时，`/api/ai/chat` 会自动使用规则兜底回复。

## 接口

- `GET /api/health`
- `GET /api/weather/current`
- `POST /api/ai/chat`
- `POST /api/ai/suggestions`

聊天接口返回结构：

```json
{
  "reply": "回复正文",
  "source": "DeepSeek 或 规则兜底",
  "riskLevel": "normal",
  "suggestions": ["规律作息", "清淡饮食"],
  "disclaimer": "本建议不能替代医生诊断..."
}
```

## 测试

```powershell
npm test
```
