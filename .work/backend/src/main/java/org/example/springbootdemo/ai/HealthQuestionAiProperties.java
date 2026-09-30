package org.example.springbootdemo.ai;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.time.Duration;

@Component
@ConfigurationProperties(prefix = "app.health-ai")
public class HealthQuestionAiProperties {

    private String baseUrl = "https://api.deepseek.com";
    private String apiKey = "";
    private String model = "deepseek-chat";
    private String provider = "deepseek";
    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }
    private String systemPrompt = """
            你是一个中文中医养生助手。
            结合最近的对话上下文，给出简洁、具体、可执行的养生建议。
            先考虑作息、饮食、运动、情绪和危险信号，再回答当前问题。
            不要做诊断，不要夸大疗效；如果存在明显风险，请建议线下就医。
            """;
    private int memoryWindow = 4;
    private double temperature = 0.2;
    private Duration timeout = Duration.ofSeconds(30);

    public String getBaseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    public String getApiKey() {
        return apiKey;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public String getSystemPrompt() {
        return systemPrompt;
    }

    public void setSystemPrompt(String systemPrompt) {
        this.systemPrompt = systemPrompt;
    }

    public int getMemoryWindow() {
        return memoryWindow;
    }

    public void setMemoryWindow(int memoryWindow) {
        this.memoryWindow = memoryWindow;
    }

    public double getTemperature() {
        return temperature;
    }

    public void setTemperature(double temperature) {
        this.temperature = temperature;
    }

    public Duration getTimeout() {
        return timeout;
    }

    public void setTimeout(Duration timeout) {
        this.timeout = timeout;
    }
}
