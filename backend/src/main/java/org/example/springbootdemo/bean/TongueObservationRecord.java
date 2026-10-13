package org.example.springbootdemo.bean;

import java.io.Serializable;
import java.util.Date;

public class TongueObservationRecord implements Serializable {

    private Long id;
    private Long userId;
    private String color;
    private String coating;
    private String dryness;
    private String note;
    private String recordedAt;
    private Date createTime;

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

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color == null ? null : color.trim();
    }

    public String getCoating() {
        return coating;
    }

    public void setCoating(String coating) {
        this.coating = coating == null ? null : coating.trim();
    }

    public String getDryness() {
        return dryness;
    }

    public void setDryness(String dryness) {
        this.dryness = dryness == null ? null : dryness.trim();
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note == null ? null : note.trim();
    }

    public String getRecordedAt() {
        return recordedAt;
    }

    public void setRecordedAt(String recordedAt) {
        this.recordedAt = recordedAt == null ? null : recordedAt.trim();
    }

    public Date getCreateTime() {
        return createTime;
    }

    public void setCreateTime(Date createTime) {
        this.createTime = createTime;
    }
}
