package org.example.springbootdemo.ai.tongue;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * 舌象AI分析服务
 * 构建中医舌诊提示词，调用视觉AI，解析返回结果
 */
@Service
public class TongueAnalysisService {

    private static final Logger log = LoggerFactory.getLogger(TongueAnalysisService.class);

    private final TongueVisionAiClient visionAiClient;
    private final ObjectMapper objectMapper;

    public TongueAnalysisService(TongueVisionAiClient visionAiClient, ObjectMapper objectMapper) {
        this.visionAiClient = visionAiClient;
        this.objectMapper = objectMapper;
    }

    /**
     * 分析舌象图片
     * @param imageBase64 图片Base64
     * @param imageType 图片MIME类型
     * @return 结构化分析结果
     */
    public TongueAnalysisResult analyze(String imageBase64, String imageType) {
        TongueAnalysisResult result = new TongueAnalysisResult();
        try {
            String systemPrompt = buildSystemPrompt();
            String userPrompt = buildUserPrompt();

            String rawResponse = visionAiClient.analyzeTongueImage(imageBase64, imageType, systemPrompt, userPrompt);
            log.debug("Tongue AI raw response: {}", rawResponse);

            // 尝试解析JSON
            parseJsonResponse(rawResponse, result);
            result.setSuccess(true);

        } catch (Exception e) {
            log.error("舌象分析失败", e);
            result.setSuccess(false);
            result.setErrorMessage(e.getMessage());
        }
        return result;
    }

    /**
     * 检查是否配置了可用的AI
     */
    public boolean isAiAvailable() {
        try {
            // 简单测试：发一个空的分析请求会抛配置异常
            // 这里我们通过尝试构建来间接判断
            visionAiClient.analyzeTongueImage("", "image/jpeg", "test", "test");
            return true;
        } catch (IllegalStateException e) {
            // 配置错误导致的异常，说明AI不可用
            return false;
        } catch (Exception e) {
            // 其他异常（如网络错误）也认为不可用
            return false;
        }
    }

    private String buildSystemPrompt() {
        return """
                你是一位经验丰富的中医舌诊专家。请仔细观察用户提供的舌象照片，按照中医舌诊理论进行专业分析。
                
                分析时请关注以下方面：
                1. 舌色（淡白、淡红、红、绛、紫等）
                2. 舌形（胖大、瘦薄、齿痕、裂纹、点刺等）
                3. 舌苔（厚薄、润燥、腻腐、剥落等）
                4. 苔色（白、黄、灰、黑等）
                5. 津液（润泽、干燥、水滑等）
                
                请基于舌象特征给出：
                - 体质倾向判断（如：气虚、阴虚、阳虚、湿热、痰湿等）
                - 相应的养生建议（饮食、作息、运动方面）
                - 注意事项和危险信号提示
                
                重要提示：
                - 你的分析仅供参考，不能替代专业医生诊断
                - 如果发现明显异常，请建议用户及时就医
                - 请用中文回答
                """;
    }

    private String buildUserPrompt() {
        return """
                请仔细观察这张舌象照片，进行中医舌诊分析。
                
                请严格按照以下JSON格式返回结果（只返回JSON，不要有其他文字）：
                {
                  "tongueColor": "舌色描述，如淡红舌",
                  "tongueCoating": "舌苔整体描述，如薄白苔",
                  "tongueDryness": "润燥情况，如润泽",
                  "tongueShape": "舌形描述，如舌体大小适中",
                  "coatingThickness": "舌苔厚薄，如薄苔",
                  "coatingColor": "舌苔颜色，如白色",
                  "constitutionSuggestion": "体质倾向判断，50-100字",
                  "healthAdvice": "养生建议，100-200字，包含饮食、作息、运动",
                  "warningSigns": "注意事项/危险信号，30-80字",
                  "analysisNote": "其他分析备注，可选"
                }
                
                请确保每个字段都有合理的内容，不要留空。如果某些特征不明显，请描述为"未见明显异常"或"基本正常"。
                """;
    }

    private void parseJsonResponse(String rawResponse, TongueAnalysisResult result) {
        try {
            // 尝试直接解析
            JsonNode root = objectMapper.readTree(extractJson(rawResponse));

            result.setTongueColor(safeText(root, "tongueColor"));
            result.setTongueCoating(safeText(root, "tongueCoating"));
            result.setTongueDryness(safeText(root, "tongueDryness"));
            result.setTongueShape(safeText(root, "tongueShape"));
            result.setCoatingThickness(safeText(root, "coatingThickness"));
            result.setCoatingColor(safeText(root, "coatingColor"));
            result.setConstitutionSuggestion(safeText(root, "constitutionSuggestion"));
            result.setHealthAdvice(safeText(root, "healthAdvice"));
            result.setWarningSigns(safeText(root, "warningSigns"));
            result.setAnalysisNote(safeText(root, "analysisNote"));

        } catch (Exception e) {
            log.warn("解析舌象AI响应JSON失败，使用原始文本作为备注: {}", e.getMessage());
            // 如果解析失败，把原始文本放到备注里
            result.setAnalysisNote(rawResponse);
            // 设置默认值
            if (result.getTongueColor() == null) result.setTongueColor("待确认");
            if (result.getTongueCoating() == null) result.setTongueCoating("待确认");
            if (result.getTongueDryness() == null) result.setTongueDryness("待确认");
            if (result.getConstitutionSuggestion() == null) {
                result.setConstitutionSuggestion("AI分析结果格式异常，请参考详细备注");
            }
        }
    }

    /**
     * 从文本中提取JSON部分
     */
    private String extractJson(String text) {
        if (text == null || text.isBlank()) return "{}";
        text = text.trim();
        // 找到第一个 { 和最后一个 }
        int start = text.indexOf('{');
        int end = text.lastIndexOf('}');
        if (start >= 0 && end > start) {
            return text.substring(start, end + 1);
        }
        return text;
    }

    private String safeText(JsonNode node, String field) {
        JsonNode value = node.path(field);
        if (value.isMissingNode() || value.isNull()) {
            return "";
        }
        String text = value.asText().trim();
        return text.isEmpty() ? "未见明显异常" : text;
    }
}
