package org.example.springbootdemo.ai;

import java.util.List;
import java.util.Map;

public record AssistantChatRequest(
        String message,
        Map<String, Object> profile,
        Map<String, Object> weather,
        List<Map<String, Object>> history,
        String requestId
) {
    public AssistantChatRequest(String message, Map<String,Object> profile, Map<String,Object> weather, List<Map<String,Object>> history) {
        this(message,profile,weather,history,null);
    }
}
