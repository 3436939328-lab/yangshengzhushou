# Node AI Orchestration Into Spring Boot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `D:\SpringBoot\SpringBootDemo` the only AI entrypoint for the HarmonyOS APP while preserving the existing Node.js `LLM / Prompt / LangGraph` orchestration as the first-phase internal engine.

**Architecture:** Spring Boot adds an internal orchestration client that calls the existing Node AI endpoints, wraps them behind Spring services, and exposes APP-compatible chat and suggestion endpoints under the Spring Boot server. The current PC flow keeps using `HealthQuestionController`, but that service is rewired to the same orchestration bridge so APP and PC begin sharing one AI backend path without rewriting the Node graph first.

**Tech Stack:** Spring Boot 3, Java 17 `HttpClient`, Jackson, existing MyBatis service layer, HarmonyOS ArkTS `@kit.NetworkKit`, HarmonyOS Preferences auth session.

---

## Planned File Structure

- `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\NodeAiOrchestrationProperties.java`
  Spring Boot configuration for the internal Node AI bridge.
- `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\AssistantChatRequest.java`
  APP-compatible AI chat request contract.
- `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\AssistantChatReply.java`
  Normalized AI chat response with `reply`, `source`, `riskLevel`, `suggestions`, `plan`, `disclaimer`.
- `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\AssistantSuggestionRequest.java`
  APP-compatible weather-aware suggestion request contract.
- `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\AssistantSuggestionReply.java`
  Normalized suggestion response for APP scene cards.
- `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\NodeAssistantOrchestrationClient.java`
  Internal HTTP client that calls the current Node `/api/ai/chat` and `/api/ai/suggestions`.
- `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\service\AssistantChatService.java`
  Service facade for APP chat requests, including fallback to current Java AI path.
- `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\service\AssistantSuggestionService.java`
  Service facade for APP suggestion requests.
- `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\controller\AssistantController.java`
  Spring Boot controller for `/api/ai/chat`, `/api/assistant/chat`, `/api/ai/suggestions`, `/api/suggestions/scene`.
- `D:\SpringBoot\SpringBootDemo\src\main\resources\application.yml`
  Adds internal Node orchestration URL and timeout config.
- `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\service\HealthQuestionAiService.java`
  Rewired to use the new bridge so PC `health-question` keeps working.
- `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\service\AssistantChatServiceTest.java`
  New service-level fallback tests.
- `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\controller\AssistantControllerTest.java`
  New controller tests for APP-compatible endpoints.
- `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\service\HealthQuestionAiServiceTest.java`
  Updated to verify existing PC flow still uses the bridge.
- `D:\yangshengzhushou\entry\src\main\ets\services\ApiConfig.ets`
  Adds split routing so APP AI/suggestions can move to Spring Boot before weather moves.
- `D:\yangshengzhushou\entry\src\main\ets\services\AuthService.ets`
  Adds runtime token access helpers for authorized AI requests.
- `D:\yangshengzhushou\entry\src\main\ets\services\BackendStatusService.ets`
  Stops using the Node health probe as the AI backend source of truth.
- `D:\yangshengzhushou\entry\src\main\ets\services\AssistantReplyService.ets`
  Sends AI chat to Spring Boot with `Authorization`.
- `D:\yangshengzhushou\entry\src\main\ets\services\SuggestionService.ets`
  Sends scene suggestions to Spring Boot with `Authorization`.
- `D:\yangshengzhushou\entry\src\main\ets\pages\Index.ets`
  Pushes the current auth session token into runtime request helpers on load/login/logout.
- `D:\yangshengzhushou\entry\src\test\LocalUnit.test.ets`
  Adds pure tests for API URL splitting and auth header helpers.

This plan does **not** refactor `D:\SpringBoot\SpringBootVue\Sprintvue` yet. PC stays compatible through the existing `HealthQuestionController` flow in this phase.

### Task 1: Add The Spring Boot Internal Node AI Bridge

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\NodeAiOrchestrationProperties.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\AssistantChatRequest.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\AssistantChatReply.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\AssistantSuggestionRequest.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\AssistantSuggestionReply.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\ai\NodeAssistantOrchestrationClient.java`
- Modify: `D:\SpringBoot\SpringBootDemo\src\main\resources\application.yml`
- Test: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\service\AssistantChatServiceTest.java`

- [ ] **Step 1: Write the failing fallback-first service test**

```java
package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.AssistantChatReply;
import org.example.springbootdemo.ai.AssistantChatRequest;
import org.example.springbootdemo.ai.NodeAssistantOrchestrationClient;
import org.example.springbootdemo.bean.HealthQuestion;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;

class AssistantChatServiceTest {

    @Test
    void chatUsesNodeReplyWhenBridgeIsAvailable() {
        NodeAssistantOrchestrationClient nodeClient = mock(NodeAssistantOrchestrationClient.class);
        HealthQuestionPromptBuilderAdapter fallbackAdapter = mock(HealthQuestionPromptBuilderAdapter.class);
        AssistantChatService service = new AssistantChatService(nodeClient, fallbackAdapter);

        AssistantChatRequest request = new AssistantChatRequest(
                "最近睡不好",
                null,
                null,
                List.of()
        );
        AssistantChatReply nodeReply = new AssistantChatReply(
                "建议固定作息",
                "DeepSeek",
                "normal",
                List.of("规律作息"),
                List.of(),
                "本建议不能替代医生诊断，若症状持续或加重，请及时就医。"
        );
        when(nodeClient.chat(request)).thenReturn(nodeReply);

        AssistantChatReply result = service.chat(request, List.of());

        assertEquals("建议固定作息", result.reply());
        verify(nodeClient).chat(request);
        verifyNoInteractions(fallbackAdapter);
    }

    @Test
    void chatFallsBackToJavaPathWhenNodeBridgeFails() {
        NodeAssistantOrchestrationClient nodeClient = mock(NodeAssistantOrchestrationClient.class);
        HealthQuestionPromptBuilderAdapter fallbackAdapter = mock(HealthQuestionPromptBuilderAdapter.class);
        AssistantChatService service = new AssistantChatService(nodeClient, fallbackAdapter);

        AssistantChatRequest request = new AssistantChatRequest(
                "最近睡不好",
                null,
                null,
                List.of()
        );
        when(nodeClient.chat(request)).thenThrow(new IllegalStateException("node down"));
        when(fallbackAdapter.generateReply("最近睡不好", List.of())).thenReturn(
                new AssistantChatReply(
                        "当前 AI 服务暂未返回结果。",
                        "SpringBootFallback",
                        "normal",
                        List.of("规律作息"),
                        List.of(),
                        "本建议不能替代医生诊断，若症状持续或加重，请及时就医。"
                )
        );

        AssistantChatReply result = service.chat(request, List.of());

        assertEquals("SpringBootFallback", result.source());
        verify(nodeClient).chat(request);
        verify(fallbackAdapter).generateReply("最近睡不好", List.of());
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```powershell
mvn -Dtest=AssistantChatServiceTest test
```

Expected:

```text
FAILURE ... cannot find symbol AssistantChatService / NodeAssistantOrchestrationClient / AssistantChatReply
```

- [ ] **Step 3: Write the minimal bridge contracts and service**

```java
package org.example.springbootdemo.ai;

import java.util.List;
import java.util.Map;

public record AssistantChatRequest(
        String message,
        Map<String, Object> profile,
        Map<String, Object> weather,
        List<Map<String, Object>> history
) {}
```

```java
package org.example.springbootdemo.ai;

import java.util.List;
import java.util.Map;

public record AssistantChatReply(
        String reply,
        String source,
        String riskLevel,
        List<String> suggestions,
        List<Map<String, Object>> plan,
        String disclaimer
) {}
```

```java
package org.example.springbootdemo.ai;

import java.util.Map;

public record AssistantSuggestionRequest(
        String scenario,
        Map<String, Object> weather,
        Map<String, Object> profile
) {}
```

```java
package org.example.springbootdemo.ai;

import java.util.List;
import java.util.Map;

public record AssistantSuggestionReply(
        String source,
        String riskLevel,
        String scenario,
        String summary,
        List<String> suggestions,
        List<Map<String, Object>> plans,
        String disclaimer
) {}
```

```java
package org.example.springbootdemo.ai;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.node-ai")
public class NodeAiOrchestrationProperties {
    private String baseUrl = "http://127.0.0.1:8787";
    private int timeoutMs = 6000;

    public String getBaseUrl() { return baseUrl; }
    public void setBaseUrl(String baseUrl) { this.baseUrl = baseUrl; }
    public int getTimeoutMs() { return timeoutMs; }
    public void setTimeoutMs(int timeoutMs) { this.timeoutMs = timeoutMs; }
}
```

```java
package org.example.springbootdemo.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

@Component
public class NodeAssistantOrchestrationClient {

    private final NodeAiOrchestrationProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient = HttpClient.newHttpClient();

    public NodeAssistantOrchestrationClient(NodeAiOrchestrationProperties properties, ObjectMapper objectMapper) {
        this.properties = properties;
        this.objectMapper = objectMapper;
    }

    public AssistantChatReply chat(AssistantChatRequest request) {
        try {
            HttpRequest httpRequest = HttpRequest.newBuilder()
                    .uri(URI.create(properties.getBaseUrl() + "/api/ai/chat"))
                    .timeout(Duration.ofMillis(properties.getTimeoutMs()))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(request)))
                    .build();
            HttpResponse<String> response = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 400) {
                throw new IllegalStateException("node chat failed");
            }
            return objectMapper.readValue(response.body(), AssistantChatReply.class);
        } catch (Exception exception) {
            throw new IllegalStateException("node orchestration unavailable", exception);
        }
    }

    public AssistantSuggestionReply suggest(AssistantSuggestionRequest request) {
        try {
            HttpRequest httpRequest = HttpRequest.newBuilder()
                    .uri(URI.create(properties.getBaseUrl() + "/api/ai/suggestions"))
                    .timeout(Duration.ofMillis(properties.getTimeoutMs()))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(request)))
                    .build();
            HttpResponse<String> response = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 400) {
                throw new IllegalStateException("node suggestion failed");
            }
            return objectMapper.readValue(response.body(), AssistantSuggestionReply.class);
        } catch (Exception exception) {
            throw new IllegalStateException("node suggestion unavailable", exception);
        }
    }
}
```

```java
package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.AssistantChatReply;
import org.example.springbootdemo.ai.AssistantChatRequest;
import org.example.springbootdemo.ai.NodeAssistantOrchestrationClient;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AssistantChatService {

    private final NodeAssistantOrchestrationClient nodeClient;
    private final HealthQuestionPromptBuilderAdapter fallbackAdapter;

    public AssistantChatService(NodeAssistantOrchestrationClient nodeClient, HealthQuestionPromptBuilderAdapter fallbackAdapter) {
        this.nodeClient = nodeClient;
        this.fallbackAdapter = fallbackAdapter;
    }

    public AssistantChatReply chat(AssistantChatRequest request, List<?> history) {
        try {
            return nodeClient.chat(request);
        } catch (RuntimeException exception) {
            return fallbackAdapter.generateReply(request.message(), history);
        }
    }
}
```

```yaml
app:
  node-ai:
    base-url: ${NODE_AI_BASE_URL:http://127.0.0.1:8787}
    timeout-ms: ${NODE_AI_TIMEOUT_MS:6000}
```

- [ ] **Step 4: Run the test to verify it passes**

Run:

```powershell
mvn -Dtest=AssistantChatServiceTest test
```

Expected:

```text
BUILD SUCCESS
Tests run: 2, Failures: 0, Errors: 0
```

- [ ] **Step 5: Commit the Spring Boot bridge contract**

```powershell
git -C D:\SpringBoot\SpringBootDemo add src/main/java/org/example/springbootdemo/ai src/main/java/org/example/springbootdemo/service/AssistantChatService.java src/main/resources/application.yml src/test/java/org/example/springbootdemo/service/AssistantChatServiceTest.java
git -C D:\SpringBoot\SpringBootDemo commit -m "feat: add node ai orchestration bridge"
```

### Task 2: Rewire The Existing Spring Boot `health-question` Flow To The Bridge

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\service\HealthQuestionPromptBuilderAdapter.java`
- Modify: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\service\HealthQuestionAiService.java`
- Modify: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\service\HealthQuestionAiServiceTest.java`

- [ ] **Step 1: Write the failing compatibility test**

```java
@Test
void askQuestionDelegatesToAssistantChatServiceAndStillWritesBackAnswer() {
    HealthQuestionService healthQuestionService = mock(HealthQuestionService.class);
    AssistantChatService assistantChatService = mock(AssistantChatService.class);
    HealthQuestionAiService aiService = new HealthQuestionAiService(healthQuestionService, assistantChatService);

    HealthQuestion previous = new HealthQuestion();
    previous.setId(1L);
    previous.setUserId(3L);
    previous.setQuestion("最近睡眠不好怎么办？");
    previous.setAnswer("早点休息");
    previous.setStatus((byte) 1);
    when(healthQuestionService.listHealthQuestions(3L)).thenReturn(List.of(previous));
    when(assistantChatService.chat(any(), eq(List.of(previous)))).thenReturn(
            new AssistantChatReply(
                    "建议固定作息，睡前放下手机。",
                    "DeepSeek",
                    "normal",
                    List.of("规律作息"),
                    List.of(),
                    "本建议不能替代医生诊断，若症状持续或加重，请及时就医。"
            )
    );

    doAnswer(invocation -> {
        HealthQuestion record = invocation.getArgument(0);
        record.setId(9L);
        return 1;
    }).when(healthQuestionService).addHealthQuestion(any(HealthQuestion.class));
    when(healthQuestionService.answerHealthQuestion(any(HealthQuestion.class))).thenReturn(1);

    HealthQuestion question = new HealthQuestion();
    question.setUserId(3L);
    question.setQuestion("最近还是睡不好");

    HealthQuestion result = aiService.askQuestion(question);

    assertEquals("建议固定作息，睡前放下手机。", result.getAnswer());
    verify(assistantChatService).chat(any(), eq(List.of(previous)));
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```powershell
mvn -Dtest=HealthQuestionAiServiceTest test
```

Expected:

```text
FAILURE ... constructor HealthQuestionAiService(...) cannot be applied to given types
```

- [ ] **Step 3: Implement the adapter and service rewiring**

```java
package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.*;
import org.example.springbootdemo.bean.HealthQuestion;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class HealthQuestionPromptBuilderAdapter {

    private final HealthQuestionAiClient aiClient;
    private final HealthQuestionPromptBuilder promptBuilder;

    public HealthQuestionPromptBuilderAdapter(HealthQuestionAiClient aiClient, HealthQuestionPromptBuilder promptBuilder) {
        this.aiClient = aiClient;
        this.promptBuilder = promptBuilder;
    }

    public AssistantChatReply generateReply(String question, List<?> history) {
        @SuppressWarnings("unchecked")
        List<HealthQuestion> typedHistory = (List<HealthQuestion>) history;
        String answer = aiClient.generateAnswer(promptBuilder.build(typedHistory, question));
        return new AssistantChatReply(
                answer,
                "SpringBootFallback",
                "normal",
                List.of("规律作息", "清淡饮食", "温和运动"),
                List.of(),
                "本建议不能替代医生诊断，若症状持续或加重，请及时就医。"
        );
    }
}
```

```java
package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.AssistantChatReply;
import org.example.springbootdemo.ai.AssistantChatRequest;
import org.example.springbootdemo.bean.HealthQuestion;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class HealthQuestionAiService {

    private final HealthQuestionService healthQuestionService;
    private final AssistantChatService assistantChatService;

    public HealthQuestionAiService(HealthQuestionService healthQuestionService, AssistantChatService assistantChatService) {
        this.healthQuestionService = healthQuestionService;
        this.assistantChatService = assistantChatService;
    }

    public HealthQuestion askQuestion(HealthQuestion healthQuestion) {
        if (healthQuestion == null || healthQuestion.getUserId() == null) {
            throw new IllegalArgumentException("userId is required");
        }
        if (healthQuestion.getQuestion() == null || healthQuestion.getQuestion().trim().isEmpty()) {
            throw new IllegalArgumentException("question is required");
        }

        List<HealthQuestion> history = healthQuestionService.listHealthQuestions(healthQuestion.getUserId());
        healthQuestion.setStatus((byte) 0);
        healthQuestionService.addHealthQuestion(healthQuestion);

        AssistantChatReply reply = assistantChatService.chat(
                new AssistantChatRequest(healthQuestion.getQuestion(), Map.of(), Map.of(), List.of()),
                history
        );

        healthQuestion.setAnswer(reply.reply());
        healthQuestionService.answerHealthQuestion(healthQuestion);
        return healthQuestion;
    }
}
```

- [ ] **Step 4: Run the compatibility tests**

Run:

```powershell
mvn -Dtest=HealthQuestionAiServiceTest test
```

Expected:

```text
BUILD SUCCESS
Tests run: 1+, Failures: 0, Errors: 0
```

- [ ] **Step 5: Commit the PC-compatible bridge rewiring**

```powershell
git -C D:\SpringBoot\SpringBootDemo add src/main/java/org/example/springbootdemo/service/HealthQuestionAiService.java src/main/java/org/example/springbootdemo/service/HealthQuestionPromptBuilderAdapter.java src/test/java/org/example/springbootdemo/service/HealthQuestionAiServiceTest.java
git -C D:\SpringBoot\SpringBootDemo commit -m "refactor: route health question ai through orchestration bridge"
```

### Task 3: Add APP-Compatible Spring Boot AI Chat And Suggestion Endpoints

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\controller\AssistantController.java`
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\service\AssistantSuggestionService.java`
- Modify: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\controller\AssistantControllerTest.java`

- [ ] **Step 1: Write the failing controller tests**

```java
@WebMvcTest(AssistantController.class)
class AssistantControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AssistantChatService assistantChatService;

    @MockBean
    private AssistantSuggestionService assistantSuggestionService;

    @Test
    void appChatEndpointReturnsNodeStylePayload() throws Exception {
        when(assistantChatService.chat(any(), any())).thenReturn(
                new AssistantChatReply(
                        "建议固定作息",
                        "DeepSeek",
                        "normal",
                        List.of("规律作息"),
                        List.of(),
                        "本建议不能替代医生诊断，若症状持续或加重，请及时就医。"
                )
        );

        mockMvc.perform(authPost("/api/ai/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"message":"最近睡不好","profile":{},"weather":{},"history":[]}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reply").value("建议固定作息"))
                .andExpect(jsonPath("$.source").value("DeepSeek"));
    }

    @Test
    void sceneSuggestionEndpointReturnsSummaryAndPlans() throws Exception {
        when(assistantSuggestionService.suggest(any())).thenReturn(
                new AssistantSuggestionReply(
                        "DeepSeek",
                        "normal",
                        "home",
                        "当前建议以清淡饮食为主。",
                        List.of("清淡饮食"),
                        List.of(Map.of("timeOfDay", "morning", "title", "清淡饮食")),
                        "本建议不能替代医生诊断，若症状持续或加重，请及时就医。"
                )
        );

        mockMvc.perform(authPost("/api/ai/suggestions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"scenario":"home","weather":{},"profile":{}}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.scenario").value("home"))
                .andExpect(jsonPath("$.summary").value("当前建议以清淡饮食为主。"));
    }
}
```

- [ ] **Step 2: Run the controller test to verify it fails**

Run:

```powershell
mvn -Dtest=AssistantControllerTest test
```

Expected:

```text
FAILURE ... AssistantController cannot be found
```

- [ ] **Step 3: Implement the Spring Boot APP-compatible controller**

```java
package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.ai.*;
import org.example.springbootdemo.service.AssistantChatService;
import org.example.springbootdemo.service.AssistantSuggestionService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class AssistantController {

    private final AssistantChatService assistantChatService;
    private final AssistantSuggestionService assistantSuggestionService;

    public AssistantController(AssistantChatService assistantChatService, AssistantSuggestionService assistantSuggestionService) {
        this.assistantChatService = assistantChatService;
        this.assistantSuggestionService = assistantSuggestionService;
    }

    @PostMapping({"/api/ai/chat", "/api/assistant/chat"})
    public AssistantChatReply chat(@RequestBody AssistantChatRequest request, HttpServletRequest servletRequest) {
        return assistantChatService.chat(request, List.of());
    }

    @PostMapping({"/api/ai/suggestions", "/api/suggestions/scene"})
    public AssistantSuggestionReply suggestions(@RequestBody AssistantSuggestionRequest request) {
        return assistantSuggestionService.suggest(request);
    }
}
```

```java
package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.AssistantSuggestionReply;
import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.example.springbootdemo.ai.NodeAssistantOrchestrationClient;
import org.springframework.stereotype.Service;

@Service
public class AssistantSuggestionService {

    private final NodeAssistantOrchestrationClient nodeClient;

    public AssistantSuggestionService(NodeAssistantOrchestrationClient nodeClient) {
        this.nodeClient = nodeClient;
    }

    public AssistantSuggestionReply suggest(AssistantSuggestionRequest request) {
        return nodeClient.suggest(request);
    }
}
```

```java
registry.addInterceptor(authInterceptor)
        .addPathPatterns("/api/**", "/user/**", "/role/**", "/user-role/**",
                "/health-archive/**", "/health-question/**", "/doctor-profile/**",
                "/consultation/**", "/consultation-message/**")
        .excludePathPatterns("/api/auth/**", "/health", "/api/health");
```

Keep the interceptor registration unchanged so the new `/api/ai/chat` and `/api/ai/suggestions` endpoints require `Authorization` automatically.

- [ ] **Step 4: Run the controller tests**

Run:

```powershell
mvn -Dtest=AssistantControllerTest,HealthQuestionControllerTest test
```

Expected:

```text
BUILD SUCCESS
All assistant and health-question controller tests pass
```

- [ ] **Step 5: Commit the APP-compatible endpoint layer**

```powershell
git -C D:\SpringBoot\SpringBootDemo add src/main/java/org/example/springbootdemo/controller/AssistantController.java src/main/java/org/example/springbootdemo/service/AssistantSuggestionService.java src/test/java/org/example/springbootdemo/controller/AssistantControllerTest.java
git -C D:\SpringBoot\SpringBootDemo commit -m "feat: expose app-compatible assistant endpoints in spring boot"
```

### Task 4: Switch HarmonyOS AI Traffic To Spring Boot With Auth Headers

**Files:**
- Modify: `D:\yangshengzhushou\entry\src\main\ets\services\ApiConfig.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\services\AuthService.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\services\BackendStatusService.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\services\AssistantReplyService.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\services\SuggestionService.ets`
- Modify: `D:\yangshengzhushou\entry\src\main\ets\pages\Index.ets`
- Modify: `D:\yangshengzhushou\entry\src\test\LocalUnit.test.ets`

- [ ] **Step 1: Write the failing ArkTS unit tests for split AI routing and auth headers**

```ts
import { describe, expect, it } from '@ohos/hypium'
import {
  buildAiApiUrl,
  buildSuggestionApiUrl
} from '../main/ets/services/ApiConfig'
import {
  buildAuthorizedJsonHeaders,
  setRuntimeAuthToken
} from '../main/ets/services/AuthService'

export default function localUnitTest() {
  describe('api config split routing', () => {
    it('builds spring boot ai urls without changing weather base url', 0, () => {
      expect(buildAiApiUrl('/api/ai/chat')).assertEqual('http://172.20.10.10:8181/api/ai/chat')
      expect(buildSuggestionApiUrl('/api/ai/suggestions')).assertEqual('http://172.20.10.10:8181/api/ai/suggestions')
    })

    it('adds bearer token to json headers', 0, () => {
      setRuntimeAuthToken('token-123')
      const headers = buildAuthorizedJsonHeaders()
      expect(headers['Authorization']).assertEqual('Bearer token-123')
      expect(headers['Content-Type']).assertEqual('application/json')
    })
  })
}
```

- [ ] **Step 2: Run the unit test to verify it fails**

Run:

```powershell
# Use the existing local ArkTS unit test entrypoint in DevEco/Hvigor
# Expected immediate failure: helper functions do not exist yet
```

Expected:

```text
buildAiApiUrl / buildAuthorizedJsonHeaders / setRuntimeAuthToken not found
```

- [ ] **Step 3: Implement split AI routing and runtime auth headers**

```ts
export interface ApiConfig {
  baseUrl: string;
  authBaseUrl: string;
  aiBaseUrl: string;
  suggestionsBaseUrl: string;
  aiChatPath: string;
  authLoginPath: string;
  authRegisterPath: string;
  suggestionsPath: string;
  weatherPath: string;
  healthPath: string;
  aiHealthPath: string;
  timeoutMs: number;
  candidateBaseUrls: string[];
  candidateAiBaseUrls: string[];
}

const DEFAULT_API_BASE_URL: string = 'http://172.20.10.10:8787';
const DEFAULT_AUTH_BASE_URL: string = 'http://172.20.10.10:8181';
const DEFAULT_AI_BASE_URL: string = 'http://172.20.10.10:8181';

export function buildAiApiUrl(path: string): string {
  return `${getApiConfig().aiBaseUrl}${path}`;
}

export function buildSuggestionApiUrl(path: string): string {
  return `${getApiConfig().suggestionsBaseUrl}${path}`;
}
```

```ts
let runtimeAuthToken: string = ''

export function setRuntimeAuthToken(token: string): void {
  runtimeAuthToken = token.trim()
}

export function buildAuthorizedJsonHeaders(): Record<string, string> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json'
  }
  if (runtimeAuthToken.length > 0) {
    headers['Authorization'] = `Bearer ${runtimeAuthToken}`
  }
  return headers
}
```

```ts
return request.request(buildAiApiUrl(config.aiChatPath), {
  method: http.RequestMethod.POST,
  header: buildAuthorizedJsonHeaders(),
  extraData: body,
  connectTimeout: config.timeoutMs,
  readTimeout: config.timeoutMs
})
```

```ts
return request.request(buildSuggestionApiUrl(config.suggestionsPath), {
  method: http.RequestMethod.POST,
  header: buildAuthorizedJsonHeaders(),
  extraData: body,
  connectTimeout: config.timeoutMs,
  readTimeout: config.timeoutMs
})
```

```ts
this.authRepository.loadSession().then((session: AuthSession | null) => {
  this.authSession = session;
  setRuntimeAuthToken(session ? session.token : '');
  this.isAuthChecked = true;
})
```

```ts
this.authRepository.saveSession(session).then((savedSession: AuthSession) => {
  this.authSession = savedSession;
  setRuntimeAuthToken(savedSession.token);
  this.hasEnteredApp = false;
})
```

```ts
private resetAuthState(): void {
  setRuntimeAuthToken('');
  this.authSession = null;
  this.hasEnteredApp = false;
  this.guideIndex = 0;
  this.currentTab = 0;
}
```

- [ ] **Step 4: Run the unit tests and manual APP smoke check**

Run:

```powershell
# Re-run the local ArkTS unit tests in DevEco/Hvigor
# Then manually verify:
# 1. 登录后打开 AI 助手
# 2. 发送问题
# 3. Spring Boot 8181 返回结果
# 4. SuggestionService 仍可拉取场景建议
```

Expected:

```text
ArkTS tests pass
APP AI chat and scene suggestions use Spring Boot with bearer token
Weather still uses the old weather base url in this phase
```

- [ ] **Step 5: Commit the APP routing change**

```powershell
git -C D:\yangshengzhushou add entry/src/main/ets/services/ApiConfig.ets entry/src/main/ets/services/AuthService.ets entry/src/main/ets/services/BackendStatusService.ets entry/src/main/ets/services/AssistantReplyService.ets entry/src/main/ets/services/SuggestionService.ets entry/src/main/ets/pages/Index.ets entry/src/test/LocalUnit.test.ets
git -C D:\yangshengzhushou commit -m "feat: route app ai traffic through spring boot"
```

### Task 5: Verify Cross-Client Compatibility And Document Rollout

**Files:**
- Modify: `D:\SpringBoot\SpringBootDemo\README.md`
- Modify: `D:\yangshengzhushou\docs\superpowers\specs\2026-06-25-unified-app-pc-backend-design.md`

- [ ] **Step 1: Write the rollout checklist in documentation**

```md
## AI Convergence Rollout

1. Start Node orchestration on `8787`.
2. Start Spring Boot on `8181`.
3. Confirm Spring Boot can call Node `/api/ai/chat` and `/api/ai/suggestions`.
4. Confirm APP AI requests now target Spring Boot, not Node directly.
5. Confirm PC `health-question` still returns AI answers through Spring Boot.
6. Only after this passes, begin Java-native migration of Prompt / LangGraph equivalents.
```

- [ ] **Step 2: Run the targeted backend regression suite**

Run:

```powershell
mvn -Dtest=HealthQuestionAiServiceTest,AssistantChatServiceTest,AssistantControllerTest,HealthQuestionControllerTest test
```

Expected:

```text
BUILD SUCCESS
```

- [ ] **Step 3: Run the manual compatibility checks**

Run:

```text
APP:
- 登录成功
- AI 对话走 Spring Boot
- 场景建议走 Spring Boot

PC:
- 登录成功
- 养生助手问答仍可新增和查看
- 问答仍由 Spring Boot 持续返回答案
```

- [ ] **Step 4: Commit the rollout docs**

```powershell
git -C D:\SpringBoot\SpringBootDemo add README.md
git -C D:\SpringBoot\SpringBootDemo commit -m "docs: add ai convergence rollout notes"

git -C D:\yangshengzhushou add docs/superpowers/specs/2026-06-25-unified-app-pc-backend-design.md
git -C D:\yangshengzhushou commit -m "docs: record ai convergence rollout status"
```

## Notes

- This plan intentionally keeps `D:\SpringBoot\SpringBootVue\Sprintvue` code untouched in the first convergence pass. PC compatibility comes from rewiring `HealthQuestionAiService`, not from rewriting the Vue frontend yet.
- This plan intentionally does **not** move weather off Node in the APP. Weather migration belongs to the next convergence plan so AI can be switched first without blocking on Open-Meteo parity.
- This plan keeps the Java-native AI client path alive as fallback. That prevents a hard outage if the Node LangGraph service is temporarily unavailable.
