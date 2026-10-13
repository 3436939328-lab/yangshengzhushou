package org.example.springbootdemo.rag;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.ai.AiChatMessage;
import org.example.springbootdemo.ai.HealthQuestionAiClient;
import org.springframework.stereotype.Component;
import java.io.IOException;
import java.util.List;

/** Parses suggestion JSON using the same provider client as conversation. */
@Component
public class LocalLlmClient {
    private final HealthQuestionAiClient client;
    private final ObjectMapper mapper;
    private final org.example.springbootdemo.ai.AiProviderStatus status;

    public LocalLlmClient(HealthQuestionAiClient client, ObjectMapper mapper) {
        this(client, mapper, new org.example.springbootdemo.ai.AiProviderStatus());
    }

    @org.springframework.beans.factory.annotation.Autowired
    public LocalLlmClient(HealthQuestionAiClient client, ObjectMapper mapper,
                          org.example.springbootdemo.ai.AiProviderStatus status) {
        this.client = client;
        this.mapper = mapper;
        this.status = status;
    }

    public LocalLlmSuggestionResult generate(String prompt) {
        String content = client.generateAnswer(List.of(
                new AiChatMessage("system", "Return only the requested JSON object."),
                new AiChatMessage("user", prompt)));
        try {
            return parseContent(content);
        } catch (RuntimeException exception) {
            status.failed("AI returned invalid suggestion data");
            throw exception;
        }
    }

    LocalLlmSuggestionResult parseContent(String content) {
        if (content == null) throw new IllegalStateException("AI returned empty content");
        String json = content.trim();
        if (json.startsWith("```")) {
            int newline = json.indexOf('\n');
            if (newline >= 0 && json.endsWith("```")) json = json.substring(newline + 1, json.length() - 3).trim();
        }
        try {
            LocalLlmSuggestionResult result = mapper.readValue(json, LocalLlmSuggestionResult.class);
            if (result == null || result.summary() == null || result.summary().isBlank()
                    || result.suggestions() == null || result.plans() == null) {
                throw new IllegalStateException("AI returned incomplete suggestion JSON");
            }
            return result;
        } catch (IOException exception) {
            throw new IllegalStateException("AI did not return valid suggestion JSON", exception);
        }
    }
}
