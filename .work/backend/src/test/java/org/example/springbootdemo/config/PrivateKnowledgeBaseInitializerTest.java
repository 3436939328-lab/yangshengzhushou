package org.example.springbootdemo.config;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PrivateKnowledgeBaseInitializerTest {

    @Test
    void runCreatesTablesAndSeedsPrivateKnowledgeWhenEmpty() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        PrivateKnowledgeBaseInitializer initializer = new PrivateKnowledgeBaseInitializer(jdbcTemplate);

        when(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM medical_knowledge_category", Integer.class))
                .thenReturn(0);

        initializer.run();

        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS medical_knowledge_category"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS medical_knowledge_document"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS medical_knowledge_chunk"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS medical_risk_rule"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS medical_knowledge_search_log"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS agent_knowledge_reference"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS knowledge_source"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS knowledge_review"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS knowledge_version ("));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS knowledge_import_task"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS knowledge_embedding_task"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS knowledge_feedback"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS knowledge_quality_score"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS rag_retrieval_result"));
        verify(jdbcTemplate, atLeastOnce()).update(contains("INSERT INTO knowledge_source"), any(Object[].class));
        verify(jdbcTemplate).update(
                contains("INSERT INTO knowledge_version"),
                any(),
                any(),
                any(),
                any()
        );
        verify(jdbcTemplate, atLeastOnce()).update(contains("INSERT INTO medical_knowledge_category"), any(Object[].class));
        verify(jdbcTemplate, atLeastOnce()).update(contains("INSERT INTO medical_risk_rule"), any(Object[].class));
        verify(jdbcTemplate, atLeastOnce()).execute(contains("中医九种体质养生知识"));
        verify(jdbcTemplate, atLeastOnce()).execute(contains("春季中医养生知识"));
        verify(jdbcTemplate, atLeastOnce()).execute(contains("large-seed-knowledge-20260701"));
    }

    @Test
    void runSkipsSeedDataWhenKnowledgeAlreadyExists() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        PrivateKnowledgeBaseInitializer initializer = new PrivateKnowledgeBaseInitializer(jdbcTemplate);

        when(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM medical_knowledge_category", Integer.class))
                .thenReturn(10);

        initializer.run();

        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS medical_knowledge_category"));
        verify(jdbcTemplate).execute(contains("CREATE TABLE IF NOT EXISTS knowledge_source"));
        verify(jdbcTemplate, atLeastOnce()).update(contains("INSERT INTO knowledge_source"), any(Object[].class));
        verify(jdbcTemplate).update(
                contains("INSERT INTO knowledge_version"),
                any(),
                any(),
                any(),
                any()
        );
        verify(jdbcTemplate, never()).update(contains("INSERT INTO medical_knowledge_category"), any(Object[].class));
        verify(jdbcTemplate, never()).update(contains("INSERT INTO medical_risk_rule"), any(Object[].class));
        verify(jdbcTemplate, atLeastOnce()).execute(contains("中医九种体质养生知识"));
        verify(jdbcTemplate, atLeastOnce()).execute(contains("春季中医养生知识"));
        verify(jdbcTemplate, atLeastOnce()).execute(contains("large-seed-knowledge-20260701"));
    }
}
