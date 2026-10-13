package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.DoctorProfile;
import org.example.springbootdemo.bean.DoctorReview;
import org.example.springbootdemo.service.DoctorReviewService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class DoctorReviewController {

    private final DoctorReviewService doctorReviewService;
    private final PermissionService permissionService;

    public DoctorReviewController(DoctorReviewService doctorReviewService, PermissionService permissionService) {
        this.doctorReviewService = doctorReviewService;
        this.permissionService = permissionService;
    }

    // ==================== 医生侧 ====================

    /** 创建/获取草稿 */
    @PostMapping("/doctor-registration/drafts")
    public ResponseEntity<Map<String, Object>> createDraft(HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }
        if (!permissionService.canManageDoctorProfile(request, userId)) {
            return forbidden();
        }
        DoctorReview draft = doctorReviewService.ensureDraft(userId);
        return ok(response(true, "draft ready", draft));
    }

    /** 更新草稿资料 */
    @PutMapping("/doctor-registration/drafts/{id}")
    public ResponseEntity<Map<String, Object>> updateDraft(@PathVariable("id") Long reviewId,
                                                           @RequestBody DoctorProfile profile,
                                                           HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }
        if (!permissionService.canManageDoctorProfile(request, userId)) {
            return forbidden();
        }
        try {
            int rows = doctorReviewService.updateDraftProfile(userId, profile);
            return ok(response(rows > 0, rows > 0 ? "draft saved" : "save failed"));
        } catch (IllegalStateException ex) {
            return conflict(ex.getMessage());
        }
    }

    /** 提交审核 */
    @PostMapping("/doctor-registration/drafts/{id}/submit")
    public ResponseEntity<Map<String, Object>> submitForReview(@PathVariable("id") Long reviewId,
                                                              HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }
        if (!permissionService.canManageDoctorProfile(request, userId)) {
            return forbidden();
        }
        try {
            DoctorReview updated = doctorReviewService.submitForReview(userId);
            return ok(response(true, "submitted for review", updated));
        } catch (IllegalStateException ex) {
            return conflict(ex.getMessage());
        }
    }

    /** 本人审核状态 + 资料 */
    @GetMapping("/doctor/qualification")
    public ResponseEntity<Map<String, Object>> getMyQualification(HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }
        return ok(response(true, "ok", doctorReviewService.getMyQualification(userId)));
    }

    /** 重提审核（REJECTED/NEED_INFO → PENDING） */
    @PostMapping("/doctor/qualification/resubmissions")
    public ResponseEntity<Map<String, Object>> resubmit(HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }
        try {
            DoctorReview updated = doctorReviewService.submitForReview(userId);
            return ok(response(true, "resubmitted", updated));
        } catch (IllegalStateException ex) {
            return conflict(ex.getMessage());
        }
    }

    /** 接诊开关（仅 APPROVED 生效） */
    @PutMapping("/doctor/availability")
    public ResponseEntity<Map<String, Object>> updateAvailability(@RequestBody Map<String, Object> body,
                                                                 HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }
        if (!permissionService.canManageDoctorProfile(request, userId)) {
            return forbidden();
        }
        boolean accepting = Boolean.TRUE.equals(body.get("accepting"));
        try {
            int rows = doctorReviewService.updateAccepting(userId, accepting);
            return ok(response(rows > 0, rows > 0 ? "availability updated" : "update failed"));
        } catch (IllegalStateException ex) {
            return conflict(ex.getMessage());
        }
    }

    // ==================== 管理员侧 ====================

    @GetMapping("/admin/doctor-reviews")
    public ResponseEntity<Map<String, Object>> listReviews(@RequestParam(value = "status", required = false) String status,
                                                           @RequestParam(value = "page", defaultValue = "1") int page,
                                                           @RequestParam(value = "pageSize", defaultValue = "20") int pageSize,
                                                           HttpServletRequest request) {
        if (!permissionService.canReviewDoctor(request)) {
            return forbidden();
        }
        return ok(response(true, "ok", doctorReviewService.listReviewsForAdmin(status, page, pageSize)));
    }

    @GetMapping("/admin/doctor-reviews/{id}")
    public ResponseEntity<Map<String, Object>> getReview(@PathVariable("id") Long reviewId,
                                                        HttpServletRequest request) {
        if (!permissionService.canReviewDoctor(request)) {
            return forbidden();
        }
        Map<String, Object> detail = doctorReviewService.getReviewDetail(reviewId);
        if (detail == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response(false, "review not found"));
        }
        return ok(response(true, "ok", detail));
    }

    @PostMapping("/admin/doctor-reviews/{id}/decision")
    public ResponseEntity<Map<String, Object>> adminDecision(@PathVariable("id") Long reviewId,
                                                            @RequestBody Map<String, Object> body,
                                                            HttpServletRequest request) {
        if (!permissionService.canReviewDoctor(request)) {
            return forbidden();
        }
        Long reviewerId = permissionService.currentUserId(request);
        String decision = text(body.get("result"));
        String reason = text(body.get("reason"));
        Integer version = integer(body.get("version"));
        if (version == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(response(false, "version is required for optimistic lock"));
        }
        try {
            DoctorReview updated = doctorReviewService.adminDecision(reviewId, decision, reason, reviewerId);
            return ok(response(true, "decision saved", updated));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, ex.getMessage()));
        } catch (IllegalStateException ex) {
            return conflict(ex.getMessage());
        }
    }

    // ==================== 工具与异常 ====================

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalState(IllegalStateException ex) {
        return conflict(ex.getMessage());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, ex.getMessage()));
    }

    private Map<String, Object> response(boolean success, String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", success);
        response.put("message", message);
        return response;
    }

    private Map<String, Object> response(boolean success, String message, Object data) {
        Map<String, Object> response = response(success, message);
        response.put("data", data);
        return response;
    }

    private ResponseEntity<Map<String, Object>> ok(Map<String, Object> body) {
        return ResponseEntity.ok(body);
    }

    private ResponseEntity<Map<String, Object>> unauthorized() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response(false, "missing or invalid token"));
    }

    private ResponseEntity<Map<String, Object>> forbidden() {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response(false, "forbidden"));
    }

    private ResponseEntity<Map<String, Object>> conflict(String message) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(response(false, message));
    }

    private String text(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }

    private Integer integer(Object value) {
        if (value == null) return null;
        if (value instanceof Integer) return (Integer) value;
        try {
            return Integer.parseInt(String.valueOf(value));
        } catch (NumberFormatException ex) {
            return null;
        }
    }
}
