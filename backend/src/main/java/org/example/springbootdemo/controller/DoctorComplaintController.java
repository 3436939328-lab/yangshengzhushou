package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.DoctorSanction;
import org.example.springbootdemo.bean.ComplaintAppeal;
import org.example.springbootdemo.bean.DoctorProfile;
import org.example.springbootdemo.service.ComplaintService;
import org.example.springbootdemo.service.SanctionService;
import org.example.springbootdemo.service.ComplaintAppealService;
import org.example.springbootdemo.service.DoctorProfileService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
@RequestMapping("/api/doctor")
public class DoctorComplaintController {

    private final ComplaintService complaintService;
    private final SanctionService sanctionService;
    private final ComplaintAppealService complaintAppealService;
    private final PermissionService permissionService;
    private final DoctorProfileService doctorProfileService;

    public DoctorComplaintController(ComplaintService complaintService,
                                     SanctionService sanctionService,
                                     ComplaintAppealService complaintAppealService,
                                     PermissionService permissionService,
                                     DoctorProfileService doctorProfileService) {
        this.complaintService = complaintService;
        this.sanctionService = sanctionService;
        this.complaintAppealService = complaintAppealService;
        this.permissionService = permissionService;
        this.doctorProfileService = doctorProfileService;
    }

    /**
     * 获取当前医生的投诉列表
     */
    @GetMapping("/complaints")
    public ResponseEntity<Map<String, Object>> getDoctorComplaints(HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }

        DoctorProfile doctorProfile = doctorProfileService.getDoctorProfileByUserId(userId);
        if (doctorProfile == null) {
            return forbidden();
        }

        Long doctorId = doctorProfile.getUserId();
        List<Map<String, Object>> complaints = complaintService.listComplaintsForDoctor(doctorId);

        Map<String, Object> data = new HashMap<>();
        data.put("items", complaints != null ? complaints : Collections.emptyList());
        return ok(response(true, "获取成功", data));
    }

    /**
     * 获取当前医生的处罚记录
     */
    @GetMapping("/sanctions")
    public ResponseEntity<Map<String, Object>> getDoctorSanctions(HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }

        DoctorProfile doctorProfile = doctorProfileService.getDoctorProfileByUserId(userId);
        if (doctorProfile == null) {
            return forbidden();
        }

        Long doctorId = doctorProfile.getUserId();
        List<DoctorSanction> activeSanctions = sanctionService.getActiveSanctionByDoctor(doctorId);
        List<DoctorSanction> allSanctions = sanctionService.getAllSanctionsByDoctor(doctorId);
        boolean blocked = sanctionService.hasActiveBlockingSanction(doctorId);

        Map<String, Object> data = new HashMap<>();
        data.put("active", activeSanctions != null ? activeSanctions : Collections.emptyList());
        data.put("all", allSanctions != null ? allSanctions : Collections.emptyList());
        data.put("blocked", blocked);
        return ok(response(true, "获取成功", data));
    }

    /**
     * 获取当前医生的申诉列表
     */
    @GetMapping("/appeals")
    public ResponseEntity<Map<String, Object>> getDoctorAppeals(HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }

        DoctorProfile doctorProfile = doctorProfileService.getDoctorProfileByUserId(userId);
        if (doctorProfile == null) {
            return forbidden();
        }

        Long doctorId = doctorProfile.getUserId();
        List<ComplaintAppeal> appeals = complaintAppealService.listByDoctorId(doctorId);

        Map<String, Object> data = new HashMap<>();
        data.put("items", appeals != null ? appeals : Collections.emptyList());
        return ok(response(true, "获取成功", data));
    }

    /**
     * 提交申诉
     */
    @PostMapping("/appeals")
    public ResponseEntity<Map<String, Object>> submitAppeal(HttpServletRequest request,
                                                            @RequestBody Map<String, Object> body) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }

        DoctorProfile doctorProfile = doctorProfileService.getDoctorProfileByUserId(userId);
        if (doctorProfile == null) {
            return forbidden();
        }

        Long decisionId = longValue(body.get("decisionId"));
        String reason = text(body.get("reason"));

        if (reason == null || reason.trim().isEmpty()) {
            return badRequest("申诉理由不能为空");
        }
        if (decisionId == null) {
            return badRequest("决策ID不能为空");
        }

        Long doctorId = doctorProfile.getUserId();
        ComplaintAppeal appeal = complaintAppealService.submitByDecision(decisionId, doctorId, reason);

        Map<String, Object> result = response(true, "申诉提交成功");
        result.put("data", appeal);
        return ok(result);
    }

    // ---------- 辅助方法 ----------

    private Map<String, Object> response(boolean success, String message) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("success", success);
        map.put("message", message);
        return map;
    }

    private Map<String, Object> response(boolean success, String message, Object data) {
        Map<String, Object> map = response(success, message);
        map.put("data", data);
        return map;
    }

    private ResponseEntity<Map<String, Object>> ok(Map<String, Object> body) {
        return ResponseEntity.ok(body);
    }

    private ResponseEntity<Map<String, Object>> forbidden() {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(response(false, "无权限访问"));
    }

    private ResponseEntity<Map<String, Object>> unauthorized() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(response(false, "未登录或登录已过期"));
    }

    private ResponseEntity<Map<String, Object>> badRequest(String msg) {
        return ResponseEntity.badRequest()
                .body(response(false, msg));
    }

    private String text(Object value) {
        if (value == null) {
            return null;
        }
        return String.valueOf(value);
    }

    private Long longValue(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Long) {
            return (Long) value;
        }
        if (value instanceof Number) {
            return ((Number) value).longValue();
        }
        try {
            return Long.parseLong(String.valueOf(value));
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
