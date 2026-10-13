package org.example.springbootdemo.ai.tongue;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.ai.HealthQuestionAiProperties;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * 舌象视觉AI分析客户端
 * 兼容 OpenAI / DeepSeek 等多模态视觉API（支持图片输入）
 */
@Component
public class TongueVisionAiClient {

    private final HealthQuestionAiProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    public TongueVisionAiClient(HealthQuestionAiProperties properties, ObjectMapper objectMapper) {
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(resolveTimeout())
                .build();
    }

    /**
     * 分析舌象图片
     * @param imageBase64 图片Base64编码（不含data:image前缀）
     * @param imageType 图片类型，如 "image/jpeg"
     * @return AI返回的原始文本
     */
    public String analyzeTongueImage(String imageBase64, String imageType, String systemPrompt, String userPrompt) {
        try {
            validateConfiguration();

            List<Map<String, Object>> messages = new ArrayList<>();

            // System message
            messages.add(Map.of(
                    "role", "system",
                    "content", systemPrompt
            ));

            // User message with image (multimodal)
            List<Map<String, Object>> contentParts = new ArrayList<>();
            contentParts.add(Map.of(
                    "type", "text",
                    "text", userPrompt
            ));
            contentParts.add(Map.of(
                    "type", "image_url",
                    "image_url", Map.of(
                            "url", "data:" + imageType + ";base64," + imageBase64,
                            "detail", "high"
                    )
            ));

            messages.add(Map.of(
                    "role", "user",
                    "content", contentParts
            ));

            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("model", resolveVisionModel());
            payload.put("messages", messages);
            payload.put("temperature", properties.getTemperature());
            payload.put("max_tokens", 2000);

            HttpRequest.Builder builder = HttpRequest.newBuilder()
                    .uri(URI.create(normalizeBaseUrl() + "/chat/completions"))
                    .timeout(resolveTimeout())
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(payload)));

            if (properties.getApiKey() != null && !properties.getApiKey().isBlank()) {
                builder.header("Authorization", "Bearer " + properties.getApiKey().trim());
            }

            HttpRequest request = builder.build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() >= 400) {
                throw new IllegalStateException("AI provider returned HTTP " + response.statusCode() + ": " + response.body());
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
            return content.asText().trim();
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("AI request interrupted", exception);
        } catch (IOException exception) {
            throw new IllegalStateException(exception instanceof java.net.http.HttpTimeoutException
                    ? "AI request timed out" : "AI provider connection failed", exception);
        }
    }

    private void validateConfiguration() {
        if (properties.getBaseUrl() == null || properties.getBaseUrl().trim().isEmpty()) {
            throw new IllegalStateException("app.health-ai.base-url is required");
        }
        if (properties.getModel() == null || properties.getModel().trim().isEmpty()) {
            throw new IllegalStateException("app.health-ai.model is required");
        }
    }

    /**
     * 解析视觉模型名。如果配置了视觉模型优先使用，否则回退到文本模型。
     * 对于支持视觉的模型（如 deepseek-vl、gpt-4-vision-preview 等）直接使用
     */
    private String resolveVisionModel() {
        // 优先使用配置的模型（假设配置的模型支持视觉）
        // 如果使用的是 deepseek，可以用 deepseek-vl 系列
        // 这里默认直接使用配置的模型
        return properties.getModel();
    }

    private Duration resolveTimeout() {
        Duration timeout = Objects.requireNonNullElse(properties.getTimeout(), Duration.ofSeconds(60));
        return timeout.isNegative() || timeout.isZero() ? Duration.ofSeconds(60)
                : (timeout.compareTo(Duration.ofSeconds(180)) > 0 ? Duration.ofSeconds(180) : timeout);
    }

    private String normalizeBaseUrl() {
        String value = properties.getBaseUrl().trim();
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }
}
