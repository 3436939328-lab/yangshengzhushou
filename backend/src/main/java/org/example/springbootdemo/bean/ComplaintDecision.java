package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class ComplaintDecision implements Serializable {

    public static final String RESULT_UPHELD = "UPHELD";
    public static final String RESULT_REJECTED = "REJECTED";
    public static final String SEVERITY_GENERAL = "GENERAL";
    public static final String SEVERITY_SERIOUS = "SERIOUS";

    private Long id;
    private Long eventId;
    private Long reviewerId;
    private String result;
    private String severity;
    private String reason;
    private String evidenceSnapshot;
    private Date createdAt;

    private static final long serialVersionUID = 1L;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getEventId() { return eventId; }
    public void setEventId(Long eventId) { this.eventId = eventId; }
    public Long getReviewerId() { return reviewerId; }
    public void setReviewerId(Long reviewerId) { this.reviewerId = reviewerId; }
    public String getResult() { return result; }
    public void setResult(String result) { this.result = result == null ? null : result.trim(); }
    public String getSeverity() { return severity; }
    public void setSeverity(String severity) { this.severity = severity == null ? null : severity.trim(); }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason == null ? null : reason.trim(); }
    public String getEvidenceSnapshot() { return evidenceSnapshot; }
    public void setEvidenceSnapshot(String evidenceSnapshot) { this.evidenceSnapshot = evidenceSnapshot; }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
