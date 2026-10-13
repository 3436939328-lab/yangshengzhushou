package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class ComplaintEvent implements Serializable {

    public static final String DECISION_UPHELD = "UPHELD";
    public static final String DECISION_REJECTED = "REJECTED";
    public static final String DECISION_MERGED = "MERGED";

    private Long id;
    private Long doctorId;
    private Long consultationId;
    private String category;
    private String effectiveDecision;
    private Date decisionAt;
    private Integer policyVersion;
    private Date createdAt;

    private static final long serialVersionUID = 1L;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getDoctorId() { return doctorId; }
    public void setDoctorId(Long doctorId) { this.doctorId = doctorId; }
    public Long getConsultationId() { return consultationId; }
    public void setConsultationId(Long consultationId) { this.consultationId = consultationId; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category == null ? null : category.trim(); }
    public String getEffectiveDecision() { return effectiveDecision; }
    public void setEffectiveDecision(String effectiveDecision) { this.effectiveDecision = effectiveDecision == null ? null : effectiveDecision.trim(); }
    public Date getDecisionAt() { return decisionAt; }
    public void setDecisionAt(Date decisionAt) { this.decisionAt = decisionAt; }
    public Integer getPolicyVersion() { return policyVersion; }
    public void setPolicyVersion(Integer policyVersion) { this.policyVersion = policyVersion; }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
