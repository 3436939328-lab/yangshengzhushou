package org.example.springbootdemo.rag;

public record KnowledgeHit(
        Long chunkId,
        String title,
        String documentTitle,
        String content,
        String keywords,
        String riskLevel,
        String retrievalType,
        double score
) {
}
