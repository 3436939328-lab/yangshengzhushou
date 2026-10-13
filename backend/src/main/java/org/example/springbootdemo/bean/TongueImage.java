package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

/**
 * 舌象图片记录
 */
public class TongueImage implements Serializable {

    private Long id;
    private Long userId;
    private String assetId;
    private String imageUrl;
    private String thumbnailUrl;
    private String source;          // CAMERA / ALBUM
    private String qualityStatus;   // PENDING / ANALYZABLE / NEED_RETAKE
    private String qualityNote;
    private String analysisStatus;  // PENDING_UPLOAD / UPLOADING / QUEUED / ANALYZING / SUCCESS / FAILED / CANCELLED
    private String analysisId;
    private String modelVersion;

    // 分析结果字段
    private String tongueColor;         // 舌色
    private String tongueCoating;       // 舌苔
    private String tongueDryness;       // 润燥
    private String tongueShape;         // 舌形
    private String coatingThickness;    // 舌苔厚薄
    private String coatingColor;        // 舌苔颜色

    // 中医判断
    private String constitutionSuggestion;  // 体质倾向判断
    private String healthAdvice;            // 养生建议
    private String warningSigns;            // 注意事项/危险信号
    private String analysisNote;            // 分析备注

    // 时间
    private String capturedAt;
    private String uploadedAt;
    private String analyzedAt;
    private Date createTime;
    private Integer isDeleted;

    private static final long serialVersionUID = 1L;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getAssetId() { return assetId; }
    public void setAssetId(String assetId) { this.assetId = assetId == null ? null : assetId.trim(); }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl == null ? null : imageUrl.trim(); }

    public String getThumbnailUrl() { return thumbnailUrl; }
    public void setThumbnailUrl(String thumbnailUrl) { this.thumbnailUrl = thumbnailUrl == null ? null : thumbnailUrl.trim(); }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source == null ? null : source.trim(); }

    public String getQualityStatus() { return qualityStatus; }
    public void setQualityStatus(String qualityStatus) { this.qualityStatus = qualityStatus == null ? null : qualityStatus.trim(); }

    public String getQualityNote() { return qualityNote; }
    public void setQualityNote(String qualityNote) { this.qualityNote = qualityNote == null ? null : qualityNote.trim(); }

    public String getAnalysisStatus() { return analysisStatus; }
    public void setAnalysisStatus(String analysisStatus) { this.analysisStatus = analysisStatus == null ? null : analysisStatus.trim(); }

    public String getAnalysisId() { return analysisId; }
    public void setAnalysisId(String analysisId) { this.analysisId = analysisId == null ? null : analysisId.trim(); }

    public String getModelVersion() { return modelVersion; }
    public void setModelVersion(String modelVersion) { this.modelVersion = modelVersion == null ? null : modelVersion.trim(); }

    public String getTongueColor() { return tongueColor; }
    public void setTongueColor(String tongueColor) { this.tongueColor = tongueColor == null ? null : tongueColor.trim(); }

    public String getTongueCoating() { return tongueCoating; }
    public void setTongueCoating(String tongueCoating) { this.tongueCoating = tongueCoating == null ? null : tongueCoating.trim(); }

    public String getTongueDryness() { return tongueDryness; }
    public void setTongueDryness(String tongueDryness) { this.tongueDryness = tongueDryness == null ? null : tongueDryness.trim(); }

    public String getTongueShape() { return tongueShape; }
    public void setTongueShape(String tongueShape) { this.tongueShape = tongueShape == null ? null : tongueShape.trim(); }

    public String getCoatingThickness() { return coatingThickness; }
    public void setCoatingThickness(String coatingThickness) { this.coatingThickness = coatingThickness == null ? null : coatingThickness.trim(); }

    public String getCoatingColor() { return coatingColor; }
    public void setCoatingColor(String coatingColor) { this.coatingColor = coatingColor == null ? null : coatingColor.trim(); }

    public String getConstitutionSuggestion() { return constitutionSuggestion; }
    public void setConstitutionSuggestion(String constitutionSuggestion) { this.constitutionSuggestion = constitutionSuggestion == null ? null : constitutionSuggestion.trim(); }

    public String getHealthAdvice() { return healthAdvice; }
    public void setHealthAdvice(String healthAdvice) { this.healthAdvice = healthAdvice == null ? null : healthAdvice.trim(); }

    public String getWarningSigns() { return warningSigns; }
    public void setWarningSigns(String warningSigns) { this.warningSigns = warningSigns == null ? null : warningSigns.trim(); }

    public String getAnalysisNote() { return analysisNote; }
    public void setAnalysisNote(String analysisNote) { this.analysisNote = analysisNote == null ? null : analysisNote.trim(); }

    public String getCapturedAt() { return capturedAt; }
    public void setCapturedAt(String capturedAt) { this.capturedAt = capturedAt == null ? null : capturedAt.trim(); }

    public String getUploadedAt() { return uploadedAt; }
    public void setUploadedAt(String uploadedAt) { this.uploadedAt = uploadedAt == null ? null : uploadedAt.trim(); }

    public String getAnalyzedAt() { return analyzedAt; }
    public void setAnalyzedAt(String analyzedAt) { this.analyzedAt = analyzedAt == null ? null : analyzedAt.trim(); }

    public Date getCreateTime() { return createTime; }
    public void setCreateTime(Date createTime) { this.createTime = createTime; }

    public Integer getIsDeleted() { return isDeleted; }
    public void setIsDeleted(Integer isDeleted) { this.isDeleted = isDeleted; }
}
