package org.example.springbootdemo.ai;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_EMPTY)
public record AssistantSuggestionReply(
        String source,
        String riskLevel,
        String scenario,
        String summary,
        List<String> suggestions,
        List<Map<String, Object>> plans,
        String disclaimer,
        List<Map<String, Object>> references,
        String retrievalStatus
) {
    public AssistantSuggestionReply(
            String source,
            String riskLevel,
            String scenario,
            String summary,
            List<String> suggestions,
            List<Map<String, Object>> plans,
            String disclaimer
    ) {
        this(source, riskLevel, scenario, summary, suggestions, plans, disclaimer, List.of(), "");
    }
}
