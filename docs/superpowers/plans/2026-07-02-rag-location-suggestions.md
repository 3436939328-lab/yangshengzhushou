# RAG Location-Aware Suggestions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace fixed SpringBoot suggestion fallback with a Spring Boot RAG pipeline that retrieves private knowledge, calls a local OpenAI-compatible LLM, and returns traceable location/weather-aware suggestions to the APP.

**Architecture:** Spring Boot remains the only APP-facing backend. `/api/ai/suggestions` delegates to `RagSuggestionService`, which builds context from weather/profile/scenario, checks risk rules, retrieves private knowledge from MySQL, optionally merges vector hits through a Milvus client interface, calls a local LLM, normalizes JSON, and records retrieval logs. Milvus is represented by an interface in phase 1 so MySQL RAG + local LLM can ship before vector deployment.

**Tech Stack:** Spring Boot 3.3.6, Java 17, JdbcTemplate, Jackson, Java `HttpClient`, JUnit 5, Mockito, MySQL FULLTEXT, future Milvus.

---

## File Structure

- Modify: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\AssistantSuggestionReply.java`
  - Add optional `references` and `retrievalStatus` fields to support traceability without breaking existing APP fields.
- Modify: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\service\AssistantSuggestionService.java`
  - Delegate suggestion generation to `RagSuggestionService`.
  - Remove direct `NodeAssistantOrchestrationClient` fallback behavior for suggestions.
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagSuggestionProperties.java`
  - Holds local LLM, embedding, retrieval, and Milvus configuration.
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\KnowledgeHit.java`
  - Represents a retrieved private knowledge chunk.
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\SuggestionReference.java`
  - Represents a reference returned to the APP.
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\LocalLlmSuggestionResult.java`
  - DTO for parsed LLM JSON.
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\LocalLlmClient.java`
  - Calls local OpenAI-compatible chat endpoint.
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagSuggestionPromptBuilder.java`
  - Builds the LLM prompt.
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\KnowledgeRetrievalService.java`
  - Retrieves risk rules and private knowledge chunks from MySQL.
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\MilvusVectorClient.java`
  - Interface for vector retrieval.
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\NoopMilvusVectorClient.java`
  - Phase-1 no-op implementation.
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagRetrievalLogService.java`
  - Writes retrieval logs.
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagSuggestionService.java`
  - Orchestrates the full suggestion pipeline.
- Modify: `D:\SpringBoot\SpringBootDemo\src\main\resources\application.yml`
  - Adds `app.rag` configuration.
- Modify: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\service\AssistantSuggestionServiceTest.java`
  - Replace Node/fallback expectations with RAG delegation tests.
- Create: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\rag\RagSuggestionPromptBuilderTest.java`
  - Tests prompt content.
- Create: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\rag\KnowledgeRetrievalServiceTest.java`
  - Tests risk and keyword retrieval.
- Create: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\rag\LocalLlmClientTest.java`
  - Tests request and JSON parsing with a fake `HttpClient`.
- Create: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\rag\RagSuggestionServiceTest.java`
  - Tests orchestration and no fake AI fallback.

---

### Task 1: Extend Suggestion Reply Contract

**Files:**
- Modify: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\AssistantSuggestionReply.java`
- Modify: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\controller\AssistantControllerTest.java`

- [ ] **Step 1: Write the failing controller assertion**

In `AssistantControllerTest.sceneSuggestionEndpointReturnsSummaryAndPlans`, change the mocked reply to include references and retrieval status after the new constructor exists:

```java
new AssistantSuggestionReply(
        "LocalRagLlm",
        "normal",
        "home",
        "Eat lightly today.",
        List.of("Eat lightly"),
        List.of(Map.of("timeOfDay", "morning", "title", "Light breakfast")),
        "This advice cannot replace medical diagnosis.",
        List.of(Map.of(
                "chunkId", 12L,
                "title", "气虚与疲劳的养生提示",
                "documentTitle", "中医体质与日常养生基础",
                "retrievalType", "KEYWORD",
                "score", 0.8
        )),
        "KEYWORD_ONLY"
)
```

Add assertions:

```java
.andExpect(jsonPath("$.source").value("LocalRagLlm"))
.andExpect(jsonPath("$.references[0].chunkId").value(12))
.andExpect(jsonPath("$.retrievalStatus").value("KEYWORD_ONLY"));
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
mvn test -Dtest=AssistantControllerTest#sceneSuggestionEndpointReturnsSummaryAndPlans
```

Expected: FAIL because `AssistantSuggestionReply` has no constructor with `references` and `retrievalStatus`.

- [ ] **Step 3: Extend `AssistantSuggestionReply`**

Replace the record with:

```java
package org.example.springbootdemo.ai;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_EMPTY)
public record AssistantSuggestionReply(
        String source,
        String riskLevel,
        String scenario,
        String summary,
        List<String> suggestions,
        List<Map<String, Object>> plans,
        String disclaimer,
        List<Map<String, Object>> references,
        String retrievalStatus
) {
    public AssistantSuggestionReply(
            String source,
            String riskLevel,
            String scenario,
            String summary,
            List<String> suggestions,
            List<Map<String, Object>> plans,
            String disclaimer
    ) {
        this(source, riskLevel, scenario, summary, suggestions, plans, disclaimer, List.of(), "");
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```powershell
mvn test -Dtest=AssistantControllerTest#sceneSuggestionEndpointReturnsSummaryAndPlans
```

Expected: PASS.

---

### Task 2: Replace Suggestion Service Dependency With RAG Service

**Files:**
- Modify: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\service\AssistantSuggestionServiceTest.java`
- Modify: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\service\AssistantSuggestionService.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagSuggestionService.java`

- [ ] **Step 1: Replace service test with a failing delegation test**

Replace `AssistantSuggestionServiceTest` with:

```java
package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.AssistantSuggestionReply;
import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.example.springbootdemo.rag.RagSuggestionService;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AssistantSuggestionServiceTest {

    @Test
    void suggestDelegatesToRagSuggestionService() {
        RagSuggestionService ragSuggestionService = mock(RagSuggestionService.class);
        AssistantSuggestionService service = new AssistantSuggestionService(ragSuggestionService);
        AssistantSuggestionRequest request = new AssistantSuggestionRequest(
                "home",
                Map.of("humidity", "78%", "temperature", "27C", "city", "Hangzhou"),
                Map.of("constitution", Map.of("name", "Qi deficiency"))
        );
        AssistantSuggestionReply ragReply = new AssistantSuggestionReply(
                "LocalRagLlm",
                "normal",
                "home",
                "RAG generated home suggestions.",
                List.of("Use private knowledge"),
                List.of(),
                "This advice cannot replace medical diagnosis.",
                List.of(Map.of("chunkId", 1L, "title", "Private knowledge", "retrievalType", "KEYWORD", "score", 0.8)),
                "KEYWORD_ONLY"
        );
        when(ragSuggestionService.suggest(request)).thenReturn(ragReply);

        AssistantSuggestionReply result = service.suggest(request);

        assertEquals("LocalRagLlm", result.source());
        assertEquals("RAG generated home suggestions.", result.summary());
        verify(ragSuggestionService).suggest(request);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
mvn test -Dtest=AssistantSuggestionServiceTest
```

Expected: FAIL because `RagSuggestionService` does not exist and `AssistantSuggestionService` expects `NodeAssistantOrchestrationClient`.

- [ ] **Step 3: Create a temporary `RagSuggestionService` skeleton**

Create `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagSuggestionService.java`:

```java
package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionReply;
import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.springframework.stereotype.Service;

@Service
public class RagSuggestionService {

    public AssistantSuggestionReply suggest(AssistantSuggestionRequest request) {
        throw new IllegalStateException("RAG suggestion pipeline is not implemented yet");
    }
}
```

- [ ] **Step 4: Modify `AssistantSuggestionService` to delegate**

Replace `AssistantSuggestionService` with:

```java
package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.AssistantSuggestionReply;
import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.example.springbootdemo.rag.RagSuggestionService;
import org.springframework.stereotype.Service;

@Service
public class AssistantSuggestionService {

    private final RagSuggestionService ragSuggestionService;

    public AssistantSuggestionService(RagSuggestionService ragSuggestionService) {
        this.ragSuggestionService = ragSuggestionService;
    }

    public AssistantSuggestionReply suggest(AssistantSuggestionRequest request) {
        return ragSuggestionService.suggest(request);
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:

```powershell
mvn test -Dtest=AssistantSuggestionServiceTest
```

Expected: PASS.

---

### Task 3: Add RAG Configuration

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagSuggestionProperties.java`
- Modify: `D:\SpringBoot\SpringBootDemo\src\main\resources\application.yml`
- Create: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\rag\RagSuggestionPropertiesTest.java`

- [ ] **Step 1: Write a properties binding test**

Create `RagSuggestionPropertiesTest.java`:

```java
package org.example.springbootdemo.rag;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class RagSuggestionPropertiesTest {

    @Test
    void defaultsTargetLocalOpenAiCompatibleServices() {
        RagSuggestionProperties properties = new RagSuggestionProperties();

        assertEquals("http://127.0.0.1:11434/v1/chat/completions", properties.getChatBaseUrl());
        assertEquals("qwen2.5:7b", properties.getChatModel());
        assertEquals("http://127.0.0.1:11434/v1/embeddings", properties.getEmbeddingBaseUrl());
        assertEquals("bge-m3", properties.getEmbeddingModel());
        assertEquals("medical_knowledge", properties.getMilvusCollection());
        assertEquals(6, properties.getTopK());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
mvn test -Dtest=RagSuggestionPropertiesTest
```

Expected: FAIL because `RagSuggestionProperties` does not exist.

- [ ] **Step 3: Implement properties**

Create `RagSuggestionProperties.java`:

```java
package org.example.springbootdemo.rag;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.time.Duration;

@Component
@ConfigurationProperties(prefix = "app.rag")
public class RagSuggestionProperties {

    private String chatBaseUrl = "http://127.0.0.1:11434/v1/chat/completions";
    private String chatApiKey = "";
    private String chatModel = "qwen2.5:7b";
    private String embeddingBaseUrl = "http://127.0.0.1:11434/v1/embeddings";
    private String embeddingApiKey = "";
    private String embeddingModel = "bge-m3";
    private String milvusCollection = "medical_knowledge";
    private int topK = 6;
    private Duration timeout = Duration.ofSeconds(30);

    public String getChatBaseUrl() {
        return chatBaseUrl;
    }

    public void setChatBaseUrl(String chatBaseUrl) {
        this.chatBaseUrl = chatBaseUrl;
    }

    public String getChatApiKey() {
        return chatApiKey;
    }

    public void setChatApiKey(String chatApiKey) {
        this.chatApiKey = chatApiKey;
    }

    public String getChatModel() {
        return chatModel;
    }

    public void setChatModel(String chatModel) {
        this.chatModel = chatModel;
    }

    public String getEmbeddingBaseUrl() {
        return embeddingBaseUrl;
    }

    public void setEmbeddingBaseUrl(String embeddingBaseUrl) {
        this.embeddingBaseUrl = embeddingBaseUrl;
    }

    public String getEmbeddingApiKey() {
        return embeddingApiKey;
    }

    public void setEmbeddingApiKey(String embeddingApiKey) {
        this.embeddingApiKey = embeddingApiKey;
    }

    public String getEmbeddingModel() {
        return embeddingModel;
    }

    public void setEmbeddingModel(String embeddingModel) {
        this.embeddingModel = embeddingModel;
    }

    public String getMilvusCollection() {
        return milvusCollection;
    }

    public void setMilvusCollection(String milvusCollection) {
        this.milvusCollection = milvusCollection;
    }

    public int getTopK() {
        return topK;
    }

    public void setTopK(int topK) {
        this.topK = topK;
    }

    public Duration getTimeout() {
        return timeout;
    }

    public void setTimeout(Duration timeout) {
        this.timeout = timeout;
    }
}
```

- [ ] **Step 4: Add YAML configuration**

In `application.yml`, add:

```yaml
  rag:
    chat-base-url: ${RAG_CHAT_BASE_URL:http://127.0.0.1:11434/v1/chat/completions}
    chat-api-key: ${RAG_CHAT_API_KEY:}
    chat-model: ${RAG_CHAT_MODEL:qwen2.5:7b}
    embedding-base-url: ${RAG_EMBEDDING_BASE_URL:http://127.0.0.1:11434/v1/embeddings}
    embedding-api-key: ${RAG_EMBEDDING_API_KEY:}
    embedding-model: ${RAG_EMBEDDING_MODEL:bge-m3}
    milvus-collection: ${RAG_MILVUS_COLLECTION:medical_knowledge}
    top-k: ${RAG_TOP_K:6}
    timeout: ${RAG_TIMEOUT:30s}
```

Place it under existing `app:` beside `health-ai` and `node-ai`.

- [ ] **Step 5: Run test to verify it passes**

Run:

```powershell
mvn test -Dtest=RagSuggestionPropertiesTest
```

Expected: PASS.

---

### Task 4: Add Prompt Builder

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\KnowledgeHit.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagSuggestionPromptBuilder.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\rag\RagSuggestionPromptBuilderTest.java`

- [ ] **Step 1: Write failing prompt test**

Create `RagSuggestionPromptBuilderTest.java`:

```java
package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertTrue;

class RagSuggestionPromptBuilderTest {

    @Test
    void promptContainsLocationWeatherProfileKnowledgeAndJsonContract() {
        RagSuggestionPromptBuilder builder = new RagSuggestionPromptBuilder();
        AssistantSuggestionRequest request = new AssistantSuggestionRequest(
                "home",
                Map.of("city", "杭州", "condition", "多云", "temperature", "29℃", "humidity", "78%"),
                Map.of("constitution", Map.of("name", "气虚质"))
        );
        KnowledgeHit hit = new KnowledgeHit(
                12L,
                "气虚与疲劳的养生提示",
                "中医体质与日常养生基础",
                "气虚用户应避免过度消耗，可选择散步或八段锦等低强度活动。",
                "气虚,疲劳,八段锦",
                "MEDIUM",
                "KEYWORD",
                0.82
        );

        String prompt = builder.build(request, List.of(hit));

        assertTrue(prompt.contains("场景: home"));
        assertTrue(prompt.contains("城市: 杭州"));
        assertTrue(prompt.contains("天气: 多云"));
        assertTrue(prompt.contains("温度: 29℃"));
        assertTrue(prompt.contains("湿度: 78%"));
        assertTrue(prompt.contains("体质: 气虚质"));
        assertTrue(prompt.contains("气虚与疲劳的养生提示"));
        assertTrue(prompt.contains("只能返回 JSON"));
        assertTrue(prompt.contains("不能诊断疾病"));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
mvn test -Dtest=RagSuggestionPromptBuilderTest
```

Expected: FAIL because `KnowledgeHit` and `RagSuggestionPromptBuilder` do not exist.

- [ ] **Step 3: Implement `KnowledgeHit`**

Create `KnowledgeHit.java`:

```java
package org.example.springbootdemo.rag;

public record KnowledgeHit(
        Long chunkId,
        String title,
        String documentTitle,
        String content,
        String keywords,
        String riskLevel,
        String retrievalType,
        double score
) {
}
```

- [ ] **Step 4: Implement prompt builder**

Create `RagSuggestionPromptBuilder.java`:

```java
package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Component
public class RagSuggestionPromptBuilder {

    public String build(AssistantSuggestionRequest request, List<KnowledgeHit> hits) {
        Map<String, Object> weather = request != null && request.weather() != null ? request.weather() : Map.of();
        Map<String, Object> profile = request != null && request.profile() != null ? request.profile() : Map.of();
        String scenario = text(request != null ? request.scenario() : null, "home");
        String constitution = constitutionName(profile);

        StringBuilder builder = new StringBuilder();
        builder.append("你是一个谨慎的中文养生建议助手。\\n");
        builder.append("只能基于用户上下文和私域知识片段生成日常养生建议，不能诊断疾病，不能替代医生。\\n");
        builder.append("如果出现胸痛、呼吸困难、卒中、高热、自伤等风险信号，必须建议及时就医或急救。\\n");
        builder.append("只能返回 JSON，不要返回 Markdown。JSON 字段必须包含 source, riskLevel, scenario, summary, suggestions, plans, disclaimer。\\n\\n");
        builder.append("用户上下文:\\n");
        builder.append("场景: ").append(scenario).append("\\n");
        builder.append("城市: ").append(text(weather.get("city"), "当前位置")).append("\\n");
        builder.append("天气: ").append(text(weather.get("condition"), "未知")).append("\\n");
        builder.append("温度: ").append(text(weather.get("temperature"), "--")).append("\\n");
        builder.append("湿度: ").append(text(weather.get("humidity"), "--")).append("\\n");
        builder.append("天气风险: ").append(text(weather.get("riskLevel"), "未提供")).append("\\n");
        builder.append("体质: ").append(constitution).append("\\n\\n");
        builder.append("私域知识片段:\\n");
        for (int index = 0; index < hits.size(); index++) {
            KnowledgeHit hit = hits.get(index);
            builder.append(index + 1).append(". [chunkId=").append(hit.chunkId()).append("] ");
            builder.append(hit.title()).append(" / ").append(hit.documentTitle()).append("\\n");
            builder.append("风险等级: ").append(hit.riskLevel()).append(", 召回方式: ").append(hit.retrievalType()).append(", 分数: ").append(hit.score()).append("\\n");
            builder.append(hit.content()).append("\\n");
        }
        builder.append("\\n返回要求:\\n");
        builder.append("- source 固定为 LocalRagLlm。\\n");
        builder.append("- plans 至少包含 morning, afternoon, evening 三个时段中的一个或多个。\\n");
        builder.append("- reason 必须说明使用了天气、体质或知识片段中的哪类依据。\\n");
        builder.append("- disclaimer 必须说明不能替代医生诊断。\\n");
        return builder.toString();
    }

    private String constitutionName(Map<String, Object> profile) {
        Object constitution = profile.get("constitution");
        if (constitution instanceof Map<?, ?> values) {
            return text(values.get("name"), "平和质");
        }
        return "平和质";
    }

    private String text(Object value, String fallback) {
        if (value == null) {
            return fallback;
        }
        String text = String.valueOf(value).trim();
        return text.isEmpty() ? fallback : text;
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:

```powershell
mvn test -Dtest=RagSuggestionPromptBuilderTest
```

Expected: PASS.

---

### Task 5: Add Local LLM Client

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\LocalLlmSuggestionResult.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\LocalLlmClient.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\rag\LocalLlmClientTest.java`

- [ ] **Step 1: Write failing parsing test**

Create `LocalLlmClientTest.java`:

```java
package org.example.springbootdemo.rag;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class LocalLlmClientTest {

    @Test
    void parsesJsonContentFromOpenAiCompatibleResponse() {
        RagSuggestionProperties properties = new RagSuggestionProperties();
        LocalLlmClient client = new LocalLlmClient(properties, new ObjectMapper());
        String content = """
                {"source":"LocalRagLlm","riskLevel":"normal","scenario":"home","summary":"结合私域知识生成。","suggestions":["清淡饮食"],"plans":[{"timeOfDay":"morning","title":"轻早餐","action":"温热清淡","reason":"气虚知识片段"}],"disclaimer":"不能替代医生诊断。"}
                """;

        LocalLlmSuggestionResult result = client.parseContent(content);

        assertEquals("LocalRagLlm", result.source());
        assertEquals("结合私域知识生成。", result.summary());
        assertEquals(List.of("清淡饮食"), result.suggestions());
        assertEquals("轻早餐", result.plans().get(0).get("title"));
    }

    @Test
    void rejectsNonJsonContent() {
        RagSuggestionProperties properties = new RagSuggestionProperties();
        LocalLlmClient client = new LocalLlmClient(properties, new ObjectMapper());

        assertThrows(IllegalStateException.class, () -> client.parseContent("请保持规律作息"));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
mvn test -Dtest=LocalLlmClientTest
```

Expected: FAIL because client/result do not exist.

- [ ] **Step 3: Implement result record**

Create `LocalLlmSuggestionResult.java`:

```java
package org.example.springbootdemo.rag;

import java.util.List;
import java.util.Map;

public record LocalLlmSuggestionResult(
        String source,
        String riskLevel,
        String scenario,
        String summary,
        List<String> suggestions,
        List<Map<String, Object>> plans,
        String disclaimer
) {
}
```

- [ ] **Step 4: Implement LLM client**

Create `LocalLlmClient.java`:

```java
package org.example.springbootdemo.rag;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class LocalLlmClient {

    private final RagSuggestionProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    public LocalLlmClient(RagSuggestionProperties properties, ObjectMapper objectMapper) {
        this(properties, objectMapper, HttpClient.newHttpClient());
    }

    LocalLlmClient(RagSuggestionProperties properties, ObjectMapper objectMapper, HttpClient httpClient) {
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.httpClient = httpClient;
    }

    public LocalLlmSuggestionResult generate(String prompt) {
        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("model", properties.getChatModel());
            payload.put("messages", List.of(Map.of("role", "user", "content", prompt)));
            payload.put("temperature", 0.2);

            HttpRequest.Builder builder = HttpRequest.newBuilder()
                    .uri(URI.create(properties.getChatBaseUrl()))
                    .timeout(properties.getTimeout())
                    .header("Content-Type", "application/json");
            if (properties.getChatApiKey() != null && !properties.getChatApiKey().trim().isEmpty()) {
                builder.header("Authorization", "Bearer " + properties.getChatApiKey().trim());
            }

            HttpResponse<String> response = httpClient.send(
                    builder.POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(payload))).build(),
                    HttpResponse.BodyHandlers.ofString()
            );
            if (response.statusCode() >= 400) {
                throw new IllegalStateException("local LLM returned HTTP " + response.statusCode());
            }
            JsonNode root = objectMapper.readTree(response.body());
            String content = root.path("choices").path(0).path("message").path("content").asText("");
            if (content.isBlank()) {
                throw new IllegalStateException("local LLM response has no message content");
            }
            return parseContent(content);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("local LLM request interrupted", exception);
        } catch (IOException exception) {
            throw new IllegalStateException("local LLM request failed", exception);
        }
    }

    LocalLlmSuggestionResult parseContent(String content) {
        try {
            String json = extractJson(content);
            return objectMapper.readValue(json, LocalLlmSuggestionResult.class);
        } catch (IOException exception) {
            throw new IllegalStateException("local LLM did not return valid suggestion JSON", exception);
        }
    }

    private String extractJson(String content) {
        String trimmed = content == null ? "" : content.trim();
        if (trimmed.startsWith("```")) {
            trimmed = trimmed.replaceFirst("(?i)^```json\\s*", "")
                    .replaceFirst("^```\\s*", "")
                    .replaceFirst("```$", "")
                    .trim();
        }
        int start = trimmed.indexOf('{');
        int end = trimmed.lastIndexOf('}');
        if (start < 0 || end <= start) {
            throw new IllegalStateException("local LLM did not return JSON object");
        }
        return trimmed.substring(start, end + 1);
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:

```powershell
mvn test -Dtest=LocalLlmClientTest
```

Expected: PASS.

---

### Task 6: Add Knowledge Retrieval

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\KnowledgeRetrievalService.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\rag\KnowledgeRetrievalServiceTest.java`

- [ ] **Step 1: Write failing retrieval tests**

Create `KnowledgeRetrievalServiceTest.java`:

```java
package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class KnowledgeRetrievalServiceTest {

    @Test
    void buildsQueryTextFromScenarioWeatherAndProfile() {
        KnowledgeRetrievalService service = new KnowledgeRetrievalService(mock(JdbcTemplate.class), new RagSuggestionProperties());
        AssistantSuggestionRequest request = new AssistantSuggestionRequest(
                "home",
                Map.of("city", "杭州", "condition", "多云", "temperature", "29℃", "humidity", "78%"),
                Map.of("constitution", Map.of("name", "气虚质"))
        );

        String query = service.buildQueryText(request);

        assertTrue(query.contains("home"));
        assertTrue(query.contains("杭州"));
        assertTrue(query.contains("78%"));
        assertTrue(query.contains("气虚质"));
    }

    @Test
    void retrievesKeywordKnowledgeHits() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        RagSuggestionProperties properties = new RagSuggestionProperties();
        KnowledgeRetrievalService service = new KnowledgeRetrievalService(jdbcTemplate, properties);
        when(jdbcTemplate.query(anyString(), any(org.springframework.jdbc.core.RowMapper.class), anyString(), eq(6)))
                .thenReturn(List.of(new KnowledgeHit(
                        12L,
                        "气虚与疲劳的养生提示",
                        "中医体质与日常养生基础",
                        "气虚用户可选择散步或八段锦。",
                        "气虚,疲劳",
                        "MEDIUM",
                        "KEYWORD",
                        0.6
                )));

        List<KnowledgeHit> hits = service.retrieveKeywordHits("气虚 杭州 湿度 78%");

        assertEquals(1, hits.size());
        assertEquals(12L, hits.get(0).chunkId());
        assertEquals("KEYWORD", hits.get(0).retrievalType());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
mvn test -Dtest=KnowledgeRetrievalServiceTest
```

Expected: FAIL because `KnowledgeRetrievalService` does not exist.

- [ ] **Step 3: Implement keyword retrieval**

Create `KnowledgeRetrievalService.java`:

```java
package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class KnowledgeRetrievalService {

    private final JdbcTemplate jdbcTemplate;
    private final RagSuggestionProperties properties;

    public KnowledgeRetrievalService(JdbcTemplate jdbcTemplate, RagSuggestionProperties properties) {
        this.jdbcTemplate = jdbcTemplate;
        this.properties = properties;
    }

    public List<KnowledgeHit> retrieve(AssistantSuggestionRequest request) {
        return retrieveKeywordHits(buildQueryText(request));
    }

    String buildQueryText(AssistantSuggestionRequest request) {
        Map<String, Object> weather = request != null && request.weather() != null ? request.weather() : Map.of();
        Map<String, Object> profile = request != null && request.profile() != null ? request.profile() : Map.of();
        return String.join(" ",
                text(request != null ? request.scenario() : null, "home"),
                text(weather.get("city"), "当前位置"),
                text(weather.get("condition"), ""),
                text(weather.get("temperature"), ""),
                text(weather.get("humidity"), ""),
                text(weather.get("riskLevel"), ""),
                constitutionName(profile)
        ).trim();
    }

    List<KnowledgeHit> retrieveKeywordHits(String queryText) {
        String likePattern = "%" + queryText.replace(" ", "%") + "%";
        return jdbcTemplate.query(
                """
                        SELECT c.id AS chunk_id,
                               c.title AS title,
                               d.title AS document_title,
                               c.content AS content,
                               c.keywords AS keywords,
                               c.risk_level AS risk_level
                        FROM medical_knowledge_chunk c
                        JOIN medical_knowledge_document d ON d.id = c.document_id
                        WHERE c.enabled = 1
                          AND d.status = 'ACTIVE'
                          AND (c.title LIKE ? OR c.content LIKE ? OR c.keywords LIKE ?)
                        ORDER BY c.risk_level DESC, c.sort_order ASC
                        LIMIT ?
                        """,
                (rs, rowNum) -> new KnowledgeHit(
                        rs.getLong("chunk_id"),
                        rs.getString("title"),
                        rs.getString("document_title"),
                        rs.getString("content"),
                        rs.getString("keywords"),
                        rs.getString("risk_level"),
                        "KEYWORD",
                        0.6
                ),
                likePattern,
                likePattern,
                likePattern,
                properties.getTopK()
        );
    }

    private String constitutionName(Map<String, Object> profile) {
        Object constitution = profile.get("constitution");
        if (constitution instanceof Map<?, ?> values) {
            return text(values.get("name"), "平和质");
        }
        return "平和质";
    }

    private String text(Object value, String fallback) {
        if (value == null) {
            return fallback;
        }
        String text = String.valueOf(value).trim();
        return text.isEmpty() ? fallback : text;
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```powershell
mvn test -Dtest=KnowledgeRetrievalServiceTest
```

Expected: PASS.

---

### Task 7: Add Milvus Interface And Reference DTO

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\MilvusVectorClient.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\NoopMilvusVectorClient.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\SuggestionReference.java`

- [ ] **Step 1: Add the vector client interface**

Create `MilvusVectorClient.java`:

```java
package org.example.springbootdemo.rag;

import java.util.List;

public interface MilvusVectorClient {

    List<KnowledgeHit> search(String queryText);
}
```

- [ ] **Step 2: Add the phase-1 no-op implementation**

Create `NoopMilvusVectorClient.java`:

```java
package org.example.springbootdemo.rag;

import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class NoopMilvusVectorClient implements MilvusVectorClient {

    @Override
    public List<KnowledgeHit> search(String queryText) {
        return List.of();
    }
}
```

- [ ] **Step 3: Add reference DTO**

Create `SuggestionReference.java`:

```java
package org.example.springbootdemo.rag;

import java.util.LinkedHashMap;
import java.util.Map;

public record SuggestionReference(
        Long chunkId,
        String title,
        String documentTitle,
        String retrievalType,
        double score
) {
    public Map<String, Object> toMap() {
        Map<String, Object> value = new LinkedHashMap<>();
        value.put("chunkId", chunkId);
        value.put("title", title);
        value.put("documentTitle", documentTitle);
        value.put("retrievalType", retrievalType);
        value.put("score", score);
        return value;
    }

    public static SuggestionReference from(KnowledgeHit hit) {
        return new SuggestionReference(hit.chunkId(), hit.title(), hit.documentTitle(), hit.retrievalType(), hit.score());
    }
}
```

- [ ] **Step 4: Compile**

Run:

```powershell
mvn test -Dtest=RagSuggestionPromptBuilderTest,KnowledgeRetrievalServiceTest
```

Expected: PASS.

---

### Task 8: Add Retrieval Logging Service

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagRetrievalLogService.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\rag\RagRetrievalLogServiceTest.java`

- [ ] **Step 1: Write failing logging test**

Create `RagRetrievalLogServiceTest.java`:

```java
package org.example.springbootdemo.rag;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class RagRetrievalLogServiceTest {

    @Test
    void logsSearchAndRetrievalResults() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        RagRetrievalLogService service = new RagRetrievalLogService(jdbcTemplate);
        KnowledgeHit hit = new KnowledgeHit(12L, "title", "document", "content", "keywords", "LOW", "KEYWORD", 0.6);

        service.logSearch(null, "home 杭州 气虚", List.of(hit));

        verify(jdbcTemplate).update(
                eq("INSERT INTO medical_knowledge_search_log (user_id, query_text, matched_chunk_ids, scene, requester_role) VALUES (?, ?, ?, ?, ?)"),
                any(), eq("home 杭州 气虚"), eq("12"), eq("APP_SEARCH"), eq("USER")
        );
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
mvn test -Dtest=RagRetrievalLogServiceTest
```

Expected: FAIL because service does not exist.

- [ ] **Step 3: Implement logging service**

Create `RagRetrievalLogService.java`:

```java
package org.example.springbootdemo.rag;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class RagRetrievalLogService {

    private final JdbcTemplate jdbcTemplate;

    public RagRetrievalLogService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void logSearch(Long userId, String queryText, List<KnowledgeHit> hits) {
        String matchedChunkIds = hits.stream()
                .map(KnowledgeHit::chunkId)
                .map(String::valueOf)
                .collect(Collectors.joining(","));
        jdbcTemplate.update(
                "INSERT INTO medical_knowledge_search_log (user_id, query_text, matched_chunk_ids, scene, requester_role) VALUES (?, ?, ?, ?, ?)",
                userId,
                queryText,
                matchedChunkIds,
                "APP_SEARCH",
                "USER"
        );
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```powershell
mvn test -Dtest=RagRetrievalLogServiceTest
```

Expected: PASS.

---

### Task 9: Implement RAG Suggestion Orchestration

**Files:**
- Modify: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagSuggestionService.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\rag\RagSuggestionServiceTest.java`

- [ ] **Step 1: Write failing orchestration test**

Create `RagSuggestionServiceTest.java`:

```java
package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionReply;
import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class RagSuggestionServiceTest {

    @Test
    void generatesSuggestionFromPrivateKnowledgeAndLocalLlm() {
        KnowledgeRetrievalService retrievalService = mock(KnowledgeRetrievalService.class);
        MilvusVectorClient vectorClient = mock(MilvusVectorClient.class);
        RagSuggestionPromptBuilder promptBuilder = mock(RagSuggestionPromptBuilder.class);
        LocalLlmClient llmClient = mock(LocalLlmClient.class);
        RagRetrievalLogService logService = mock(RagRetrievalLogService.class);
        RagSuggestionService service = new RagSuggestionService(retrievalService, vectorClient, promptBuilder, llmClient, logService);
        AssistantSuggestionRequest request = new AssistantSuggestionRequest(
                "home",
                Map.of("city", "杭州", "humidity", "78%"),
                Map.of("constitution", Map.of("name", "气虚质"))
        );
        KnowledgeHit hit = new KnowledgeHit(12L, "气虚与疲劳", "私域知识", "气虚建议低强度活动", "气虚", "LOW", "KEYWORD", 0.7);
        when(retrievalService.retrieve(request)).thenReturn(List.of(hit));
        when(vectorClient.search(anyString())).thenReturn(List.of());
        when(retrievalService.buildQueryText(request)).thenReturn("home 杭州 78% 气虚质");
        when(promptBuilder.build(request, List.of(hit))).thenReturn("prompt");
        when(llmClient.generate("prompt")).thenReturn(new LocalLlmSuggestionResult(
                "LocalRagLlm",
                "normal",
                "home",
                "结合私域知识生成建议。",
                List.of("低强度活动"),
                List.of(Map.of("timeOfDay", "morning", "title", "轻活动")),
                "不能替代医生诊断。"
        ));

        AssistantSuggestionReply reply = service.suggest(request);

        assertEquals("LocalRagLlm", reply.source());
        assertEquals("结合私域知识生成建议。", reply.summary());
        assertEquals("KEYWORD_ONLY", reply.retrievalStatus());
        assertFalse(reply.references().isEmpty());
        verify(logService).logSearch(null, "home 杭州 78% 气虚质", List.of(hit));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
mvn test -Dtest=RagSuggestionServiceTest
```

Expected: FAIL because `RagSuggestionService` is still a skeleton.

- [ ] **Step 3: Implement orchestration**

Replace `RagSuggestionService.java` with:

```java
package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionReply;
import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class RagSuggestionService {

    private final KnowledgeRetrievalService retrievalService;
    private final MilvusVectorClient vectorClient;
    private final RagSuggestionPromptBuilder promptBuilder;
    private final LocalLlmClient llmClient;
    private final RagRetrievalLogService logService;

    public RagSuggestionService(
            KnowledgeRetrievalService retrievalService,
            MilvusVectorClient vectorClient,
            RagSuggestionPromptBuilder promptBuilder,
            LocalLlmClient llmClient,
            RagRetrievalLogService logService
    ) {
        this.retrievalService = retrievalService;
        this.vectorClient = vectorClient;
        this.promptBuilder = promptBuilder;
        this.llmClient = llmClient;
        this.logService = logService;
    }

    public AssistantSuggestionReply suggest(AssistantSuggestionRequest request) {
        String queryText = retrievalService.buildQueryText(request);
        List<KnowledgeHit> keywordHits = retrievalService.retrieve(request);
        List<KnowledgeHit> vectorHits = vectorClient.search(queryText);
        List<KnowledgeHit> mergedHits = merge(keywordHits, vectorHits);
        String prompt = promptBuilder.build(request, mergedHits);
        LocalLlmSuggestionResult result = llmClient.generate(prompt);
        logService.logSearch(null, queryText, mergedHits);

        return new AssistantSuggestionReply(
                text(result.source(), "LocalRagLlm"),
                text(result.riskLevel(), "normal"),
                text(result.scenario(), request != null && request.scenario() != null ? request.scenario() : "home"),
                text(result.summary(), ""),
                result.suggestions() == null ? List.of() : result.suggestions(),
                result.plans() == null ? List.of() : result.plans(),
                text(result.disclaimer(), "本建议不能替代医生诊断，若症状持续或加重，请及时就医。"),
                mergedHits.stream().map(SuggestionReference::from).map(SuggestionReference::toMap).toList(),
                vectorHits.isEmpty() ? "KEYWORD_ONLY" : "HYBRID"
        );
    }

    private List<KnowledgeHit> merge(List<KnowledgeHit> keywordHits, List<KnowledgeHit> vectorHits) {
        Map<Long, KnowledgeHit> merged = new LinkedHashMap<>();
        for (KnowledgeHit hit : keywordHits == null ? List.<KnowledgeHit>of() : keywordHits) {
            merged.put(hit.chunkId(), hit);
        }
        for (KnowledgeHit hit : vectorHits == null ? List.<KnowledgeHit>of() : vectorHits) {
            merged.putIfAbsent(hit.chunkId(), hit);
        }
        return new ArrayList<>(merged.values());
    }

    private String text(String value, String fallback) {
        if (value == null || value.trim().isEmpty()) {
            return fallback;
        }
        return value.trim();
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```powershell
mvn test -Dtest=RagSuggestionServiceTest
```

Expected: PASS.

---

### Task 10: Return 503 For Local LLM Failure

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagSuggestionUnavailableException.java`
- Modify: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\rag\RagSuggestionService.java`
- Modify: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\controller\AssistantController.java`
- Modify: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\controller\AssistantControllerTest.java`

- [ ] **Step 1: Write failing controller test**

Add to `AssistantControllerTest`:

```java
@Test
void suggestionsReturnsUnavailableWhenRagServiceFails() throws Exception {
    when(assistantSuggestionService.suggest(any())).thenThrow(
            new org.example.springbootdemo.rag.RagSuggestionUnavailableException("local LLM unavailable")
    );

    mockMvc.perform(authPost("/api/ai/suggestions")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("""
                            {"scenario":"home","weather":{},"profile":{}}
                            """))
            .andExpect(status().isServiceUnavailable())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("local LLM unavailable"));
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
mvn test -Dtest=AssistantControllerTest#suggestionsReturnsUnavailableWhenRagServiceFails
```

Expected: FAIL because exception class and controller handling do not exist.

- [ ] **Step 3: Create exception**

Create `RagSuggestionUnavailableException.java`:

```java
package org.example.springbootdemo.rag;

public class RagSuggestionUnavailableException extends RuntimeException {

    public RagSuggestionUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }

    public RagSuggestionUnavailableException(String message) {
        super(message);
    }
}
```

- [ ] **Step 4: Wrap LLM failures in RAG service**

In `RagSuggestionService.suggest`, wrap `llmClient.generate(prompt)`:

```java
LocalLlmSuggestionResult result;
try {
    result = llmClient.generate(prompt);
} catch (RuntimeException exception) {
    throw new RagSuggestionUnavailableException("local LLM unavailable", exception);
}
```

- [ ] **Step 5: Handle exception in controller**

In `AssistantController.suggestions`, change:

```java
return ResponseEntity.ok(assistantSuggestionService.suggest(request));
```

to:

```java
try {
    return ResponseEntity.ok(assistantSuggestionService.suggest(request));
} catch (org.example.springbootdemo.rag.RagSuggestionUnavailableException exception) {
    return error(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage());
}
```

- [ ] **Step 6: Run test to verify it passes**

Run:

```powershell
mvn test -Dtest=AssistantControllerTest#suggestionsReturnsUnavailableWhenRagServiceFails
```

Expected: PASS.

---

### Task 11: Run Focused And Full Verification

**Files:**
- All files touched above.

- [ ] **Step 1: Run focused RAG tests**

Run:

```powershell
mvn test -Dtest=AssistantSuggestionServiceTest,RagSuggestionPropertiesTest,RagSuggestionPromptBuilderTest,LocalLlmClientTest,KnowledgeRetrievalServiceTest,RagRetrievalLogServiceTest,RagSuggestionServiceTest
```

Expected: PASS.

- [ ] **Step 2: Run controller tests**

Run:

```powershell
mvn test -Dtest=AssistantControllerTest
```

Expected: PASS.

- [ ] **Step 3: Run full backend tests**

Run:

```powershell
mvn test
```

Expected: PASS.

- [ ] **Step 4: Manual runtime smoke test**

Start local LLM and Spring Boot, then call:

```powershell
Invoke-RestMethod -Method Post `
  -Uri http://127.0.0.1:8181/api/ai/suggestions `
  -Headers @{ Authorization = "Bearer <APP_TOKEN>" } `
  -ContentType "application/json" `
  -Body '{"scenario":"home","weather":{"city":"杭州","condition":"多云","temperature":"29℃","humidity":"78%"},"profile":{"constitution":{"name":"气虚质"}}}'
```

Expected:

- HTTP 200 when local LLM is available.
- `source` is `LocalRagLlm`.
- `retrievalStatus` is `KEYWORD_ONLY` in phase 1.
- `references` contains retrieved private knowledge chunks if seed data matches the query.
- HTTP 503 when local LLM is unavailable.

---

## Self-Review Checklist

- Spec coverage:
  - Spring Boot unified entry: Task 2.
  - No written fallback: Tasks 2, 9, 10.
  - MySQL private knowledge retrieval: Task 6.
  - Milvus-ready interface: Task 7.
  - Local LLM generation: Task 5 and Task 9.
  - Traceable references: Task 1, Task 7, Task 9.
  - Retrieval logs: Task 8 and Task 9.
  - Error handling for LLM unavailable: Task 10.
- Placeholder scan:
  - No `TBD`, `TODO`, or unspecified implementation steps.
- Type consistency:
  - `KnowledgeHit`, `SuggestionReference`, `LocalLlmSuggestionResult`, and `AssistantSuggestionReply` fields are used consistently across tasks.
