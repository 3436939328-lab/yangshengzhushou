package org.example.springbootdemo.rag;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class RagRetrievalLogService {

    private final JdbcTemplate jdbcTemplate;

    public RagRetrievalLogService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void logSearch(Long userId, String queryText, List<KnowledgeHit> hits) {
        String matchedChunkIds = (hits == null ? List.<KnowledgeHit>of() : hits).stream()
                .map(KnowledgeHit::chunkId)
                .map(String::valueOf)
                .collect(Collectors.joining(","));
        jdbcTemplate.update(
                "INSERT INTO medical_knowledge_search_log (user_id, query_text, matched_chunk_ids, scene, requester_role) VALUES (?, ?, ?, ?, ?)",
                userId,
                queryText,
                matchedChunkIds,
                "APP_SEARCH",
                "USER"
        );
    }
}
