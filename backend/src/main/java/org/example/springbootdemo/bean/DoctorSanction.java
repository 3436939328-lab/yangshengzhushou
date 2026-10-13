package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class DoctorSanction implements Serializable {

    public static final String TYPE_WARNING = "WARNING";
    public static final String TYPE_SUSPEND_1D = "SUSPEND_1D";
    public static final String TYPE_SUSPEND_7D = "SUSPEND_7D";
    public static final String TYPE_SUSPEND_30D = "SUSPEND_30D";
    public static final String TYPE_PERMANENT_BAN = "PERMANENT_BAN";
    public static final String SCOPE_ACCEPTING = "ACCEPTING";
    public static final String SCOPE_LOGIN_LIMITED = "LOGIN_LIMITED";
    public static final String STATUS_ACTIVE = "ACTIVE";
    public static final String STATUS_EXPIRED = "EXPIRED";
    public static final String STATUS_REVOKED = "REVOKED";

    private Long id;
    private Long eventId;
    private Long decisionId;
    private Long doctorId;
    private String type;
    private String scope;
    private String status;
    private Date startsAt;
    private Date endsAt;
    private Long issuerId;
    private Long approverId;
    private String reason;
    private Date createdAt;

    private static final long serialVersionUID = 1L;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getEventId() { return eventId; }
    public void setEventId(Long eventId) { this.eventId = eventId; }
    public Long getDecisionId() { return decisionId; }
    public void setDecisionId(Long decisionId) { this.decisionId = decisionId; }
    public Long getDoctorId() { return doctorId; }
    public void setDoctorId(Long doctorId) { this.doctorId = doctorId; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type == null ? null : type.trim(); }
    public String getScope() { return scope; }
    public void setScope(String scope) { this.scope = scope == null ? null : scope.trim(); }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status == null ? null : status.trim(); }
    public Date getStartsAt() { return startsAt; }
    public void setStartsAt(Date startsAt) { this.startsAt = startsAt; }
    public Date getEndsAt() { return endsAt; }
    public void setEndsAt(Date endsAt) { this.endsAt = endsAt; }
    public Long getIssuerId() { return issuerId; }
    public void setIssuerId(Long issuerId) { this.issuerId = issuerId; }
    public Long getApproverId() { return approverId; }
    public void setApproverId(Long approverId) { this.approverId = approverId; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason == null ? null : reason.trim(); }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
