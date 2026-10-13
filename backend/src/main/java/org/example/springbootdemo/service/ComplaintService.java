package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.Complaint;
import org.example.springbootdemo.bean.ComplaintAppeal;
import org.example.springbootdemo.bean.ComplaintDecision;
import org.example.springbootdemo.bean.ComplaintEvent;
import org.example.springbootdemo.bean.ComplaintEvidence;
import org.example.springbootdemo.bean.DoctorSanction;
import org.example.springbootdemo.dao.ComplaintAppealDao;
import org.example.springbootdemo.dao.ComplaintDao;
import org.example.springbootdemo.dao.ComplaintDecisionDao;
import org.example.springbootdemo.dao.ComplaintEventDao;
import org.example.springbootdemo.dao.ComplaintEvidenceDao;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 投诉状态机：SUBMITTED→REVIEWING↔NEED_INFO→UPHELD|REJECTED|MERGED
 */
@Service
public class ComplaintService {

    private final ComplaintDao complaintDao;
    private final ComplaintEventDao complaintEventDao;
    private final ComplaintDecisionDao complaintDecisionDao;
    private final ComplaintEvidenceDao complaintEvidenceDao;
    private final ComplaintAppealDao complaintAppealDao;
    private final SanctionService sanctionService;
    private final NotificationService notificationService;
    private final AuditService auditService;

    public ComplaintService(ComplaintDao complaintDao, ComplaintEventDao complaintEventDao,
                            ComplaintDecisionDao complaintDecisionDao, ComplaintEvidenceDao complaintEvidenceDao,
                            ComplaintAppealDao complaintAppealDao,
                            SanctionService sanctionService, NotificationService notificationService,
                            AuditService auditService) {
        this.complaintDao = complaintDao;
        this.complaintEventDao = complaintEventDao;
        this.complaintDecisionDao = complaintDecisionDao;
        this.complaintEvidenceDao = complaintEvidenceDao;
        this.complaintAppealDao = complaintAppealDao;
        this.sanctionService = sanctionService;
        this.notificationService = notificationService;
        this.auditService = auditService;
    }

    public Map<String, Object> listForAdmin(String status, Long doctorId, int page, int size) {
        if (page < 1) page = 1;
        if (size < 1 || size > 100) size = 20;
        long total = complaintDao.countListForAdmin(status, doctorId);
        List<Complaint> items = complaintDao.selectListForAdmin(status, doctorId, (page - 1) * size, size);
        Map<String, Object> data = new HashMap<>();
        data.put("items", items);
        data.put("page", page);
        data.put("pageSize", size);
        data.put("total", total);
        return data;
    }

    public Map<String, Object> getDetail(Long complaintId) {
        Complaint c = complaintDao.selectByPrimaryKey(complaintId);
        if (c == null) return null;
        ComplaintEvent event = null;
        List<ComplaintEvidence> evidence = List.of();
        List<ComplaintDecision> decisions = List.of();
        List<DoctorSanction> sanctions = List.of();
        if (c.getEventId() != null) {
            event = complaintEventDao.selectByPrimaryKey(c.getEventId());
            evidence = complaintEvidenceDao.selectByComplaintId(complaintId);
            decisions = complaintDecisionDao.selectByEventId(c.getEventId());
            sanctions = sanctionService.listByEvent(c.getEventId());
        }
        Map<String, Object> data = new HashMap<>();
        data.put("complaint", c);
        data.put("event", event);
        data.put("evidence", evidence);
        data.put("decisions", decisions);
        data.put("sanctions", sanctions);
        return data;
    }

    @Transactional
    /**
     * 统一操作入口：CLAIM / NEED_INFO
     */
    public Complaint action(Long complaintId, String action, String reason, Long targetEventId,
                            Long operatorId, Integer version) {
        String normalized = action == null ? "" : action.trim().toUpperCase();
        switch (normalized) {
            case "CLAIM":
                return claim(complaintId, operatorId);
            case "NEED_INFO":
                return needInfo(complaintId, operatorId, reason);
            default:
                throw new IllegalArgumentException("unknown action: " + action);
        }
    }

    public Complaint claim(Long complaintId, Long assigneeId) {
        Complaint c = complaintDao.selectByPrimaryKey(complaintId);
        if (c == null) throw new IllegalArgumentException("complaint not found");
        if (!Complaint.STATUS_SUBMITTED.equals(c.getStatus())) {
            throw new IllegalStateException("complaint status " + c.getStatus() + " cannot claim");
        }
        Complaint updating = new Complaint();
        updating.setId(c.getId());
        updating.setVersion(c.getVersion());
        updating.setStatus(Complaint.STATUS_REVIEWING);
        updating.setAssigneeId(assigneeId);
        updating.setUpdatedAt(new Date());
        int rows = complaintDao.updateStatus(updating);
        if (rows == 0) throw new IllegalStateException("version conflict, please retry");
        auditService.appendAudit(assigneeId, "COMPLAINT_CLAIM", "complaint", complaintId,
                "claim complaint #" + complaintId, null, "OK", null);
        return complaintDao.selectByPrimaryKey(complaintId);
    }

    @Transactional
    public Complaint needInfo(Long complaintId, Long reviewerId, String reason) {
        Complaint c = complaintDao.selectByPrimaryKey(complaintId);
        if (c == null) throw new IllegalArgumentException("complaint not found");
        if (!Complaint.STATUS_REVIEWING.equals(c.getStatus())) {
            throw new IllegalStateException("complaint status " + c.getStatus() + " cannot need info");
        }
        Complaint updating = new Complaint();
        updating.setId(c.getId());
        updating.setVersion(c.getVersion());
        updating.setStatus(Complaint.STATUS_NEED_INFO);
        updating.setUpdatedAt(new Date());
        int rows = complaintDao.updateStatus(updating);
        if (rows == 0) throw new IllegalStateException("version conflict, please retry");
        auditService.appendAudit(reviewerId, "COMPLAINT_NEED_INFO", "complaint", complaintId,
                "need info for complaint #" + complaintId, reason, "OK", null);
        return complaintDao.selectByPrimaryKey(complaintId);
    }

    @Transactional
    public Complaint decision(Long complaintId, String result, String severity, String reason,
                              Map<String, Object> sanction, Integer version, Long reviewerId) {
        Complaint c = complaintDao.selectByPrimaryKey(complaintId);
        if (c == null) throw new IllegalArgumentException("complaint not found");
        if (!Complaint.STATUS_REVIEWING.equals(c.getStatus()) && !Complaint.STATUS_NEED_INFO.equals(c.getStatus())) {
            throw new IllegalStateException("complaint status " + c.getStatus() + " cannot decide");
        }
        String normalized = result == null ? "" : result.trim().toUpperCase();
        if (!Complaint.STATUS_UPHELD.equals(normalized) && !Complaint.STATUS_REJECTED.equals(normalized)) {
            throw new IllegalArgumentException("result must be UPHELD or REJECTED");
        }
        Date now = new Date();
        // 1. 更新投诉状态（乐观锁）
        Complaint updating = new Complaint();
        updating.setId(c.getId());
        updating.setVersion(version == null ? c.getVersion() : version);
        updating.setStatus(normalized);
        updating.setUpdatedAt(now);
        int rows = complaintDao.updateStatus(updating);
        if (rows == 0) throw new IllegalStateException("version conflict, please retry");
        // 2. 写判定记录（追加）
        ComplaintDecision dec = new ComplaintDecision();
        dec.setEventId(c.getEventId());
        dec.setReviewerId(reviewerId);
        dec.setResult(normalized);
        dec.setSeverity(severity);
        dec.setReason(reason);
        dec.setCreatedAt(now);
        complaintDecisionDao.insertSelective(dec);
        // 3. 更新事件 effective_decision
        if (c.getEventId() != null) {
            ComplaintEvent evUpd = new ComplaintEvent();
            evUpd.setId(c.getEventId());
            evUpd.setEffectiveDecision(normalized);
            evUpd.setDecisionAt(now);
            complaintEventDao.updateEffectiveDecision(evUpd);
        }
        // 4. 成立且需处罚 → 创建 doctor_sanction
        if (Complaint.STATUS_UPHELD.equals(normalized) && sanction != null && c.getEventId() != null) {
            ComplaintEvent ev = complaintEventDao.selectByPrimaryKey(c.getEventId());
            if (ev != null && ev.getDoctorId() != null) {
                String type = text(sanction.get("type"));
                String scope = text(sanction.get("scope"));
                if (type.length() > 0) {
                    String endsAtStr = text(sanction.get("endsAt"));
                    Date endsAt = null;
                    if (endsAtStr.length() > 0) {
                        try {
                            java.time.OffsetDateTime odt = java.time.OffsetDateTime.parse(endsAtStr, java.time.format.DateTimeFormatter.ISO_OFFSET_DATE_TIME);
                            endsAt = Date.from(odt.toInstant());
                        } catch (Exception ignored) {
                            try { endsAt = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(endsAtStr); }
                            catch (Exception ignored2) {}
                        }
                    }
                    sanctionService.createSanction(c.getEventId(), dec.getId(), ev.getDoctorId(), type,
                            scope.length() > 0 ? scope : DoctorSanction.SCOPE_ACCEPTING,
                            now, endsAt, reviewerId, reason);
                    // 通知医生被处罚
                    try {
                        notificationService.writeOutbox("complaint.decision." + dec.getId(), ev.getDoctorId(),
                                "SANCTION", "处罚通知", "您因投诉 #" + complaintId + " 被处罚：" + type);
                    } catch (Exception e) {
                        // 通知失败不影响主流程
                    }
                }
            }
        }
        // 5. 通知投诉人结果
        try {
            notificationService.writeOutbox("complaint.result." + c.getId(), c.getReporterId(),
                    "COMPLAINT_RESULT", "投诉处理结果", "您的投诉 #" + complaintId + " 处理结果：" + normalized);
        } catch (Exception e) {
            // 通知失败不影响主流程
        }
        // 6. 审计
        auditService.appendAudit(reviewerId, "COMPLAINT_DECISION", "complaint", complaintId,
                "decision " + normalized + " severity=" + severity, reason, normalized, null);
        return complaintDao.selectByPrimaryKey(complaintId);
    }

    /** 用户补充证据/说明 */
    @Transactional
    public Complaint supplement(Long complaintId, Long uploaderId, String description, String summary) {
        Complaint c = complaintDao.selectByPrimaryKey(complaintId);
        if (c == null) throw new IllegalArgumentException("complaint not found");
        if (!Complaint.STATUS_NEED_INFO.equals(c.getStatus()) && !Complaint.STATUS_SUBMITTED.equals(c.getStatus())) {
            throw new IllegalStateException("complaint status " + c.getStatus() + " cannot supplement");
        }
        // 状态自动回 REVIEWING
        Complaint updating = new Complaint();
        updating.setId(c.getId());
        updating.setVersion(c.getVersion());
        updating.setStatus(Complaint.STATUS_REVIEWING);
        updating.setUpdatedAt(new Date());
        int rows = complaintDao.updateStatus(updating);
        if (rows == 0) throw new IllegalStateException("version conflict, please retry");
        return complaintDao.selectByPrimaryKey(complaintId);
    }

    public Map<String, Object> myComplaints(Long reporterId) {
        List<Complaint> items = complaintDao.selectByReporterId(reporterId);
        // 补充事件类别和处理结果说明
        List<Map<String, Object>> enriched = new ArrayList<>();
        for (Complaint c : items) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", c.getId());
            map.put("eventId", c.getEventId());
            map.put("reporterId", c.getReporterId());
            map.put("description", c.getDescription());
            map.put("status", c.getStatus());
            map.put("createdAt", c.getCreatedAt());
            map.put("updatedAt", c.getUpdatedAt());
            // 类别
            if (c.getEventId() != null) {
                ComplaintEvent ev = complaintEventDao.selectByPrimaryKey(c.getEventId());
                if (ev != null) {
                    map.put("category", ev.getCategory());
                }
                // 最新处理决定
                List<ComplaintDecision> decisions = complaintDecisionDao.selectByEventId(c.getEventId());
                if (decisions != null && decisions.size() > 0) {
                    ComplaintDecision latest = decisions.get(0);
                    map.put("decisionId", latest.getId());
                    map.put("decisionResult", latest.getResult());
                    map.put("decisionReason", latest.getReason());
                    map.put("decisionAt", latest.getCreatedAt());
                    // 申诉信息
                    List<ComplaintAppeal> appeals = complaintAppealDao.selectByDecisionId(latest.getId());
                    if (appeals != null && !appeals.isEmpty()) {
                        ComplaintAppeal appeal = appeals.get(0);
                        Map<String, Object> appealInfo = new HashMap<>();
                        appealInfo.put("id", appeal.getId());
                        appealInfo.put("status", appeal.getStatus());
                        appealInfo.put("reason", appeal.getReason());
                        appealInfo.put("resultReason", appeal.getResultReason());
                        appealInfo.put("createdAt", appeal.getCreatedAt());
                        appealInfo.put("reviewedAt", appeal.getReviewedAt());
                        map.put("appeal", appealInfo);
                    }
                }
            }
            enriched.add(map);
        }
        Map<String, Object> data = new HashMap<>();
        data.put("items", enriched);
        return data;
    }

    /**
     * 用户提交投诉：创建投诉事件 + 投诉记录
     */
    @Transactional
    public Complaint submitUserComplaint(Long reporterId, Long doctorId, Long consultationId,
                                         String category, String description) {
        Date now = new Date();
        // 1. 检查是否已存在同咨询的投诉事件
        ComplaintEvent existingEvent = complaintEventDao.selectByConsultationIdAndDoctor(consultationId, doctorId);
        Long eventId;
        if (existingEvent != null) {
            eventId = existingEvent.getId();
        } else {
            // 2. 创建新的投诉事件
            ComplaintEvent event = new ComplaintEvent();
            event.setDoctorId(doctorId);
            event.setConsultationId(consultationId);
            event.setCategory(category);
            event.setCreatedAt(now);
            complaintEventDao.insertSelective(event);
            eventId = event.getId();
        }
        // 3. 创建投诉记录
        Complaint complaint = new Complaint();
        complaint.setEventId(eventId);
        complaint.setReporterId(reporterId);
        complaint.setDescription(description);
        complaint.setStatus(Complaint.STATUS_SUBMITTED);
        complaint.setCreatedAt(now);
        complaint.setUpdatedAt(now);
        complaint.setVersion(1);
        complaintDao.insertSelective(complaint);

        // 4. 通知医生被投诉
        try {
            notificationService.writeOutbox("complaint.new." + complaint.getId(), doctorId,
                    "NEW_COMPLAINT", "新投诉通知", "您有一条新的投诉 #" + complaint.getId() + " 待处理");
        } catch (Exception e) {
            // 通知失败不影响主流程
        }

        return complaint;
    }

    /**
     * 医生查看针对自己的投诉列表（带类别和处理结果）
     */
    public List<Map<String, Object>> listComplaintsForDoctor(Long doctorId) {
        List<Complaint> items = complaintDao.selectByDoctorId(doctorId);
        List<Map<String, Object>> result = new ArrayList<>();
        for (Complaint c : items) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", c.getId());
            map.put("eventId", c.getEventId());
            map.put("reporterId", c.getReporterId());
            map.put("description", c.getDescription());
            map.put("status", c.getStatus());
            map.put("createdAt", c.getCreatedAt());
            map.put("updatedAt", c.getUpdatedAt());
            if (c.getEventId() != null) {
                ComplaintEvent ev = complaintEventDao.selectByPrimaryKey(c.getEventId());
                if (ev != null) {
                    map.put("category", ev.getCategory());
                    map.put("consultationId", ev.getConsultationId());
                }
                // 最新处理决定
                List<ComplaintDecision> decisions = complaintDecisionDao.selectByEventId(c.getEventId());
                if (decisions != null && decisions.size() > 0) {
                    ComplaintDecision latest = decisions.get(0);
                    map.put("decisionId", latest.getId());
                    map.put("decisionResult", latest.getResult());
                    map.put("decisionReason", latest.getReason());
                    map.put("decisionAt", latest.getCreatedAt());
                    // 申诉信息
                    List<ComplaintAppeal> appeals = complaintAppealDao.selectByDecisionId(latest.getId());
                    if (appeals != null && !appeals.isEmpty()) {
                        ComplaintAppeal appeal = appeals.get(0);
                        Map<String, Object> appealInfo = new HashMap<>();
                        appealInfo.put("id", appeal.getId());
                        appealInfo.put("status", appeal.getStatus());
                        appealInfo.put("reason", appeal.getReason());
                        appealInfo.put("resultReason", appeal.getResultReason());
                        appealInfo.put("createdAt", appeal.getCreatedAt());
                        appealInfo.put("reviewedAt", appeal.getReviewedAt());
                        map.put("appeal", appealInfo);
                    }
                }
            }
            result.add(map);
        }
        return result;
    }

    private static String text(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }
}
