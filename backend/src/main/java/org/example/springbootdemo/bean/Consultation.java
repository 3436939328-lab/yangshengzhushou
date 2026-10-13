package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class Consultation implements Serializable {

    private Long id;
    private Long userId;
    private Long doctorId;
    private String title;
    private String symptom;
    private String description;
    private Byte status;
    private Date createTime;

    /**
     * 用户分享给医生的个人信息（可自定义）
     */
    private String sharedName;
    private Integer sharedAge;
    private String sharedGender;
    private String sharedPhone;

    /**
     * 用户健康快照（JSON 字符串，包含血压、血糖、心率、睡眠等指标摘要）
     */
    private String healthSnapshot;

    /**
     * 用户分享的舌象照片URL（多张用逗号分隔）
     */
    private String tongueImageUrls;

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

    public Long getDoctorId() {
        return doctorId;
    }

    public void setDoctorId(Long doctorId) {
        this.doctorId = doctorId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title == null ? null : title.trim();
    }

    public String getSymptom() {
        return symptom;
    }

    public void setSymptom(String symptom) {
        this.symptom = symptom == null ? null : symptom.trim();
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description == null ? null : description.trim();
    }

    public Byte getStatus() {
        return status;
    }

    public void setStatus(Byte status) {
        this.status = status;
    }

    public Date getCreateTime() {
        return createTime;
    }

    public void setCreateTime(Date createTime) {
        this.createTime = createTime;
    }

    public String getSharedName() {
        return sharedName;
    }

    public void setSharedName(String sharedName) {
        this.sharedName = sharedName == null ? null : sharedName.trim();
    }

    public Integer getSharedAge() {
        return sharedAge;
    }

    public void setSharedAge(Integer sharedAge) {
        this.sharedAge = sharedAge;
    }

    public String getSharedGender() {
        return sharedGender;
    }

    public void setSharedGender(String sharedGender) {
        this.sharedGender = sharedGender == null ? null : sharedGender.trim();
    }

    public String getSharedPhone() {
        return sharedPhone;
    }

    public void setSharedPhone(String sharedPhone) {
        this.sharedPhone = sharedPhone == null ? null : sharedPhone.trim();
    }

    public String getHealthSnapshot() {
        return healthSnapshot;
    }

    public void setHealthSnapshot(String healthSnapshot) {
        this.healthSnapshot = healthSnapshot == null ? null : healthSnapshot.trim();
    }

    public String getTongueImageUrls() {
        return tongueImageUrls;
    }

    public void setTongueImageUrls(String tongueImageUrls) {
        this.tongueImageUrls = tongueImageUrls == null ? null : tongueImageUrls.trim();
    }
}
