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
