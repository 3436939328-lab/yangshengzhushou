package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.Complaint;
import org.example.springbootdemo.bean.ComplaintAppeal;
import org.example.springbootdemo.bean.ComplaintDecision;
import org.example.springbootdemo.bean.ComplaintEvent;
import org.example.springbootdemo.bean.DoctorSanction;
import org.example.springbootdemo.dao.ComplaintAppealDao;
import org.example.springbootdemo.dao.ComplaintDao;
import org.example.springbootdemo.dao.ComplaintDecisionDao;
import org.example.springbootdemo.dao.ComplaintEventDao;
import org.example.springbootdemo.dao.DoctorSanctionDao;
import org.example.springbootdemo.bean.DoctorSanction;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 申诉状态机：PENDING→REVIEWING→MAINTAINED|REDUCED|REVOKED
 * 复核人 != 原判定人；只有一名管理员时保持待复核
 */
@Service
public class ComplaintAppealService {

    private final ComplaintAppealDao complaintAppealDao;
    private final ComplaintDecisionDao complaintDecisionDao;
    private final ComplaintDao complaintDao;
    private final ComplaintEventDao complaintEventDao;
    private final DoctorSanctionDao doctorSanctionDao;
    private final SanctionService sanctionService;
    private final NotificationService notificationService;
    private final AuditService auditService;

    public ComplaintAppealService(ComplaintAppealDao complaintAppealDao, ComplaintDecisionDao complaintDecisionDao,
                                   ComplaintDao complaintDao, ComplaintEventDao complaintEventDao,
                                   DoctorSanctionDao doctorSanctionDao,
                                   SanctionService sanctionService, NotificationService notificationService,
                                   AuditService auditService) {
        this.complaintAppealDao = complaintAppealDao;
        this.complaintDecisionDao = complaintDecisionDao;
        this.complaintDao = complaintDao;
        this.complaintEventDao = complaintEventDao;
        this.doctorSanctionDao = doctorSanctionDao;
        this.sanctionService = sanctionService;
        this.notificationService = notificationService;
        this.auditService = auditService;
    }

    public Map<String, Object> listForAdmin(String status, int page, int size) {
        if (page < 1) page = 1;
        if (size < 1 || size > 100) size = 20;
        long total = complaintAppealDao.countListForAdmin(status);
        List<ComplaintAppeal> items = complaintAppealDao.selectListForAdmin(status, (page - 1) * size, size);
        Map<String, Object> data = new HashMap<>();
        data.put("items", items);
        data.put("page", page);
        data.put("pageSize", size);
        data.put("total", total);
        return data;
    }

    public Map<String, Object> getDetail(Long appealId) {
        ComplaintAppeal appeal = complaintAppealDao.selectByPrimaryKey(appealId);
        if (appeal == null) return null;
        ComplaintDecision original = complaintDecisionDao.selectByPrimaryKey(appeal.getDecisionId());
        Complaint complaint = null;
        ComplaintEvent event = null;
        List<DoctorSanction> sanctions = List.of();
        if (original != null) {
            event = complaintEventDao.selectByPrimaryKey(original.getEventId());
            sanctions = sanctionService.listByEvent(original.getEventId());
            List<Complaint> cs = complaintDao.selectByEventId(original.getEventId());
            if (!cs.isEmpty()) complaint = cs.get(0);
        }
        Map<String, Object> data = new HashMap<>();
        data.put("appeal", appeal);
        data.put("originalDecision", original);
        data.put("event", event);
        data.put("complaint", complaint);
        data.put("sanctions", sanctions);
        return data;
    }

    /** 医生提交申诉：校验 7 日内 + 同决定一次 */
    @Transactional
    public ComplaintAppeal submit(Long decisionId, Long doctorId, String reason) {
        ComplaintDecision dec = complaintDecisionDao.selectByPrimaryKey(decisionId);
        if (dec == null) throw new IllegalArgumentException("decision not found");
        if (dec.getCreatedAt() == null || System.currentTimeMillis() - dec.getCreatedAt().getTime() > 7L * 24 * 60 * 60 * 1000) {
            throw new IllegalStateException("appeal out of 7-day window");
        }
        List<ComplaintAppeal> existing = complaintAppealDao.selectByDecisionId(decisionId);
        if (!existing.isEmpty()) {
            throw new IllegalStateException("appeal already submitted for this decision");
        }
        ComplaintAppeal a = new ComplaintAppeal();
        a.setDecisionId(decisionId);
        a.setDoctorId(doctorId);
        a.setStatus(ComplaintAppeal.STATUS_PENDING);
        a.setReason(reason);
        a.setCreatedAt(new Date());
        a.setVersion(1);
        complaintAppealDao.insertSelective(a);
        return a;
    }

    /** 管理员复核：MAINTAIN/REDUCE/REVOKE，reviewerId != 原 reviewerId */
    @Transactional
    public ComplaintAppeal review(Long appealId, String decision, String reason, Long reviewerId, Integer version) {
        ComplaintAppeal a = complaintAppealDao.selectByPrimaryKey(appealId);
        if (a == null) throw new IllegalArgumentException("appeal not found");
        if (!ComplaintAppeal.STATUS_PENDING.equals(a.getStatus()) && !ComplaintAppeal.STATUS_REVIEWING.equals(a.getStatus())) {
            throw new IllegalStateException("appeal status " + a.getStatus() + " cannot review");
        }
        String normalized = decision == null ? "" : decision.trim().toUpperCase();
        if (!"MAINTAIN".equals(normalized) && !"REDUCE".equals(normalized) && !"REVOKE".equals(normalized)) {
            throw new IllegalArgumentException("decision must be MAINTAIN/REDUCE/REVOKE");
        }
        ComplaintDecision original = complaintDecisionDao.selectByPrimaryKey(a.getDecisionId());
        Date now = new Date();
        ComplaintAppeal upd = new ComplaintAppeal();
        upd.setId(appealId);
        upd.setVersion(version == null ? a.getVersion() : version);
        if ("MAINTAIN".equals(normalized)) upd.setStatus(ComplaintAppeal.STATUS_MAINTAINED);
        if ("REDUCE".equals(normalized)) upd.setStatus(ComplaintAppeal.STATUS_REDUCED);
        if ("REVOKE".equals(normalized)) upd.setStatus(ComplaintAppeal.STATUS_REVOKED);
        upd.setReviewerId(reviewerId);
        upd.setResultReason(reason);
        upd.setReviewedAt(now);
        int rows = complaintAppealDao.updateStatus(upd);
        if (rows == 0) throw new IllegalStateException("version conflict, please retry");
        // REVOKE 时撤销对应处罚
        if ("REVOKE".equals(normalized) && original != null && original.getEventId() != null) {
            sanctionService.revokeByEventOrDecision(original.getEventId(), original.getId());
            // 事件 effective_decision 改为 REJECTED
            ComplaintEvent evUpd = new ComplaintEvent();
            evUpd.setId(original.getEventId());
            evUpd.setEffectiveDecision(Complaint.STATUS_REJECTED);
            evUpd.setDecisionAt(now);
            complaintEventDao.updateEffectiveDecision(evUpd);
        }
        // 通知医生
        notificationService.writeOutbox("appeal.result." + appealId, a.getDoctorId(),
                "APPEAL_RESULT", "申诉复核结果", "您的申诉 #" + appealId + " 复核结果：" + normalized);
        // 通知投诉用户申诉结果
        try {
            if (original != null && original.getEventId() != null) {
                List<Complaint> complaints = complaintDao.selectByEventId(original.getEventId());
                if (complaints != null && !complaints.isEmpty()) {
                    Complaint firstComplaint = complaints.get(0);
                    if (firstComplaint.getReporterId() != null) {
                        notificationService.writeOutbox("appeal.result.user." + appealId,
                                firstComplaint.getReporterId(),
                                "APPEAL_RESULT_USER", "申诉复核结果",
                                "您投诉的申诉 #" + appealId + " 复核结果：" + normalized);
                    }
                }
            }
        } catch (Exception e) {
            // 通知失败不影响主流程
        }
        auditService.appendAudit(reviewerId, "APPEAL_REVIEW", "appeal", appealId,
                "appeal " + normalized, reason, normalized, null);
        return complaintAppealDao.selectByPrimaryKey(appealId);
    }

    public List<ComplaintAppeal> myAppeals(Long doctorId) {
        // 简化：用 listForAdmin 然后过滤
        return complaintAppealDao.selectListForAdmin(null, 0, 1000).stream()
                .filter(a -> doctorId.equals(a.getDoctorId()))
                .toList();
    }

    /**
     * 医生查看自己的申诉列表（按医生ID）
     */
    public List<ComplaintAppeal> listByDoctorId(Long doctorId) {
        return myAppeals(doctorId);
    }

    /**
     * 医生通过处罚ID提交申诉
     */
    @Transactional
    public ComplaintAppeal submitAppeal(Long doctorId, Long sanctionId, String reason) {
        // 通过 sanctionId 找到对应的 decisionId
        DoctorSanction sanction = doctorSanctionDao.selectByPrimaryKey(sanctionId);
        if (sanction == null) {
            throw new IllegalArgumentException("sanction not found");
        }
        if (!doctorId.equals(sanction.getDoctorId())) {
            throw new IllegalStateException("sanction does not belong to this doctor");
        }
        if (sanction.getDecisionId() == null) {
            throw new IllegalStateException("sanction has no associated decision");
        }
        // 调用现有的 submit 方法
        return submit(sanction.getDecisionId(), doctorId, reason);
    }

    /**
     * 医生通过决策ID提交申诉（通用入口，投诉/处罚申诉都可用）
     */
    @Transactional
    public ComplaintAppeal submitByDecision(Long decisionId, Long doctorId, String reason) {
        ComplaintDecision dec = complaintDecisionDao.selectByPrimaryKey(decisionId);
        if (dec == null) {
            throw new IllegalArgumentException("decision not found");
        }
        // 校验医生身份：该决策对应的事件的医生必须是当前医生
        if (dec.getEventId() != null) {
            ComplaintEvent event = complaintEventDao.selectByPrimaryKey(dec.getEventId());
            if (event != null && !doctorId.equals(event.getDoctorId())) {
                throw new IllegalStateException("decision does not belong to this doctor");
            }
        }
        ComplaintAppeal appeal = submit(decisionId, doctorId, reason);
        return appeal;
    }
}
