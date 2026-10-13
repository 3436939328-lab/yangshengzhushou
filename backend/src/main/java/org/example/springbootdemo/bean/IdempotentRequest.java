package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class IdempotentRequest implements Serializable {

    public static final String STATUS_PENDING = "PENDING";
    public static final String STATUS_DONE = "DONE";

    private Long id;
    private Long actorId;
    private String action;
    private String key;
    private String requestHash;
    private String resultRef;
    private String status;
    private Date expiresAt;
    private Date createdAt;

    private static final long serialVersionUID = 1L;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getActorId() { return actorId; }
    public void setActorId(Long actorId) { this.actorId = actorId; }
    public String getAction() { return action; }
    public void setAction(String action) { this.action = action == null ? null : action.trim(); }
    public String getKey() { return key; }
    public void setKey(String key) { this.key = key == null ? null : key.trim(); }
    public String getRequestHash() { return requestHash; }
    public void setRequestHash(String requestHash) { this.requestHash = requestHash == null ? null : requestHash.trim(); }
    public String getResultRef() { return resultRef; }
    public void setResultRef(String resultRef) { this.resultRef = resultRef == null ? null : resultRef.trim(); }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status == null ? null : status.trim(); }
    public Date getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Date expiresAt) { this.expiresAt = expiresAt; }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
