package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.DoctorSanction;
import org.example.springbootdemo.dao.DoctorSanctionDao;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * 医生处罚：创建/查询有效处罚/申诉撤销/永久封禁二人复核
 */
@Service
public class SanctionService {

    private final DoctorSanctionDao doctorSanctionDao;

    public SanctionService(DoctorSanctionDao doctorSanctionDao) {
        this.doctorSanctionDao = doctorSanctionDao;
    }

    @Transactional
    public DoctorSanction createSanction(Long eventId, Long decisionId, Long doctorId, String type, String scope, Date startsAt, Date endsAt, Long issuerId, String reason) {
        DoctorSanction s = new DoctorSanction();
        s.setEventId(eventId);
        s.setDecisionId(decisionId);
        s.setDoctorId(doctorId);
        s.setType(type);
        s.setScope(scope);
        s.setStatus(DoctorSanction.STATUS_ACTIVE);
        s.setStartsAt(startsAt == null ? new Date() : startsAt);
        s.setEndsAt(endsAt);
        s.setIssuerId(issuerId);
        s.setReason(reason);
        s.setCreatedAt(new Date());
        // 永久封禁需二人复核，未复核前先置 ACTIVE 之外的状态？MVP：直接 ACTIVE，approval 接口单独处理已有 sanction
        doctorSanctionDao.insertSelective(s);
        return s;
    }

    public List<DoctorSanction> getActiveSanctionByDoctor(Long doctorId) {
        return doctorSanctionDao.selectActiveByDoctor(doctorId, new Date());
    }

    public List<DoctorSanction> getAllSanctionsByDoctor(Long doctorId) {
        return doctorSanctionDao.selectAllByDoctor(doctorId);
    }

    /** 是否存在阻断接诊的有效处罚（暂停/永久封禁） */
    public boolean hasActiveBlockingSanction(Long doctorId) {
        List<DoctorSanction> active = getActiveSanctionByDoctor(doctorId);
        for (DoctorSanction s : active) {
            if (DoctorSanction.TYPE_SUSPEND_1D.equals(s.getType())
                    || DoctorSanction.TYPE_SUSPEND_7D.equals(s.getType())
                    || DoctorSanction.TYPE_SUSPEND_30D.equals(s.getType())
                    || DoctorSanction.TYPE_PERMANENT_BAN.equals(s.getType())) {
                return true;
            }
        }
        return false;
    }

    /** 申诉撤销时：把对应处罚置 REVOKED */
    @Transactional
    public void revokeByEventOrDecision(Long eventId, Long decisionId) {
        List<DoctorSanction> list = doctorSanctionDao.selectByEventId(eventId);
        for (DoctorSanction s : list) {
            if (DoctorSanction.STATUS_ACTIVE.equals(s.getStatus())) {
                DoctorSanction upd = new DoctorSanction();
                upd.setId(s.getId());
                upd.setStatus(DoctorSanction.STATUS_REVOKED);
                doctorSanctionDao.updateStatus(upd);
            }
        }
    }

    /** 永久封禁二人复核：approverId 必须 != issuerId */
    @Transactional
    public DoctorSanction approvePermanentBan(Long sanctionId, Long approverId, String reason) {
        DoctorSanction s = doctorSanctionDao.selectByPrimaryKey(sanctionId);
        if (s == null) {
            throw new IllegalArgumentException("sanction not found");
        }
        if (!DoctorSanction.TYPE_PERMANENT_BAN.equals(s.getType())) {
            throw new IllegalStateException("only permanent ban needs approval");
        }
        if (s.getIssuerId() != null && s.getIssuerId().equals(approverId)) {
            throw new IllegalStateException("approver must differ from issuer");
        }
        DoctorSanction upd = new DoctorSanction();
        upd.setId(sanctionId);
        upd.setStatus(DoctorSanction.STATUS_ACTIVE);
        upd.setApproverId(approverId);
        doctorSanctionDao.updateStatus(upd);
        return doctorSanctionDao.selectByPrimaryKey(sanctionId);
    }

    public List<DoctorSanction> listByEvent(Long eventId) {
        return doctorSanctionDao.selectByEventId(eventId);
    }

    /** 管理员查看医生全部处罚记录(含已过期/已撤销) */
    public List<DoctorSanction> listAllByDoctor(Long doctorId) {
        return doctorSanctionDao.selectAllByDoctor(doctorId);
    }
}
