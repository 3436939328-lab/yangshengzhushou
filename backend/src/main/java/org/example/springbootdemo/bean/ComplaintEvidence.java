package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class ComplaintEvidence implements Serializable {

    private Long id;
    private Long complaintId;
    private Long uploaderId;
    private String storageBucket;
    private String objectKey;
    private String format;
    private Long size;
    private String summary;
    private Date createdAt;

    private static final long serialVersionUID = 1L;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getComplaintId() { return complaintId; }
    public void setComplaintId(Long complaintId) { this.complaintId = complaintId; }
    public Long getUploaderId() { return uploaderId; }
    public void setUploaderId(Long uploaderId) { this.uploaderId = uploaderId; }
    public String getStorageBucket() { return storageBucket; }
    public void setStorageBucket(String storageBucket) { this.storageBucket = storageBucket == null ? null : storageBucket.trim(); }
    public String getObjectKey() { return objectKey; }
    public void setObjectKey(String objectKey) { this.objectKey = objectKey == null ? null : objectKey.trim(); }
    public String getFormat() { return format; }
    public void setFormat(String format) { this.format = format == null ? null : format.trim(); }
    public Long getSize() { return size; }
    public void setSize(Long size) { this.size = size; }
    public String getSummary() { return summary; }
    public void setSummary(String summary) { this.summary = summary == null ? null : summary.trim(); }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
