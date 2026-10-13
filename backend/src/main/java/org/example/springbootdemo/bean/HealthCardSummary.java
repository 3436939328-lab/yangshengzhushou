package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;
import java.util.List;

/**
 * 健康卡摘要
 */
public class HealthCardSummary implements Serializable {

    private String subjectId;
    private String subjectName;
    private String generatedAt;
    private String dataVersion;

    private int attentionCount;
    private int urgentCount;
    private List<String> missingCategories;
    private String olderItemsNote;

    // 各类别最新记录摘要
    private MetricSummary bloodPressure;
    private MetricSummary bloodSugar;
    private MetricSummary heartRate;
    private MetricSummary bloodOxygen;
    private MetricSummary temperature;
    private BodySummary body;
    private SleepSummary sleep;
    private StepsSummary steps;

    private static final long serialVersionUID = 1L;

    public static class MetricSummary implements Serializable {
        private String valueText;
        private String measuredAt;
        private String state;
        private String stateText;
        private static final long serialVersionUID = 1L;

        public String getValueText() { return valueText; }
        public void setValueText(String valueText) { this.valueText = valueText; }
        public String getMeasuredAt() { return measuredAt; }
        public void setMeasuredAt(String measuredAt) { this.measuredAt = measuredAt; }
        public String getState() { return state; }
        public void setState(String state) { this.state = state; }
        public String getStateText() { return stateText; }
        public void setStateText(String stateText) { this.stateText = stateText; }
    }

    public static class BodySummary extends MetricSummary {
        private Double heightCm;
        private Double weightKg;
        private Double bmi;
        public Double getHeightCm() { return heightCm; }
        public void setHeightCm(Double heightCm) { this.heightCm = heightCm; }
        public Double getWeightKg() { return weightKg; }
        public void setWeightKg(Double weightKg) { this.weightKg = weightKg; }
        public Double getBmi() { return bmi; }
        public void setBmi(Double bmi) { this.bmi = bmi; }
    }

    public static class SleepSummary extends MetricSummary {
        private Integer totalMinutes;
        private String totalText;
        private String sleepType;
        private String source;
        private Integer lightMinutes;
        private Integer deepMinutes;
        private Integer remMinutes;
        public Integer getTotalMinutes() { return totalMinutes; }
        public void setTotalMinutes(Integer totalMinutes) { this.totalMinutes = totalMinutes; }
        public String getTotalText() { return totalText; }
        public void setTotalText(String totalText) { this.totalText = totalText; }
        public String getSleepType() { return sleepType; }
        public void setSleepType(String sleepType) { this.sleepType = sleepType; }
        public String getSource() { return source; }
        public void setSource(String source) { this.source = source; }
        public Integer getLightMinutes() { return lightMinutes; }
        public void setLightMinutes(Integer lightMinutes) { this.lightMinutes = lightMinutes; }
        public Integer getDeepMinutes() { return deepMinutes; }
        public void setDeepMinutes(Integer deepMinutes) { this.deepMinutes = deepMinutes; }
        public Integer getRemMinutes() { return remMinutes; }
        public void setRemMinutes(Integer remMinutes) { this.remMinutes = remMinutes; }
    }

    public static class StepsSummary implements Serializable {
        private Integer steps;
        private String measuredAt;
        private String source;
        private static final long serialVersionUID = 1L;
        public Integer getSteps() { return steps; }
        public void setSteps(Integer steps) { this.steps = steps; }
        public String getMeasuredAt() { return measuredAt; }
        public void setMeasuredAt(String measuredAt) { this.measuredAt = measuredAt; }
        public String getSource() { return source; }
        public void setSource(String source) { this.source = source; }
    }

    public String getSubjectId() { return subjectId; }
    public void setSubjectId(String subjectId) { this.subjectId = subjectId; }
    public String getSubjectName() { return subjectName; }
    public void setSubjectName(String subjectName) { this.subjectName = subjectName; }
    public String getGeneratedAt() { return generatedAt; }
    public void setGeneratedAt(String generatedAt) { this.generatedAt = generatedAt; }
    public String getDataVersion() { return dataVersion; }
    public void setDataVersion(String dataVersion) { this.dataVersion = dataVersion; }
    public int getAttentionCount() { return attentionCount; }
    public void setAttentionCount(int attentionCount) { this.attentionCount = attentionCount; }
    public int getUrgentCount() { return urgentCount; }
    public void setUrgentCount(int urgentCount) { this.urgentCount = urgentCount; }
    public List<String> getMissingCategories() { return missingCategories; }
    public void setMissingCategories(List<String> missingCategories) { this.missingCategories = missingCategories; }
    public String getOlderItemsNote() { return olderItemsNote; }
    public void setOlderItemsNote(String olderItemsNote) { this.olderItemsNote = olderItemsNote; }
    public MetricSummary getBloodPressure() { return bloodPressure; }
    public void setBloodPressure(MetricSummary bloodPressure) { this.bloodPressure = bloodPressure; }
    public MetricSummary getBloodSugar() { return bloodSugar; }
    public void setBloodSugar(MetricSummary bloodSugar) { this.bloodSugar = bloodSugar; }
    public MetricSummary getHeartRate() { return heartRate; }
    public void setHeartRate(MetricSummary heartRate) { this.heartRate = heartRate; }
    public MetricSummary getBloodOxygen() { return bloodOxygen; }
    public void setBloodOxygen(MetricSummary bloodOxygen) { this.bloodOxygen = bloodOxygen; }
    public MetricSummary getTemperature() { return temperature; }
    public void setTemperature(MetricSummary temperature) { this.temperature = temperature; }
    public BodySummary getBody() { return body; }
    public void setBody(BodySummary body) { this.body = body; }
    public SleepSummary getSleep() { return sleep; }
    public void setSleep(SleepSummary sleep) { this.sleep = sleep; }
    public StepsSummary getSteps() { return steps; }
    public void setSteps(StepsSummary steps) { this.steps = steps; }
}
