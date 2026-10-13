package org.example.springbootdemo.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Component
public class OpenAiCompatibleHealthQuestionAiClient implements HealthQuestionAiClient {

    private final HealthQuestionAiProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final AiProviderStatus status;

    public OpenAiCompatibleHealthQuestionAiClient(HealthQuestionAiProperties properties, ObjectMapper objectMapper) {
        this(properties, objectMapper, new AiProviderStatus());
    }

    @org.springframework.beans.factory.annotation.Autowired
    public OpenAiCompatibleHealthQuestionAiClient(HealthQuestionAiProperties properties, ObjectMapper objectMapper, AiProviderStatus status) {
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.status = status;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(resolveTimeout())
                .build();
    }

    @Override
    public String generateAnswer(List<AiChatMessage> messages) {
        try {
            validateConfiguration();
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("model", properties.getModel());
            payload.put("messages", messages.stream()
                    .map(message -> Map.of(
                            "role", message.role(),
                            "content", message.content()
                    ))
                    .toList());
            payload.put("temperature", properties.getTemperature());
            payload.put("max_tokens", 1600);

            HttpRequest.Builder builder = HttpRequest.newBuilder()
                    .uri(URI.create(normalizeBaseUrl() + "/chat/completions"))
                    .timeout(resolveTimeout())
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(payload)));
            if (properties.getApiKey()!=null && !properties.getApiKey().isBlank()) builder.header("Authorization", "Bearer " + properties.getApiKey().trim());
            HttpRequest request = builder
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 400) {
                throw new IllegalStateException("AI provider returned HTTP " + response.statusCode());
            }

            JsonNode root = objectMapper.readTree(response.body());
            JsonNode choices = root.path("choices");
            if (!choices.isArray() || choices.isEmpty()) {
                throw new IllegalStateException("AI response does not contain choices");
            }
            JsonNode content = choices.get(0).path("message").path("content");
            if (content.isMissingNode() || content.isNull()) {
                throw new IllegalStateException("AI response does not contain message content");
            }
            String answer = content.asText().trim();
            if (answer.isEmpty()) throw new IllegalStateException("AI provider returned empty content");
            status.succeeded();
            return answer;
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            status.failed("AI request interrupted");
            throw new IllegalStateException("AI request interrupted", exception);
        } catch (IOException exception) {
            status.failed(exception instanceof java.net.http.HttpTimeoutException ? "AI request timed out" : "AI provider connection failed");
            throw new IllegalStateException(exception instanceof java.net.http.HttpTimeoutException ? "AI request timed out" : "AI provider connection failed", exception);
        } catch (RuntimeException exception) {
            status.failed(exception.getMessage());
            throw exception;
        }
    }

    private void validateConfiguration() {
        if (properties.getBaseUrl() == null || properties.getBaseUrl().trim().isEmpty()) {
            throw new IllegalStateException("app.health-ai.base-url is required");
        }
        if (!"deepseek".equals(properties.getProvider()) && !"local".equals(properties.getProvider())) {
            throw new IllegalStateException("AI provider must be deepseek or local");
        }
        if (!"local".equals(properties.getProvider()) && (properties.getApiKey() == null || properties.getApiKey().trim().isEmpty())) {
            throw new IllegalStateException("app.health-ai.api-key is required");
        }
        if (properties.getModel() == null || properties.getModel().trim().isEmpty()) {
            throw new IllegalStateException("app.health-ai.model is required");
        }
    }

    private Duration resolveTimeout() {
        Duration timeout = Objects.requireNonNullElse(properties.getTimeout(), Duration.ofSeconds(45));
        return timeout.isNegative() || timeout.isZero() ? Duration.ofSeconds(45) : (timeout.compareTo(Duration.ofSeconds(120)) > 0 ? Duration.ofSeconds(120) : timeout);
    }

    private String normalizeBaseUrl() {
        String value = properties.getBaseUrl().trim();
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }
}
