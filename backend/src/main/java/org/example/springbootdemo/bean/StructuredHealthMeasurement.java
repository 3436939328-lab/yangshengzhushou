package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

/**
 * 结构化健康测量记录
 * 使用统一表结构，metric_code 区分指标类型，type_specific_json 存储类型专属字段
 */
public class StructuredHealthMeasurement implements Serializable {

    private Long id;
    private Long userId;

    /**
     * 指标编码：BLOOD_PRESSURE, BLOOD_SUGAR, HEART_RATE, BLOOD_OXYGEN,
     * TEMPERATURE, BODY, STEPS, EXERCISE, WATER, SLEEP
     */
    private String metricCode;

    /**
     * 测量时间（ISO格式字符串）
     */
    private String measuredAt;

    /**
     * 时区，如 Asia/Shanghai
     */
    private String timezone;

    /**
     * 数据来源：MANUAL, DEVICE, WEARABLE
     */
    private String source;

    /**
     * 来源名称，如设备名
     */
    private String sourceName;

    /**
     * 来源设备记录ID
     */
    private String providerRecordId;

    /**
     * 数据版本号
     */
    private Integer version;

    /**
     * 数据质量状态
     */
    private String qualityStatus;

    /**
     * 评估状态：IN_RANGE, ATTENTION, URGENT, UNKNOWN
     */
    private String assessment;

    /**
     * 评估原因
     */
    private String assessmentReason;

    /**
     * 备注
     */
    private String note;

    /**
     * 类型专属字段的JSON表示
     * 血压：{systolic, diastolic, pulse, position, arm}
     * 血糖：{value, sugarType, measureMethod}
     * 心率：{value, context}
     * 血氧：{value}
     * 体温：{value, site}
     * 体格：{heightCm, weightKg, waistCm, bmi}
     * 步数：{steps}
     * 运动：{durationMinutes, exerciseType, calories}
     * 饮水：{amountMl}
     * 睡眠：{sleepStartAt, sleepEndAt, totalSleepMinutes, lightMinutes, deepMinutes,
     *        remMinutes, awakeMinutes, awakenings, sleepType, subjectiveFeeling, feelingNote, stagesJson}
     */
    private String typeSpecificJson;

    /**
     * 同步状态：pending, synced, failed
     */
    private String syncStatus;

    /**
     * 是否已删除（逻辑删除）
     */
    private Boolean isDeleted;

    private Date createTime;
    private Date updateTime;

    private static final long serialVersionUID = 1L;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getMetricCode() {
        return metricCode;
    }

    public void setMetricCode(String metricCode) {
        this.metricCode = metricCode == null ? null : metricCode.trim();
    }

    public String getMeasuredAt() {
        return measuredAt;
    }

    public void setMeasuredAt(String measuredAt) {
        this.measuredAt = measuredAt == null ? null : measuredAt.trim();
    }

    public String getTimezone() {
        return timezone;
    }

    public void setTimezone(String timezone) {
        this.timezone = timezone == null ? null : timezone.trim();
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source == null ? null : source.trim();
    }

    public String getSourceName() {
        return sourceName;
    }

    public void setSourceName(String sourceName) {
        this.sourceName = sourceName == null ? null : sourceName.trim();
    }

    public String getProviderRecordId() {
        return providerRecordId;
    }

    public void setProviderRecordId(String providerRecordId) {
        this.providerRecordId = providerRecordId == null ? null : providerRecordId.trim();
    }

    public Integer getVersion() {
        return version;
    }

    public void setVersion(Integer version) {
        this.version = version;
    }

    public String getQualityStatus() {
        return qualityStatus;
    }

    public void setQualityStatus(String qualityStatus) {
        this.qualityStatus = qualityStatus == null ? null : qualityStatus.trim();
    }

    public String getAssessment() {
        return assessment;
    }

    public void setAssessment(String assessment) {
        this.assessment = assessment == null ? null : assessment.trim();
    }

    public String getAssessmentReason() {
        return assessmentReason;
    }

    public void setAssessmentReason(String assessmentReason) {
        this.assessmentReason = assessmentReason == null ? null : assessmentReason.trim();
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note == null ? null : note.trim();
    }

    public String getTypeSpecificJson() {
        return typeSpecificJson;
    }

    public void setTypeSpecificJson(String typeSpecificJson) {
        this.typeSpecificJson = typeSpecificJson == null ? null : typeSpecificJson.trim();
    }

    public String getSyncStatus() {
        return syncStatus;
    }

    public void setSyncStatus(String syncStatus) {
        this.syncStatus = syncStatus == null ? null : syncStatus.trim();
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public void setIsDeleted(Boolean isDeleted) {
        this.isDeleted = isDeleted;
    }

    public Date getCreateTime() {
        return createTime;
    }

    public void setCreateTime(Date createTime) {
        this.createTime = createTime;
    }

    public Date getUpdateTime() {
        return updateTime;
    }

    public void setUpdateTime(Date updateTime) {
        this.updateTime = updateTime;
    }
}
