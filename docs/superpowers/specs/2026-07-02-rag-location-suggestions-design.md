# RAG Location-Aware Suggestions Design

## Goal

把 APP 当前获取到的定位、地址、天气、用户档案和场景信息发给统一后端，由后端检索私域知识库和向量数据库，再调用本地大模型生成养生建议返回 APP。

最终效果不是“判断湿度后返回写死文案”，而是：

1. APP 负责采集当前位置和天气上下文。
2. Spring Boot 作为 APP 唯一后端入口。
3. Spring Boot 组织用户档案、位置天气、场景、风险信号和检索查询。
4. 后端从 MySQL 私域知识库做关键词/规则检索。
5. 后端从 Milvus 做向量召回。
6. 后端把召回片段、风险规则、用户上下文交给本地 OpenAI-compatible 大模型。
7. 大模型生成结构化建议、计划、引用来源和免责声明。
8. Spring Boot 记录检索日志和使用过的知识片段，返回 APP。

## Current Context

当前代码已经有一部分基础：

- APP 的 `SuggestionService.ets` 已调用 `/api/ai/suggestions`，请求体包含 `scenario`、`weather`、`profile`。
- APP 的天气链路已经会用定位坐标请求天气。
- Spring Boot 已暴露 `/api/ai/suggestions`，但当前 `AssistantSuggestionService` 在 Node 桥接失败时会返回写死的 `SpringBootFallback`。
- Spring Boot 已有私域知识库表结构初始化，包括：
  - `medical_knowledge_category`
  - `medical_knowledge_document`
  - `medical_knowledge_chunk`
  - `medical_risk_rule`
  - `medical_knowledge_search_log`
  - `agent_knowledge_reference`
  - `knowledge_embedding_task`
  - `rag_retrieval_result`
- 表结构已经预留 `vector_id`、`vector_database`、`collection_name`，适合接 Milvus。
- Node 端已经支持本地 OpenAI-compatible 大模型配置，可以作为迁移参考，但本次目标以 Spring Boot 为主链路。

## Recommended Architecture

第一版采用：

**Spring Boot unified API + MySQL private knowledge base + Milvus vector retrieval + local embedding model + local LLM generation.**

运行链路：

```text
HarmonyOS APP
  -> Spring Boot /api/ai/suggestions
  -> User/profile/weather/location context builder
  -> Risk rule retrieval from MySQL
  -> Keyword retrieval from medical_knowledge_chunk
  -> Vector retrieval from Milvus
  -> Prompt builder
  -> Local OpenAI-compatible LLM
  -> Response normalizer
  -> Retrieval/reference logging
  -> APP
```

## Key Decisions

### Backend Entry

APP 和 PC 最终只面对 Spring Boot。Node 不再作为正式客户端入口。

短期如果 Node 的 prompt 或 LLM client 仍有可复用价值，可以作为参考实现，但 `/api/ai/suggestions` 的正式业务链路应落在 Spring Boot。

### Vector Database

选 Milvus。

原因：

- Spring Boot 现有 RAG 表结构已经默认写了 `MILVUS`。
- Milvus 更适合后续私域医疗/养生知识库扩展。
- `knowledge_embedding_task.vector_database`、`collection_name`、`vector_id` 可以直接承接 Milvus 索引状态。

### Embedding Model

第一版推荐 `bge-m3` 或同等级中文 embedding 模型。

后端通过 OpenAI-compatible embedding endpoint 调用本地 embedding 服务，不把 embedding 模型绑定死在代码里。配置示例：

```yaml
app:
  rag:
    embedding-base-url: ${RAG_EMBEDDING_BASE_URL:http://127.0.0.1:11434/v1/embeddings}
    embedding-model: ${RAG_EMBEDDING_MODEL:bge-m3}
```

### Generation Model

本地大模型使用 OpenAI-compatible chat endpoint。

配置示例：

```yaml
app:
  rag:
    chat-base-url: ${RAG_CHAT_BASE_URL:http://127.0.0.1:11434/v1/chat/completions}
    chat-model: ${RAG_CHAT_MODEL:qwen2.5:7b}
```

### Fallback Policy

不再返回写死的养生建议伪装成 AI 结果。

允许的兜底只有两类：

1. 风险规则拦截：如果命中胸痛、呼吸困难、卒中、高热、心理危机等高危规则，直接返回就医/急救提示。
2. 服务不可用提示：如果私域库、向量库或大模型不可用，返回明确的错误来源和“AI 建议暂不可用”，APP 保留原页面内容。

不允许：

- 根据湿度、温度或场景硬编码一组固定建议。
- 在没有检索和模型生成时返回 `source=DeepSeek`、`source=AI` 或类似标识。

## Request Contract

当前 APP 请求体可以继续兼容：

```json
{
  "scenario": "home",
  "weather": {
    "city": "杭州",
    "condition": "多云",
    "temperature": "29℃",
    "humidity": "78%",
    "riskLevel": "湿热提醒",
    "sourceLabel": "Open-Meteo",
    "latitude": 30.2741,
    "longitude": 120.1551
  },
  "profile": {
    "constitution": {
      "name": "气虚质"
    },
    "healthIndicators": [],
    "tongueNotes": [],
    "reminderPreferences": []
  }
}
```

如果 APP 当前 `weather` 对象还没有 `latitude`、`longitude`，第一版可以只使用 `city`、天气和湿度；后续再补坐标字段透传。

## Response Contract

建议返回结构继续兼容 APP 当前 `SuggestionResult`，并扩展可追溯字段：

```json
{
  "source": "LocalRagLlm",
  "riskLevel": "normal",
  "scenario": "home",
  "summary": "结合杭州当前湿度偏高、气虚质倾向和私域知识库，今日建议以轻量活动、清淡饮食和睡眠恢复为主。",
  "suggestions": [
    "早餐减少油腻和冰冷食物",
    "午后安排短时通风和舒缓步行",
    "睡前减少屏幕刺激并保持固定入睡时间"
  ],
  "plans": [
    {
      "timeOfDay": "morning",
      "title": "轻启动",
      "action": "早餐选择温热清淡食物，饭后散步 5-10 分钟。",
      "reason": "召回知识提示气虚和湿度偏高时应避免过度消耗。"
    }
  ],
  "references": [
    {
      "chunkId": 12,
      "title": "气虚与疲劳的养生提示",
      "documentTitle": "中医体质与日常养生基础",
      "retrievalType": "HYBRID",
      "score": 0.82
    }
  ],
  "disclaimer": "本建议仅用于日常养生参考，不能替代医生诊断。若症状持续、加重或出现胸痛、呼吸困难等风险信号，请及时就医。"
}
```

APP 第一版可以忽略 `references`，但后端必须保留，方便后续展示“依据来源”。

## Spring Boot Components

### `AssistantSuggestionService`

职责：

- 作为 `/api/ai/suggestions` 的业务入口。
- 调用 RAG suggestion pipeline。
- 不再直接拼装写死 fallback 建议。

### `RagSuggestionService`

职责：

- 构建检索查询。
- 调用风险规则、关键词检索、向量检索。
- 调用 prompt builder 和 LLM client。
- 归一化返回结构。

### `KnowledgeRetrievalService`

职责：

- 从 `medical_risk_rule` 检索风险规则。
- 从 `medical_knowledge_chunk` 做 MySQL FULLTEXT 或 LIKE 关键词召回。
- 合并 Milvus 向量召回结果。
- 返回统一 `KnowledgeHit` 列表。

### `EmbeddingClient`

职责：

- 调用本地 embedding 服务。
- 输入 query text，输出 float vector。
- 仅封装 HTTP 和错误，不做业务判断。

### `MilvusVectorClient`

职责：

- 调用 Milvus 检索。
- 输入 embedding vector 和 collection name。
- 输出 vector id、score、rank。

第一版如果 Milvus SDK 引入成本高，可以先定义接口和 no-op 实现，同时保留 MySQL FULLTEXT 召回；但正式目标必须接 Milvus。

### `LocalLlmClient`

职责：

- 调用本地 OpenAI-compatible chat endpoint。
- 要求模型返回 JSON。
- 不负责写死建议。

### `RagSuggestionPromptBuilder`

职责：

- 把场景、天气、地址、用户档案、风险规则和知识片段拼成 prompt。
- 明确要求模型：
  - 只能基于给定上下文和知识片段生成日常养生建议。
  - 不得诊断疾病。
  - 高危信号必须建议就医。
  - 必须返回 JSON。

### `RagRetrievalLogService`

职责：

- 写入 `medical_knowledge_search_log`。
- 写入 `rag_retrieval_result`。
- 写入 `agent_knowledge_reference`。

## Data Flow

1. APP 调用 `/api/weather/current` 获取当前位置天气。
2. APP 调用 `/api/ai/suggestions`，传入 `scenario`、`weather`、`profile`。
3. Spring Boot 生成 query text，例如：

```text
场景: home
城市: 杭州
天气: 多云 29℃ 湿度78% 湿热提醒
体质: 气虚质
目标: 生成今日居家养生建议
```

4. 风险规则检索：
   - 如果 request/profile 中有高危关键词，返回风险提示。
5. 关键词检索：
   - 查询 `medical_knowledge_chunk` 中启用的知识片段。
6. 向量检索：
   - 调用 embedding 服务生成 query embedding。
   - 调用 Milvus 搜索。
   - 用 vector id 回查 `medical_knowledge_chunk`。
7. 合并和排序：
   - 优先高安全等级、启用状态、关键词+向量都命中的片段。
8. 生成 prompt。
9. 调用本地 LLM。
10. 解析 JSON。
11. 保存检索日志和引用。
12. 返回 APP。

## Error Handling

### Risk Rule Hit

如果命中 `EMERGENCY` 或 `HIGH` 风险规则：

- 不调用普通养生建议生成。
- 返回 `riskLevel=urgent`。
- `source=RiskRule`.
- `summary` 和 `suggestions` 来自风险规则和安全模板。

这是安全拦截，不属于写死养生建议。

### Knowledge Retrieval Empty

如果没有检索到任何知识片段：

- 可以调用 LLM 生成“信息不足，建议补充档案/天气/症状”的响应。
- 不生成具体个性化养生计划。
- `source=LocalRagLlm`.
- `references=[]`.

### LLM Failure

如果本地大模型不可用：

- 返回 HTTP 503 或业务结构 `source=Unavailable`。
- APP 保留原计划，不显示伪 AI 建议。

### Vector DB Failure

第一版允许 vector 失败后继续使用 MySQL 关键词召回，但 response metadata 应能体现：

```json
{
  "retrievalStatus": "KEYWORD_ONLY"
}
```

不允许静默伪装成完整向量检索。

## Testing Strategy

### Unit Tests

- `AssistantSuggestionServiceTest`
  - 验证建议请求进入 `RagSuggestionService`。
  - 验证不再返回 `SpringBootFallback` 写死建议。
- `KnowledgeRetrievalServiceTest`
  - 验证风险规则命中。
  - 验证关键词召回。
  - 验证向量结果与 MySQL chunk 合并。
- `RagSuggestionPromptBuilderTest`
  - 验证 prompt 包含城市、天气、体质、场景、知识片段和安全边界。
- `LocalLlmClientTest`
  - 验证 OpenAI-compatible 请求格式。
  - 验证 JSON 解析失败会抛出可识别异常。

### Controller Tests

- `/api/ai/suggestions` 返回 RAG 结果。
- LLM 不可用时返回明确不可用状态。
- 风险规则命中时返回 urgent。

### Integration Tests

第一版不要求真实 Milvus 在单测中运行。使用 mock `MilvusVectorClient`。

真实环境联调用手动 checklist：

1. 启动 MySQL。
2. 启动 Spring Boot。
3. 启动 embedding 服务。
4. 启动 Milvus。
5. 启动本地 LLM。
6. APP 刷新天气。
7. APP 首页触发 `/api/ai/suggestions`。
8. 后端日志能看到检索片段和 LLM 调用。
9. APP 显示 `source=LocalRagLlm` 的建议。

## Rollout Plan

### Phase 1: MySQL RAG + Local LLM

先不阻塞在 Milvus 部署上，完成：

- Spring Boot RAG pipeline。
- MySQL 私域知识检索。
- 本地 LLM 生成。
- 禁止写死 fallback 建议。

### Phase 2: Embedding + Milvus

完成：

- embedding task 生成。
- Milvus collection 写入。
- `/api/ai/suggestions` 使用 hybrid retrieval。
- 检索日志记录 vector score。

### Phase 3: APP 引用展示

完成：

- APP 展示“建议来源”。
- 显示引用知识标题。
- 管理员可追踪建议使用过的知识片段。

## Acceptance Criteria

第一版完成时必须满足：

1. `/api/ai/suggestions` 不再返回 `SpringBootFallback` 写死建议。
2. 正常请求会经过私域知识检索。
3. 正常请求会调用本地大模型。
4. 返回结果包含 `source=LocalRagLlm`。
5. 返回结果包含 `summary`、`suggestions`、`plans`、`disclaimer`。
6. 后端保存检索日志。
7. LLM 不可用时不伪造建议。
8. 风险规则命中时优先返回就医/急救提示。

## Open Implementation Notes

- 如果当前 Spring Boot 项目暂时没有 Milvus SDK 依赖，第一版可以先创建 `MilvusVectorClient` 接口和 mock/no-op 实现，待第二阶段接真实 Milvus。
- APP 当前模型 `SuggestionResult` 没有 `references` 字段，第一版后端可返回额外字段，ArkTS 解析会忽略；后续再扩展 APP 展示。
- 当前 `weather` 结构是否包含经纬度取决于 APP 模型，需要实现时确认并补字段透传。
- 本地大模型和 embedding 服务的 endpoint 应全部通过 `application.yml` 和环境变量配置，不写死在 Java 类里。
