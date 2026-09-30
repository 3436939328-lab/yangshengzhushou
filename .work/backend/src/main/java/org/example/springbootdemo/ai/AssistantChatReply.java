package org.example.springbootdemo.ai;

import java.util.List;
import java.util.Map;

public record AssistantChatReply(
        String reply,
        String source,
        String riskLevel,
        List<String> suggestions,
        List<Map<String, Object>> plan,
        String disclaimer
) {
}
