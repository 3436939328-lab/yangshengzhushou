package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionReply;
import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.example.springbootdemo.ai.NodeAssistantOrchestrationClient;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class RagSuggestionService {

    private final KnowledgeRetrievalService retrievalService;
    private final MilvusVectorClient vectorClient;
    private final RagSuggestionPromptBuilder promptBuilder;
    private final LocalLlmClient llmClient;
    private final RagRetrievalLogService logService;
    private final NodeAssistantOrchestrationClient nodeClient;
    @org.springframework.beans.factory.annotation.Autowired
    private org.example.springbootdemo.ai.HealthQuestionAiProperties aiProperties = new org.example.springbootdemo.ai.HealthQuestionAiProperties();

    public RagSuggestionService(
            KnowledgeRetrievalService retrievalService,
            MilvusVectorClient vectorClient,
            RagSuggestionPromptBuilder promptBuilder,
            LocalLlmClient llmClient,
            RagRetrievalLogService logService,
            NodeAssistantOrchestrationClient nodeClient
    ) {
        this.retrievalService = retrievalService;
        this.vectorClient = vectorClient;
        this.promptBuilder = promptBuilder;
        this.llmClient = llmClient;
        this.logService = logService;
        this.nodeClient = nodeClient;
    }

    public AssistantSuggestionReply suggest(AssistantSuggestionRequest request) {
        String queryText = retrievalService.buildQueryText(request);
        List<KnowledgeHit> keywordHits = safeHits(retrievalService.retrieve(request));
        List<KnowledgeHit> vectorHits = safeHits(vectorClient.search(queryText));
        List<KnowledgeHit> mergedHits = merge(keywordHits, vectorHits);
        String prompt = promptBuilder.build(request, mergedHits);
        LocalLlmSuggestionResult result;
        try {
            result = llmClient.generate(prompt);
        } catch (RuntimeException exception) {
            // LLM 不可用时回退到 Node.js AI 服务（规则兜底）
            try {
                AssistantSuggestionReply nodeReply = nodeClient.suggest(request);
                if (nodeReply != null) {
                    return nodeReply;
                }
            } catch (RuntimeException nodeException) {
                // Node.js 回退也失败，继续抛出原始异常
            }
            throw new RagSuggestionUnavailableException("AI provider unavailable", exception);
        }
        logService.logSearch(null, queryText, mergedHits);

        return new AssistantSuggestionReply(
                aiProperties.getProvider() + "Rag",
                text(result.riskLevel(), "normal"),
                text(result.scenario(), request != null && request.scenario() != null ? request.scenario() : "home"),
                text(result.summary(), ""),
                result.suggestions() == null ? List.of() : result.suggestions(),
                result.plans() == null ? List.of() : result.plans(),
                text(result.disclaimer(), "本建议不能替代医生诊断，若症状持续或加重，请及时就医。"),
                mergedHits.stream().map(SuggestionReference::from).map(SuggestionReference::toMap).toList(),
                retrievalStatus(keywordHits, vectorHits)
        );
    }

    private String retrievalStatus(List<KnowledgeHit> keywordHits, List<KnowledgeHit> vectorHits) {
        if (keywordHits.isEmpty() && vectorHits.isEmpty()) {
            return "NO_HIT";
        }
        return vectorHits.isEmpty() ? "KEYWORD_ONLY" : "HYBRID";
    }

    private List<KnowledgeHit> merge(List<KnowledgeHit> keywordHits, List<KnowledgeHit> vectorHits) {
        Map<Long, KnowledgeHit> merged = new LinkedHashMap<>();
        for (KnowledgeHit hit : keywordHits) {
            merged.put(hit.chunkId(), hit);
        }
        for (KnowledgeHit hit : vectorHits) {
            merged.putIfAbsent(hit.chunkId(), hit);
        }
        return new ArrayList<>(merged.values());
    }

    private List<KnowledgeHit> safeHits(List<KnowledgeHit> hits) {
        return hits == null ? List.of() : hits;
    }

    private String text(String value, String fallback) {
        if (value == null || value.trim().isEmpty()) {
            return fallback;
        }
        return value.trim();
    }
}
