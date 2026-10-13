package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class Complaint implements Serializable {

    public static final String STATUS_SUBMITTED = "SUBMITTED";
    public static final String STATUS_REVIEWING = "REVIEWING";
    public static final String STATUS_NEED_INFO = "NEED_INFO";
    public static final String STATUS_UPHELD = "UPHELD";
    public static final String STATUS_REJECTED = "REJECTED";
    public static final String STATUS_MERGED = "MERGED";

    private Long id;
    private Long eventId;
    private Long reporterId;
    private String description;
    private String status;
    private Long assigneeId;
    private Long mergedIntoId;
    private Date createdAt;
    private Date updatedAt;
    private Integer version;

    private static final long serialVersionUID = 1L;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getEventId() { return eventId; }
    public void setEventId(Long eventId) { this.eventId = eventId; }
    public Long getReporterId() { return reporterId; }
    public void setReporterId(Long reporterId) { this.reporterId = reporterId; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description == null ? null : description.trim(); }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status == null ? null : status.trim(); }
    public Long getAssigneeId() { return assigneeId; }
    public void setAssigneeId(Long assigneeId) { this.assigneeId = assigneeId; }
    public Long getMergedIntoId() { return mergedIntoId; }
    public void setMergedIntoId(Long mergedIntoId) { this.mergedIntoId = mergedIntoId; }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }
    public Integer getVersion() { return version; }
    public void setVersion(Integer version) { this.version = version; }
}
