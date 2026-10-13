package org.example.springbootdemo.ai;

import java.util.Map;

public record AssistantSuggestionRequest(
        String scenario,
        Map<String, Object> weather,
        Map<String, Object> profile,
        Map<String, Object> location
) {
    public AssistantSuggestionRequest(
            String scenario,
            Map<String, Object> weather,
            Map<String, Object> profile
    ) {
        this(scenario, weather, profile, Map.of());
    }
}
