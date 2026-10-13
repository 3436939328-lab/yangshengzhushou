package org.example.springbootdemo.bean;

import java.util.List;

public class HealthDetailBundle {

    private List<HealthQuestionnaireRecord> questionnaireRecords;
    private List<HealthIndicatorRecord> healthIndicators;
    private List<TongueObservationRecord> tongueNotes;

    public HealthDetailBundle() {
    }

    public HealthDetailBundle(
            List<HealthQuestionnaireRecord> questionnaireRecords,
            List<HealthIndicatorRecord> healthIndicators,
            List<TongueObservationRecord> tongueNotes) {
        this.questionnaireRecords = questionnaireRecords;
        this.healthIndicators = healthIndicators;
        this.tongueNotes = tongueNotes;
    }

    public List<HealthQuestionnaireRecord> getQuestionnaireRecords() {
        return questionnaireRecords;
    }

    public void setQuestionnaireRecords(List<HealthQuestionnaireRecord> questionnaireRecords) {
        this.questionnaireRecords = questionnaireRecords;
    }

    public List<HealthIndicatorRecord> getHealthIndicators() {
        return healthIndicators;
    }

    public void setHealthIndicators(List<HealthIndicatorRecord> healthIndicators) {
        this.healthIndicators = healthIndicators;
    }

    public List<TongueObservationRecord> getTongueNotes() {
        return tongueNotes;
    }

    public void setTongueNotes(List<TongueObservationRecord> tongueNotes) {
        this.tongueNotes = tongueNotes;
    }
}
