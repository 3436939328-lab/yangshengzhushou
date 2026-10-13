package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class KnowledgeRetrievalService {

    private final JdbcTemplate jdbcTemplate;
    private final RagSuggestionProperties properties;

    public KnowledgeRetrievalService(JdbcTemplate jdbcTemplate, RagSuggestionProperties properties) {
        this.jdbcTemplate = jdbcTemplate;
        this.properties = properties;
    }

    public List<KnowledgeHit> retrieve(AssistantSuggestionRequest request) {
        return retrieveKeywordHits(buildQueryText(request));
    }

    String buildQueryText(AssistantSuggestionRequest request) {
        Map<String, Object> weather = request != null && request.weather() != null ? request.weather() : Map.of();
        Map<String, Object> profile = request != null && request.profile() != null ? request.profile() : Map.of();
        Map<String, Object> location = request != null && request.location() != null ? request.location() : Map.of();
        return String.join(" ",
                text(request != null ? request.scenario() : null, "home"),
                text(first(location.get("city"), weather.get("city")), "当前位置"),
                text(location.get("district"), ""),
                text(location.get("province"), ""),
                text(location.get("address"), ""),
                text(weather.get("condition"), ""),
                text(weather.get("temperature"), ""),
                text(weather.get("humidity"), ""),
                text(weather.get("riskLevel"), ""),
                constitutionName(profile)
        ).trim();
    }

    List<KnowledgeHit> retrieveKeywordHits(String queryText) {
        List<String> terms = queryTerms(queryText);
        List<Object> parameters = new ArrayList<>();
        StringBuilder conditions = new StringBuilder();
        for (int index = 0; index < terms.size(); index++) {
            if (index > 0) {
                conditions.append(" OR ");
            }
            conditions.append("(c.title LIKE ? OR c.content LIKE ? OR c.keywords LIKE ?)");
            String likePattern = "%" + terms.get(index) + "%";
            parameters.add(likePattern);
            parameters.add(likePattern);
            parameters.add(likePattern);
        }
        parameters.add(properties.getTopK());
        RowMapper<KnowledgeHit> mapper = (rs, rowNum) -> new KnowledgeHit(
                rs.getLong("chunk_id"),
                rs.getString("title"),
                rs.getString("document_title"),
                rs.getString("content"),
                rs.getString("keywords"),
                rs.getString("risk_level"),
                "KEYWORD",
                0.6
        );
        return jdbcTemplate.query(
                ("""
                        SELECT c.id AS chunk_id,
                               c.title AS title,
                               d.title AS document_title,
                               c.content AS content,
                               c.keywords AS keywords,
                               c.risk_level AS risk_level
                        FROM medical_knowledge_chunk c
                        JOIN medical_knowledge_document d ON d.id = c.document_id
                        WHERE c.enabled = 1
                          AND d.status = 'ACTIVE'
                          AND (%s)
                        ORDER BY CASE c.risk_level WHEN 'EMERGENCY' THEN 4 WHEN 'HIGH' THEN 3 WHEN 'MEDIUM' THEN 2 WHEN 'LOW' THEN 1 ELSE 0 END DESC,
                                 c.sort_order ASC
                        LIMIT ?
                        """).formatted(conditions),
                mapper,
                parameters.toArray()
        );
    }

    private List<String> queryTerms(String queryText) {
        String normalized = text(queryText, "").replaceAll("[,，;；、\\n\\r\\t]+", " ");
        List<String> terms = new ArrayList<>();
        for (String value : normalized.split("\\s+")) {
            String term = value.trim();
            if (!term.isEmpty() && terms.size() < 8 && !terms.contains(term)) {
                terms.add(term);
            }
        }
        if (terms.isEmpty()) {
            terms.add("养生");
        }
        return terms;
    }

    private String constitutionName(Map<String, Object> profile) {
        Object constitution = profile.get("constitution");
        if (constitution instanceof Map<?, ?> values) {
            return text(values.get("name"), "平和质");
        }
        return "平和质";
    }

    private String text(Object value, String fallback) {
        if (value == null) {
            return fallback;
        }
        String text = String.valueOf(value).trim();
        return text.isEmpty() ? fallback : text;
    }

    private Object first(Object primary, Object fallback) {
        return primary == null || String.valueOf(primary).trim().isEmpty() ? fallback : primary;
    }
}
