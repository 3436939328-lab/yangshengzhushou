package org.example.springbootdemo.rag;

import java.util.LinkedHashMap;
import java.util.Map;

public record SuggestionReference(
        Long chunkId,
        String title,
        String documentTitle,
        String retrievalType,
        double score
) {
    public Map<String, Object> toMap() {
        Map<String, Object> value = new LinkedHashMap<>();
        value.put("chunkId", chunkId);
        value.put("title", title);
        value.put("documentTitle", documentTitle);
        value.put("retrievalType", retrievalType);
        value.put("score", score);
        return value;
    }

    public static SuggestionReference from(KnowledgeHit hit) {
        return new SuggestionReference(hit.chunkId(), hit.title(), hit.documentTitle(), hit.retrievalType(), hit.score());
    }
}
