package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class AdminPermission implements Serializable {

    public static final String CODE_COMPLAINT_REVIEW = "admin:complaint:review";
    public static final String CODE_SANCTION_MANAGE = "admin:sanction:manage";
    public static final String CODE_SANCTION_PERMANENT = "admin:sanction:permanent";
    public static final String CODE_APPEAL_REVIEW = "admin:appeal:review";

    private Long id;
    private Long adminUserId;
    private String permissionCode;
    private Long grantedBy;
    private Date grantedAt;

    private static final long serialVersionUID = 1L;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getAdminUserId() { return adminUserId; }
    public void setAdminUserId(Long adminUserId) { this.adminUserId = adminUserId; }
    public String getPermissionCode() { return permissionCode; }
    public void setPermissionCode(String permissionCode) { this.permissionCode = permissionCode == null ? null : permissionCode.trim(); }
    public Long getGrantedBy() { return grantedBy; }
    public void setGrantedBy(Long grantedBy) { this.grantedBy = grantedBy; }
    public Date getGrantedAt() { return grantedAt; }
    public void setGrantedAt(Date grantedAt) { this.grantedAt = grantedAt; }
}
