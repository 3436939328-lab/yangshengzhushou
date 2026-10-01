package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.DoctorProfile;
import org.example.springbootdemo.bean.DoctorReview;
import org.example.springbootdemo.dao.DoctorProfileDao;
import org.example.springbootdemo.dao.DoctorReviewDao;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 医生资质审核业务：草稿 / 提交审核 / 管理员决策 / 接诊开关
 */
@Service
public class DoctorReviewService {

    private final DoctorReviewDao doctorReviewDao;
    private final DoctorProfileDao doctorProfileDao;
    private final DoctorProfileService doctorProfileService;

    public DoctorReviewService(DoctorReviewDao doctorReviewDao,
                               DoctorProfileDao doctorProfileDao,
                               DoctorProfileService doctorProfileService) {
        this.doctorReviewDao = doctorReviewDao;
        this.doctorProfileDao = doctorProfileDao;
        this.doctorProfileService = doctorProfileService;
    }

    /** 本人获取当前审核状态 + 资料 */
    public Map<String, Object> getMyQualification(Long userId) {
        Map<String, Object> data = new HashMap<>();
        DoctorProfile profile = doctorProfileService.getDoctorProfileByUserId(userId);
        DoctorReview latest = doctorReviewDao.selectLatestByDoctorUserId(userId);
        data.put("profile", profile);
        data.put("review", latest);
        return data;
    }

    /** 创建或复用现有草稿 */
    @Transactional
    public DoctorReview ensureDraft(Long userId) {
        DoctorReview latest = doctorReviewDao.selectLatestByDoctorUserId(userId);
        if (latest != null && DoctorReview.STATUS_DRAFT.equals(latest.getStatus())) {
            return latest;
        }
        DoctorReview draft = new DoctorReview();
        draft.setDoctorUserId(userId);
        draft.setStatus(DoctorReview.STATUS_DRAFT);
        draft.setVersion(latest == null ? 1 : latest.getVersion() + 1);
        draft.setCreatedAt(new Date());
        doctorReviewDao.insertSelective(draft);
        return draft;
    }

    /** 更新草稿资料（不进入 PENDING） */
    @Transactional
    public int updateDraftProfile(Long userId, DoctorProfile profile) {
        DoctorReview latest = doctorReviewDao.selectLatestByDoctorUserId(userId);
        if (latest == null || !DoctorReview.STATUS_DRAFT.equals(latest.getStatus())) {
            throw new IllegalStateException("no active draft for user " + userId);
        }
        profile.setUserId(userId);
        profile.setVerificationStatus(DoctorReview.STATUS_DRAFT);
        profile.setVerificationRemark(null);
        return doctorProfileService.saveDoctorProfile(profile);
    }

    /** 提交审核：DRAFT 或 REJECTED/NEED_INFO → PENDING */
    @Transactional
    public DoctorReview submitForReview(Long userId) {
        DoctorReview latest = doctorReviewDao.selectLatestByDoctorUserId(userId);
        if (latest == null) {
            throw new IllegalStateException("no draft to submit");
        }
        String status = latest.getStatus();
        if (!DoctorReview.STATUS_DRAFT.equals(status)
                && !DoctorReview.STATUS_REJECTED.equals(status)
                && !DoctorReview.STATUS_NEED_INFO.equals(status)) {
            throw new IllegalStateException("current status " + status + " cannot submit");
        }
        // 状态机校验通过，更新 review 与 profile
        DoctorReview updating = new DoctorReview();
        updating.setId(latest.getId());
        updating.setVersion(latest.getVersion());
        updating.setStatus(DoctorReview.STATUS_PENDING);
        updating.setSubmittedAt(new Date());
        int rows = doctorReviewDao.updateStatus(updating);
        if (rows == 0) {
            throw new IllegalStateException("version conflict, please retry");
        }

        DoctorProfile profile = doctorProfileDao.selectByUserId(userId);
        if (profile != null) {
            profile.setVerificationStatus(DoctorReview.STATUS_PENDING);
            profile.setVerificationRemark(null);
            doctorProfileDao.updateByPrimaryKeySelective(profile);
        }
        return doctorReviewDao.selectByPrimaryKey(latest.getId());
    }

    /** 管理员审核队列 */
    public Map<String, Object> listReviewsForAdmin(String status, int page, int size) {
        if (page < 1) page = 1;
        if (size < 1 || size > 100) size = 20;
        long total = doctorReviewDao.countListForAdmin(status);
        List<DoctorReview> items = doctorReviewDao.selectListForAdmin(status, (page - 1) * size, size);
        Map<String, Object> data = new HashMap<>();
        data.put("items", items);
        data.put("page", page);
        data.put("pageSize", size);
        data.put("total", total);
        return data;
    }

    /** 审核详情含 profile 快照 */
    public Map<String, Object> getReviewDetail(Long reviewId) {
        DoctorReview review = doctorReviewDao.selectByPrimaryKey(reviewId);
        if (review == null) {
            return null;
        }
        DoctorProfile profile = doctorProfileDao.selectByUserId(review.getDoctorUserId());
        List<DoctorReview> history = doctorReviewDao.selectByDoctorUserIdOrderByVersionDesc(review.getDoctorUserId());
        Map<String, Object> data = new HashMap<>();
        data.put("review", review);
        data.put("profile", profile);
        data.put("history", history);
        return data;
    }

    /** 管理员决策：APPROVED / REJECTED / NEED_INFO */
    @Transactional
    public DoctorReview adminDecision(Long reviewId, String decision, String reason, Long reviewerId) {
        DoctorReview review = doctorReviewDao.selectByPrimaryKey(reviewId);
        if (review == null) {
            throw new IllegalArgumentException("review not found");
        }
        if (!DoctorReview.STATUS_PENDING.equals(review.getStatus())
                && !DoctorReview.STATUS_NEED_INFO.equals(review.getStatus())) {
            throw new IllegalStateException("review status " + review.getStatus() + " cannot decide");
        }
        String normalized = decision == null ? "" : decision.trim().toUpperCase();
        if (!"APPROVED".equals(normalized) && !"REJECTED".equals(normalized) && !"NEED_INFO".equals(normalized)) {
            throw new IllegalArgumentException("decision must be APPROVED/REJECTED/NEED_INFO");
        }

        DoctorReview updating = new DoctorReview();
        updating.setId(review.getId());
        updating.setVersion(review.getVersion());
        updating.setStatus(normalized);
        updating.setReason(reason);
        updating.setReviewerId(reviewerId);
        updating.setReviewedAt(new Date());
        int rows = doctorReviewDao.updateStatus(updating);
        if (rows == 0) {
            throw new IllegalStateException("version conflict, please retry");
        }

        // 同步 doctor_profile.verification_status 与 remark
        DoctorProfile profile = doctorProfileDao.selectByUserId(review.getDoctorUserId());
        if (profile != null) {
            profile.setVerificationStatus(normalized);
            profile.setVerificationRemark(reason);
            if ("APPROVED".equals(normalized)) {
                // 通过后保留原有 accepting 状态，由医生决定是否开启
            } else {
                profile.setAccepting(false);
            }
            doctorProfileDao.updateByPrimaryKeySelective(profile);
        }
        return doctorReviewDao.selectByPrimaryKey(reviewId);
    }

    /** 接诊开关：仅 APPROVED 时生效 */
    @Transactional
    public int updateAccepting(Long userId, boolean accepting) {
        DoctorProfile profile = doctorProfileService.getDoctorProfileByUserId(userId);
        if (profile == null) {
            throw new IllegalStateException("doctor profile not found");
        }
        if (!DoctorReview.STATUS_APPROVED.equals(profile.getVerificationStatus())) {
            throw new IllegalStateException("only approved doctor can toggle accepting");
        }
        profile.setAccepting(accepting);
        return doctorProfileDao.updateByPrimaryKeySelective(profile);
    }
}
