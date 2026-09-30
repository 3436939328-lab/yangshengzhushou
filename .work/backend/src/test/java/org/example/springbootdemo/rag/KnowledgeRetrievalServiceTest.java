package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class KnowledgeRetrievalServiceTest {

    @Test
    void buildsQueryTextFromScenarioWeatherAndProfile() {
        KnowledgeRetrievalService service = new KnowledgeRetrievalService(mock(JdbcTemplate.class), new RagSuggestionProperties());
        AssistantSuggestionRequest request = new AssistantSuggestionRequest(
                "home",
                Map.of("city", "杭州", "condition", "多云", "temperature", "29℃", "humidity", "78%"),
                Map.of("constitution", Map.of("name", "气虚质"))
        );

        String query = service.buildQueryText(request);

        assertTrue(query.contains("home"));
        assertTrue(query.contains("杭州"));
        assertTrue(query.contains("78%"));
        assertTrue(query.contains("气虚质"));
    }

    @Test
    void buildsQueryTextFromTopLevelLocationWhenPresent() {
        KnowledgeRetrievalService service = new KnowledgeRetrievalService(mock(JdbcTemplate.class), new RagSuggestionProperties());
        AssistantSuggestionRequest request = new AssistantSuggestionRequest(
                "home",
                Map.of("condition", "多云"),
                Map.of(),
                Map.of("city", "苏州", "district", "姑苏区")
        );

        String query = service.buildQueryText(request);

        assertTrue(query.contains("苏州"));
        assertTrue(query.contains("姑苏区"));
    }

    @Test
    void retrievesKeywordKnowledgeHits() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        KnowledgeRetrievalService service = new KnowledgeRetrievalService(jdbcTemplate, new RagSuggestionProperties());
        doReturn(List.of(new KnowledgeHit(
                        12L,
                        "气虚与疲劳的养生提示",
                        "中医体质与日常养生基础",
                        "气虚用户可选择散步或八段锦。",
                        "气虚,疲劳",
                        "MEDIUM",
                        "KEYWORD",
                        0.6
                )))
                .when(jdbcTemplate)
                .query(anyString(), any(RowMapper.class), any(Object[].class));

        List<KnowledgeHit> hits = service.retrieveKeywordHits("气虚 杭州 湿度 78%");

        assertEquals(1, hits.size());
        assertEquals(12L, hits.get(0).chunkId());
        assertEquals("KEYWORD", hits.get(0).retrievalType());
    }

    @Test
    void retrievesWithSeparateLikeTermsInsteadOfOneWholeQueryPattern() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        KnowledgeRetrievalService service = new KnowledgeRetrievalService(jdbcTemplate, new RagSuggestionProperties());

        service.retrieveKeywordHits("home 杭州 78% 气虚质");

        verify(jdbcTemplate).query(
                anyString(),
                any(RowMapper.class),
                eq("%home%"), eq("%home%"), eq("%home%"),
                eq("%杭州%"), eq("%杭州%"), eq("%杭州%"),
                eq("%78%%"), eq("%78%%"), eq("%78%%"),
                eq("%气虚质%"), eq("%气虚质%"), eq("%气虚质%"),
                eq(6)
        );
    }

    @Test
    void retrievalSqlOrdersRiskByMedicalPriority() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        KnowledgeRetrievalService service = new KnowledgeRetrievalService(jdbcTemplate, new RagSuggestionProperties());

        service.retrieveKeywordHits("胸痛 气短");

        verify(jdbcTemplate).query(
                org.mockito.ArgumentMatchers.contains("CASE c.risk_level WHEN 'EMERGENCY' THEN 4 WHEN 'HIGH' THEN 3 WHEN 'MEDIUM' THEN 2 WHEN 'LOW' THEN 1 ELSE 0 END DESC"),
                any(RowMapper.class),
                any(Object[].class)
        );
    }
}
