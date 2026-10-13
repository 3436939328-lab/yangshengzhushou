package org.example.springbootdemo.rag;

import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Component
public class RagSuggestionPromptBuilder {

    public String build(AssistantSuggestionRequest request, List<KnowledgeHit> hits) {
        Map<String, Object> weather = request != null && request.weather() != null ? request.weather() : Map.of();
        Map<String, Object> profile = request != null && request.profile() != null ? request.profile() : Map.of();
        Map<String, Object> location = request != null && request.location() != null ? request.location() : Map.of();
        String scenario = text(request != null ? request.scenario() : null, "home");

        StringBuilder builder = new StringBuilder();
        builder.append("你是一个谨慎的中文养生建议助手。\n");
        builder.append("只能基于用户上下文和私域知识片段生成日常养生建议，不能诊断疾病，不能替代医生。\n");
        builder.append("如果出现胸痛、呼吸困难、卒中、高热、自伤等风险信号，必须建议及时就医或急救。\n");
        builder.append("只能返回 JSON，不要返回 Markdown。JSON 字段必须包含 source, riskLevel, scenario, summary, suggestions, plans, disclaimer。\n\n");
        builder.append("用户上下文:\n");
        builder.append("场景: ").append(scenario).append("\n");
        builder.append("城市: ").append(text(first(location.get("city"), weather.get("city")), "当前位置")).append("\n");
        builder.append("区域: ").append(text(location.get("district"), "未知")).append("\n");
        builder.append("地址: ").append(text(location.get("address"), "未知")).append("\n");
        builder.append("天气: ").append(text(weather.get("condition"), "未知")).append("\n");
        builder.append("温度: ").append(text(weather.get("temperature"), "--")).append("\n");
        builder.append("湿度: ").append(text(weather.get("humidity"), "--")).append("\n");
        builder.append("体质: ").append(constitutionName(profile)).append("\n\n");
        builder.append("私域知识片段:\n");
        List<KnowledgeHit> safeHits = hits == null ? List.of() : hits;
        if (safeHits.isEmpty()) {
            builder.append("- 暂无匹配知识。请基于用户上下文给出保守的一般性建议，并说明知识库未命中。\n");
        } else {
            for (int index = 0; index < safeHits.size(); index++) {
                KnowledgeHit hit = safeHits.get(index);
                builder.append(index + 1).append(". [").append(text(hit.retrievalType(), "KEYWORD")).append("] ");
                builder.append(text(hit.title(), "未命名知识")).append(" - ");
                builder.append(text(hit.documentTitle(), "私域知识库")).append("\n");
                builder.append("风险级别: ").append(text(hit.riskLevel(), "LOW")).append("\n");
                builder.append("关键词: ").append(text(hit.keywords(), "")).append("\n");
                builder.append("内容: ").append(text(hit.content(), "")).append("\n\n");
            }
        }
        builder.append("输出要求:\n");
        builder.append("- source 固定为 LocalRagLlm。\n");
        builder.append("- suggestions 是 3 到 6 条短建议。\n");
        builder.append("- plans 是适合当天执行的 morning/noon/evening 计划数组。\n");
        builder.append("- disclaimer 必须提醒不能替代医生诊断。\n");
        return builder.toString();
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
