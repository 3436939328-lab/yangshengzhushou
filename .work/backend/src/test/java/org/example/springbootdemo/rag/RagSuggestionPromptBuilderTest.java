package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertTrue;

class RagSuggestionPromptBuilderTest {

    @Test
    void promptContainsLocationWeatherProfileKnowledgeAndJsonContract() {
        RagSuggestionPromptBuilder builder = new RagSuggestionPromptBuilder();
        AssistantSuggestionRequest request = new AssistantSuggestionRequest(
                "home",
                Map.of("city", "杭州", "condition", "多云", "temperature", "29℃", "humidity", "78%"),
                Map.of("constitution", Map.of("name", "气虚质"))
        );
        KnowledgeHit hit = new KnowledgeHit(
                12L,
                "气虚与疲劳的养生提示",
                "中医体质与日常养生基础",
                "气虚用户应避免过度消耗，可选择散步或八段锦等低强度活动。",
                "气虚,疲劳,八段锦",
                "MEDIUM",
                "KEYWORD",
                0.82
        );

        String prompt = builder.build(request, List.of(hit));

        assertTrue(prompt.contains("场景: home"));
        assertTrue(prompt.contains("城市: 杭州"));
        assertTrue(prompt.contains("天气: 多云"));
        assertTrue(prompt.contains("温度: 29℃"));
        assertTrue(prompt.contains("湿度: 78%"));
        assertTrue(prompt.contains("体质: 气虚质"));
        assertTrue(prompt.contains("气虚与疲劳的养生提示"));
        assertTrue(prompt.contains("只能返回 JSON"));
        assertTrue(prompt.contains("不能诊断疾病"));
    }

    @Test
    void promptContainsTopLevelLocationWhenPresent() {
        RagSuggestionPromptBuilder builder = new RagSuggestionPromptBuilder();
        AssistantSuggestionRequest request = new AssistantSuggestionRequest(
                "home",
                Map.of("condition", "多云"),
                Map.of(),
                Map.of("city", "苏州", "district", "姑苏区")
        );

        String prompt = builder.build(request, List.of());

        assertTrue(prompt.contains("城市: 苏州"));
        assertTrue(prompt.contains("区域: 姑苏区"));
    }
}
