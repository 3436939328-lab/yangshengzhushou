package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

/**
 * 舌象照片记录
 */
public class TongueImageRecord implements Serializable {

    private Long id;
    private Long userId;
    private String imageAssetId;
    private String imageUrl;
    private String thumbnailUrl;
    private String capturedAt;
    private String uploadedAt;
    private String source; // CAMERA, ALBUM
    private String qualityStatus; // PENDING, ANALYZABLE, NEED_RETAKE
    private String qualityNote;
    private String analysisStatus; // PENDING_UPLOAD, UPLOADING, QUEUED, ANALYZING, SUCCESS, FAILED, CANCELLED
    private String analysisId;
    private String analysisResultJson;
    private String modelVersion;
    private String note;
    private Boolean isDeleted;
    private Date createTime;
    private Date updateTime;

    private static final long serialVersionUID = 1L;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getImageAssetId() { return imageAssetId; }
    public void setImageAssetId(String imageAssetId) { this.imageAssetId = imageAssetId == null ? null : imageAssetId.trim(); }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl == null ? null : imageUrl.trim(); }
    public String getThumbnailUrl() { return thumbnailUrl; }
    public void setThumbnailUrl(String thumbnailUrl) { this.thumbnailUrl = thumbnailUrl == null ? null : thumbnailUrl.trim(); }
    public String getCapturedAt() { return capturedAt; }
    public void setCapturedAt(String capturedAt) { this.capturedAt = capturedAt == null ? null : capturedAt.trim(); }
    public String getUploadedAt() { return uploadedAt; }
    public void setUploadedAt(String uploadedAt) { this.uploadedAt = uploadedAt == null ? null : uploadedAt.trim(); }
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
    public String getAnalysisResultJson() { return analysisResultJson; }
    public void setAnalysisResultJson(String analysisResultJson) { this.analysisResultJson = analysisResultJson == null ? null : analysisResultJson.trim(); }
    public String getModelVersion() { return modelVersion; }
    public void setModelVersion(String modelVersion) { this.modelVersion = modelVersion == null ? null : modelVersion.trim(); }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note == null ? null : note.trim(); }
    public Boolean getIsDeleted() { return isDeleted; }
    public void setIsDeleted(Boolean isDeleted) { this.isDeleted = isDeleted; }
    public Date getCreateTime() { return createTime; }
    public void setCreateTime(Date createTime) { this.createTime = createTime; }
    public Date getUpdateTime() { return updateTime; }
    public void setUpdateTime(Date updateTime) { this.updateTime = updateTime; }
}
