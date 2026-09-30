package org.example.springbootdemo.rag;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class RagSuggestionPropertiesTest {

    @Test
    void defaultsTargetLocalOpenAiCompatibleServices() {
        RagSuggestionProperties properties = new RagSuggestionProperties();

        assertEquals("http://127.0.0.1:11434/v1/chat/completions", properties.getChatBaseUrl());
        assertEquals("qwen2.5:7b", properties.getChatModel());
        assertEquals("http://127.0.0.1:11434/v1/embeddings", properties.getEmbeddingBaseUrl());
        assertEquals("bge-m3", properties.getEmbeddingModel());
        assertEquals("medical_knowledge", properties.getMilvusCollection());
        assertEquals(6, properties.getTopK());
    }
}
