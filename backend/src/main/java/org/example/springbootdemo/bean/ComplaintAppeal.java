package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class ComplaintAppeal implements Serializable {

    public static final String STATUS_PENDING = "PENDING";
    public static final String STATUS_REVIEWING = "REVIEWING";
    public static final String STATUS_MAINTAINED = "MAINTAINED";
    public static final String STATUS_REDUCED = "REDUCED";
    public static final String STATUS_REVOKED = "REVOKED";

    private Long id;
    private Long decisionId;
    private Long doctorId;
    private String status;
    private String reason;
    private Long reviewerId;
    private String resultReason;
    private Date createdAt;
    private Date reviewedAt;
    private Integer version;

    private static final long serialVersionUID = 1L;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getDecisionId() { return decisionId; }
    public void setDecisionId(Long decisionId) { this.decisionId = decisionId; }
    public Long getDoctorId() { return doctorId; }
    public void setDoctorId(Long doctorId) { this.doctorId = doctorId; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status == null ? null : status.trim(); }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason == null ? null : reason.trim(); }
    public Long getReviewerId() { return reviewerId; }
    public void setReviewerId(Long reviewerId) { this.reviewerId = reviewerId; }
    public String getResultReason() { return resultReason; }
    public void setResultReason(String resultReason) { this.resultReason = resultReason == null ? null : resultReason.trim(); }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
    public Date getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(Date reviewedAt) { this.reviewedAt = reviewedAt; }
    public Integer getVersion() { return version; }
    public void setVersion(Integer version) { this.version = version; }
}
