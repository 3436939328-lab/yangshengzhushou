package org.example.springbootdemo.ai.tongue;

/**
 * 舌象AI分析结果
 */
public class TongueAnalysisResult {

    private boolean success;
    private String errorMessage;

    // 舌象特征
    private String tongueColor;         // 舌色
    private String tongueCoating;       // 舌苔描述
    private String tongueDryness;       // 润燥
    private String tongueShape;         // 舌形
    private String coatingThickness;    // 舌苔厚薄
    private String coatingColor;        // 舌苔颜色

    // 中医判断
    private String constitutionSuggestion;  // 体质倾向判断
    private String healthAdvice;            // 养生建议
    private String warningSigns;            // 注意事项/危险信号
    private String analysisNote;            // 分析备注

    private String modelVersion;

    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    public String getTongueColor() { return tongueColor; }
    public void setTongueColor(String tongueColor) { this.tongueColor = tongueColor; }

    public String getTongueCoating() { return tongueCoating; }
    public void setTongueCoating(String tongueCoating) { this.tongueCoating = tongueCoating; }

    public String getTongueDryness() { return tongueDryness; }
    public void setTongueDryness(String tongueDryness) { this.tongueDryness = tongueDryness; }

    public String getTongueShape() { return tongueShape; }
    public void setTongueShape(String tongueShape) { this.tongueShape = tongueShape; }

    public String getCoatingThickness() { return coatingThickness; }
    public void setCoatingThickness(String coatingThickness) { this.coatingThickness = coatingThickness; }

    public String getCoatingColor() { return coatingColor; }
    public void setCoatingColor(String coatingColor) { this.coatingColor = coatingColor; }

    public String getConstitutionSuggestion() { return constitutionSuggestion; }
    public void setConstitutionSuggestion(String constitutionSuggestion) { this.constitutionSuggestion = constitutionSuggestion; }

    public String getHealthAdvice() { return healthAdvice; }
    public void setHealthAdvice(String healthAdvice) { this.healthAdvice = healthAdvice; }

    public String getWarningSigns() { return warningSigns; }
    public void setWarningSigns(String warningSigns) { this.warningSigns = warningSigns; }

    public String getAnalysisNote() { return analysisNote; }
    public void setAnalysisNote(String analysisNote) { this.analysisNote = analysisNote; }

    public String getModelVersion() { return modelVersion; }
    public void setModelVersion(String modelVersion) { this.modelVersion = modelVersion; }
}
