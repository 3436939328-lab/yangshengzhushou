package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class DoctorProfile implements Serializable {

    private Long id;
    private Long userId;
    private String doctorName;
    private String title;
    private String specialty;
    private String introduction;
    private Date createTime;

    /**
     * 头像URL
     */
    private String avatar;

    /**
     * 科室
     */
    private String department;

    /**
     * 医师资格证编号
     */
    private String licenseNumber;

    /**
     * 医师资格证照片URL（多张用逗号分隔）
     */
    private String licenseImageUrls;

    /**
     * 资质审核状态：PENDING-待审核, APPROVED-已通过, REJECTED-未通过
     */
    private String verificationStatus;

    /**
     * 审核意见
     */
    private String verificationRemark;

    /**
     * 是否开启接诊：true-开启, false-关闭
     */
    private Boolean accepting;

    private static final long serialVersionUID = 1L;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getDoctorName() {
        return doctorName;
    }

    public void setDoctorName(String doctorName) {
        this.doctorName = doctorName == null ? null : doctorName.trim();
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title == null ? null : title.trim();
    }

    public String getSpecialty() {
        return specialty;
    }

    public void setSpecialty(String specialty) {
        this.specialty = specialty == null ? null : specialty.trim();
    }

    public String getIntroduction() {
        return introduction;
    }

    public void setIntroduction(String introduction) {
        this.introduction = introduction == null ? null : introduction.trim();
    }

    public Date getCreateTime() {
        return createTime;
    }

    public void setCreateTime(Date createTime) {
        this.createTime = createTime;
    }

    public String getAvatar() {
        return avatar;
    }

    public void setAvatar(String avatar) {
        this.avatar = avatar == null ? null : avatar.trim();
    }

    public String getDepartment() {
        return department;
    }

    public void setDepartment(String department) {
        this.department = department == null ? null : department.trim();
    }

    public String getLicenseNumber() {
        return licenseNumber;
    }

    public void setLicenseNumber(String licenseNumber) {
        this.licenseNumber = licenseNumber == null ? null : licenseNumber.trim();
    }

    public String getLicenseImageUrls() {
        return licenseImageUrls;
    }

    public void setLicenseImageUrls(String licenseImageUrls) {
        this.licenseImageUrls = licenseImageUrls == null ? null : licenseImageUrls.trim();
    }

    public String getVerificationStatus() {
        return verificationStatus;
    }

    public void setVerificationStatus(String verificationStatus) {
        this.verificationStatus = verificationStatus == null ? null : verificationStatus.trim();
    }

    public String getVerificationRemark() {
        return verificationRemark;
    }

    public void setVerificationRemark(String verificationRemark) {
        this.verificationRemark = verificationRemark == null ? null : verificationRemark.trim();
    }

    public Boolean getAccepting() {
        return accepting;
    }

    public void setAccepting(Boolean accepting) {
        this.accepting = accepting;
    }
}
