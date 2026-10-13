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
