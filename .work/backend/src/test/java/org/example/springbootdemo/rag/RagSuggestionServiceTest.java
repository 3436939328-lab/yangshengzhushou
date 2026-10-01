package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionReply;
import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.example.springbootdemo.ai.NodeAssistantOrchestrationClient;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
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
        NodeAssistantOrchestrationClient nodeClient = mock(NodeAssistantOrchestrationClient.class);
        RagSuggestionService service = new RagSuggestionService(retrievalService, vectorClient, promptBuilder, llmClient, logService, nodeClient);
        AssistantSuggestionRequest request = new AssistantSuggestionRequest(
                "home",
                Map.of("city", "杭州", "humidity", "78%"),
                Map.of("constitution", Map.of("name", "气虚质"))
        );
        KnowledgeHit hit = new KnowledgeHit(12L, "气虚与疲劳", "私域知识", "气虚建议低强度活动", "气虚", "LOW", "KEYWORD", 0.7);
        when(retrievalService.buildQueryText(request)).thenReturn("home 杭州 78% 气虚质");
        when(retrievalService.retrieve(request)).thenReturn(List.of(hit));
        when(vectorClient.search(anyString())).thenReturn(List.of());
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

        assertEquals("deepseekRag", reply.source());
        assertEquals("结合私域知识生成建议。", reply.summary());
        assertEquals("KEYWORD_ONLY", reply.retrievalStatus());
        assertFalse(reply.references().isEmpty());
        verify(logService).logSearch(null, "home 杭州 78% 气虚质", List.of(hit));
    }

    @Test
    void wrapsLocalLlmFailuresAsUnavailable() {
        KnowledgeRetrievalService retrievalService = mock(KnowledgeRetrievalService.class);
        MilvusVectorClient vectorClient = mock(MilvusVectorClient.class);
        RagSuggestionPromptBuilder promptBuilder = mock(RagSuggestionPromptBuilder.class);
        LocalLlmClient llmClient = mock(LocalLlmClient.class);
        RagRetrievalLogService logService = mock(RagRetrievalLogService.class);
        NodeAssistantOrchestrationClient nodeClient = mock(NodeAssistantOrchestrationClient.class);
        RagSuggestionService service = new RagSuggestionService(retrievalService, vectorClient, promptBuilder, llmClient, logService, nodeClient);
        AssistantSuggestionRequest request = new AssistantSuggestionRequest("home", Map.of(), Map.of());
        when(retrievalService.buildQueryText(request)).thenReturn("home");
        when(retrievalService.retrieve(request)).thenReturn(List.of());
        when(vectorClient.search("home")).thenReturn(List.of());
        when(promptBuilder.build(request, List.of())).thenReturn("prompt");
        when(llmClient.generate("prompt")).thenThrow(new IllegalStateException("connection refused"));
        when(nodeClient.suggest(request)).thenThrow(new IllegalStateException("node unavailable"));

        assertThrows(RagSuggestionUnavailableException.class, () -> service.suggest(request));
    }

    @Test
    void reportsNoHitWhenNoKnowledgeWasRetrieved() {
        KnowledgeRetrievalService retrievalService = mock(KnowledgeRetrievalService.class);
        MilvusVectorClient vectorClient = mock(MilvusVectorClient.class);
        RagSuggestionPromptBuilder promptBuilder = mock(RagSuggestionPromptBuilder.class);
        LocalLlmClient llmClient = mock(LocalLlmClient.class);
        RagRetrievalLogService logService = mock(RagRetrievalLogService.class);
        NodeAssistantOrchestrationClient nodeClient = mock(NodeAssistantOrchestrationClient.class);
        RagSuggestionService service = new RagSuggestionService(retrievalService, vectorClient, promptBuilder, llmClient, logService, nodeClient);
        AssistantSuggestionRequest request = new AssistantSuggestionRequest("home", Map.of(), Map.of());
        when(retrievalService.buildQueryText(request)).thenReturn("home");
        when(retrievalService.retrieve(request)).thenReturn(List.of());
        when(vectorClient.search("home")).thenReturn(List.of());
        when(promptBuilder.build(request, List.of())).thenReturn("prompt");
        when(llmClient.generate("prompt")).thenReturn(new LocalLlmSuggestionResult(
                "LocalRagLlm",
                "normal",
                "home",
                "未命中知识库时生成的保守建议。",
                List.of("保持规律作息"),
                List.of(),
                "不能替代医生诊断。"
        ));

        AssistantSuggestionReply reply = service.suggest(request);

        assertEquals("NO_HIT", reply.retrievalStatus());
        assertEquals(List.of(), reply.references());
    }
}
