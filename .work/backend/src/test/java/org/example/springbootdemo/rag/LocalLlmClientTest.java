package org.example.springbootdemo.rag;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class LocalLlmClientTest {

    @Test
    void parsesJsonContentFromOpenAiCompatibleResponse() {
        LocalLlmClient client = new LocalLlmClient(org.mockito.Mockito.mock(org.example.springbootdemo.ai.HealthQuestionAiClient.class), new ObjectMapper());
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
        LocalLlmClient client = new LocalLlmClient(org.mockito.Mockito.mock(org.example.springbootdemo.ai.HealthQuestionAiClient.class), new ObjectMapper());

        assertThrows(IllegalStateException.class, () -> client.parseContent("请保持规律作息"));
        assertThrows(IllegalStateException.class, () -> client.parseContent("{}"));
    }
}
