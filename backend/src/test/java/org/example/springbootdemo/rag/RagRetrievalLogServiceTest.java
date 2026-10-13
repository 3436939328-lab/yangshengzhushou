package org.example.springbootdemo.rag;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class RagRetrievalLogServiceTest {

    @Test
    void logsSearchAndRetrievalResults() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        RagRetrievalLogService service = new RagRetrievalLogService(jdbcTemplate);
        KnowledgeHit hit = new KnowledgeHit(12L, "title", "document", "content", "keywords", "LOW", "KEYWORD", 0.6);

        service.logSearch(null, "home 杭州 气虚", List.of(hit));

        verify(jdbcTemplate).update(
                eq("INSERT INTO medical_knowledge_search_log (user_id, query_text, matched_chunk_ids, scene, requester_role) VALUES (?, ?, ?, ?, ?)"),
                any(), eq("home 杭州 气虚"), eq("12"), eq("APP_SEARCH"), eq("USER")
        );
    }
}
