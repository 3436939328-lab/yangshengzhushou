package org.example.springbootdemo.rag;

import java.util.List;
import java.util.Map;

public record LocalLlmSuggestionResult(
        String source,
        String riskLevel,
        String scenario,
        String summary,
        List<String> suggestions,
        List<Map<String, Object>> plans,
        String disclaimer
) {
}
