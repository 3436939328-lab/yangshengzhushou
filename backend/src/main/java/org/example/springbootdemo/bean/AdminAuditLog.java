package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class AdminAuditLog implements Serializable {

    private Long id;
    private Long actorId;
    private String action;
    private String targetType;
    private Long targetId;
    private String summary;
    private String reason;
    private String result;
    private String requestId;
    private Date createdAt;

    private static final long serialVersionUID = 1L;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getActorId() { return actorId; }
    public void setActorId(Long actorId) { this.actorId = actorId; }
    public String getAction() { return action; }
    public void setAction(String action) { this.action = action == null ? null : action.trim(); }
    public String getTargetType() { return targetType; }
    public void setTargetType(String targetType) { this.targetType = targetType == null ? null : targetType.trim(); }
    public Long getTargetId() { return targetId; }
    public void setTargetId(Long targetId) { this.targetId = targetId; }
    public String getSummary() { return summary; }
    public void setSummary(String summary) { this.summary = summary; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason == null ? null : reason.trim(); }
    public String getResult() { return result; }
    public void setResult(String result) { this.result = result == null ? null : result.trim(); }
    public String getRequestId() { return requestId; }
    public void setRequestId(String requestId) { this.requestId = requestId == null ? null : requestId.trim(); }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
