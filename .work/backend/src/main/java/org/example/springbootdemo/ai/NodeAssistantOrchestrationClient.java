package org.example.springbootdemo.ai;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;

@Component
public class NodeAssistantOrchestrationClient {

    private final NodeAiOrchestrationProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    @Autowired
    public NodeAssistantOrchestrationClient(NodeAiOrchestrationProperties properties, ObjectMapper objectMapper) {
        this(properties, objectMapper, HttpClient.newHttpClient());
    }

    NodeAssistantOrchestrationClient(
            NodeAiOrchestrationProperties properties,
            ObjectMapper objectMapper,
            HttpClient httpClient
    ) {
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.httpClient = httpClient;
    }

    public AssistantChatReply chat(AssistantChatRequest request) {
        return post("/api/ai/chat", request, AssistantChatReply.class, "node chat failed");
    }

    public AssistantSuggestionReply suggest(AssistantSuggestionRequest request) {
        return post("/api/ai/suggestions", request, AssistantSuggestionReply.class, "node suggestion failed");
    }

    public Map<String, Object> health() {
        try {
            HttpRequest httpRequest = HttpRequest.newBuilder()
                    .uri(URI.create(properties.getBaseUrl() + "/api/health"))
                    .timeout(Duration.ofMillis(properties.getTimeoutMs()))
                    .GET()
                    .build();
            HttpResponse<String> response = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 400) {
                throw new IllegalStateException("node health check failed: HTTP " + response.statusCode());
            }
            return objectMapper.readValue(response.body(), new TypeReference<Map<String, Object>>() {
            });
        } catch (Exception exception) {
            throw new IllegalStateException("node health check failed", exception);
        }
    }

    public String getBaseUrl() {
        return properties.getBaseUrl();
    }

    private <T> T post(String path, Object body, Class<T> responseType, String errorMessage) {
        try {
            HttpRequest httpRequest = HttpRequest.newBuilder()
                    .uri(URI.create(properties.getBaseUrl() + path))
                    .timeout(Duration.ofMillis(properties.getTimeoutMs()))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(body)))
                    .build();
            HttpResponse<String> response = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 400) {
                throw new IllegalStateException(errorMessage + ": HTTP " + response.statusCode());
            }
            return objectMapper.readValue(response.body(), responseType);
        } catch (Exception exception) {
            throw new IllegalStateException(errorMessage, exception);
        }
    }
}

