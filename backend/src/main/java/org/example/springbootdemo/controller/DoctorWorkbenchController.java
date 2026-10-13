package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.DoctorProfile;
import org.example.springbootdemo.service.DoctorProfileService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

/**
 * 医生工作台控制器
 * 提供医生端首页概览数据、统计信息、待办提醒等
 */
@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
@RequestMapping("/api/doctor")
public class DoctorWorkbenchController {

    private final PermissionService permissionService;
    private final DoctorProfileService doctorProfileService;
    private final JdbcTemplate jdbcTemplate;

    public DoctorWorkbenchController(PermissionService permissionService,
                                     DoctorProfileService doctorProfileService,
                                     JdbcTemplate jdbcTemplate) {
        this.permissionService = permissionService;
        this.doctorProfileService = doctorProfileService;
        this.jdbcTemplate = jdbcTemplate;
    }

    /**
     * 医生工作台概览数据
     * 包含：医生信息、接诊状态、数据统计、待办提醒
     */
    @GetMapping("/workbench/overview")
    public ResponseEntity<Map<String, Object>> getWorkbenchOverview(HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }

        DoctorProfile doctorProfile = doctorProfileService.getDoctorProfileByUserId(userId);
        if (doctorProfile == null) {
            return forbidden();
        }

        Long doctorId = doctorProfile.getUserId();

        Map<String, Object> data = new LinkedHashMap<>();

        // 1. 医生基本信息
        Map<String, Object> profile = new LinkedHashMap<>();
        profile.put("doctorId", doctorId);
        profile.put("name", doctorProfile.getDoctorName());
        profile.put("title", doctorProfile.getTitle());
        profile.put("specialty", doctorProfile.getSpecialty());
        profile.put("department", doctorProfile.getDepartment());
        profile.put("avatar", doctorProfile.getAvatar());
        profile.put("verificationStatus", doctorProfile.getVerificationStatus());
        profile.put("accepting", doctorProfile.getAccepting());
        data.put("profile", profile);

        // 2. 数据统计
        Map<String, Object> stats = buildDoctorStats(doctorId);
        data.put("stats", stats);

        // 3. 待办事项
        List<Map<String, Object>> todos = buildDoctorTodos(doctorId, userId);
        data.put("todos", todos);

        // 4. 快捷入口
        List<Map<String, Object>> quickActions = buildQuickActions(doctorProfile);
        data.put("quickActions", quickActions);

        return ok(response(true, "获取成功", data));
    }

    /**
     * 切换接诊状态
     */
    @PostMapping("/workbench/toggle-accepting")
    public ResponseEntity<Map<String, Object>> toggleAccepting(HttpServletRequest request,
                                                               @RequestBody Map<String, Object> body) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return unauthorized();
        }

        DoctorProfile doctorProfile = doctorProfileService.getDoctorProfileByUserId(userId);
        if (doctorProfile == null) {
            return forbidden();
        }

        Boolean accepting = (Boolean) body.get("accepting");
        if (accepting == null) {
            return badRequest("accepting 参数不能为空");
        }

        // 只有审核通过的医生才能切换接诊状态
        if (!"APPROVED".equals(doctorProfile.getVerificationStatus())) {
            return badRequest("资质审核通过后才能开启接诊");
        }

        jdbcTemplate.update("update doctor_profile set accepting = ? where user_id = ?",
                accepting, doctorProfile.getUserId());

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("accepting", accepting);
        return ok(response(true, accepting ? "已开启接诊" : "已暂停接诊", result));
    }

    // ==================== 私有方法 ====================

    private Map<String, Object> buildDoctorStats(Long doctorId) {
        Map<String, Object> stats = new LinkedHashMap<>();

        // 今日问诊数
        int todayConsultations = jdbcTemplate.queryForObject(
                "select count(*) from consultation where doctor_id = ? and date(create_time) = curdate()",
                Integer.class, doctorId);
        stats.put("todayConsultations", todayConsultations);

        // 待回复问诊数（状态为0=进行中且最后一条消息来自患者）
        // 简化：状态为0的问诊数
        int pendingReplies = jdbcTemplate.queryForObject(
                "select count(*) from consultation where doctor_id = ? and status = 0",
                Integer.class, doctorId);
        stats.put("pendingReplies", pendingReplies);

        // 累计服务患者数（去重）
        int totalPatients = jdbcTemplate.queryForObject(
                "select count(distinct user_id) from consultation where doctor_id = ?",
                Integer.class, doctorId);
        stats.put("totalPatients", totalPatients);

        // 累计问诊数
        int totalConsultations = jdbcTemplate.queryForObject(
                "select count(*) from consultation where doctor_id = ?",
                Integer.class, doctorId);
        stats.put("totalConsultations", totalConsultations);

        // 好评率
        try {
            Map<String, Object> ratingResult = jdbcTemplate.queryForMap(
                    "select count(*) as total, avg(rating) as avgRating " +
                            "from consultation_rating r " +
                            "join consultation c on r.consultation_id = c.id " +
                            "where c.doctor_id = ? and r.is_visible = 1",
                    doctorId);
            int ratingCount = ((Number) ratingResult.get("total")).intValue();
            double avgRating = ratingResult.get("avgRating") != null
                    ? ((Number) ratingResult.get("avgRating")).doubleValue()
                    : 0.0;
            // 好评率：4星及以上算好评
            int goodRatings = 0;
            if (ratingCount > 0) {
                goodRatings = jdbcTemplate.queryForObject(
                        "select count(*) from consultation_rating r " +
                                "join consultation c on r.consultation_id = c.id " +
                                "where c.doctor_id = ? and r.is_visible = 1 and r.rating >= 4",
                        Integer.class, doctorId);
            }
            double goodRate = ratingCount > 0 ? (goodRatings * 100.0 / ratingCount) : 0.0;

            stats.put("avgRating", roundTo(avgRating, 1));
            stats.put("ratingCount", ratingCount);
            stats.put("goodRate", roundTo(goodRate, 1));
        } catch (Exception e) {
            stats.put("avgRating", 0.0);
            stats.put("ratingCount", 0);
            stats.put("goodRate", 0.0);
        }

        return stats;
    }

    private List<Map<String, Object>> buildDoctorTodos(Long doctorId, Long userId) {
        List<Map<String, Object>> todos = new ArrayList<>();

        // 待回复问诊
        int pendingCount = jdbcTemplate.queryForObject(
                "select count(*) from consultation where doctor_id = ? and status = 0",
                Integer.class, doctorId);
        if (pendingCount > 0) {
            Map<String, Object> todo = new LinkedHashMap<>();
            todo.put("type", "pending_consultation");
            todo.put("title", "待回复问诊");
            todo.put("count", pendingCount);
            todo.put("description", pendingCount + " 位患者等待你的回复");
            todo.put("icon", "💬");
            todo.put("actionTab", "doctorConsultation");
            todos.add(todo);
        }

        // 待处理投诉
        try {
            int complaintCount = jdbcTemplate.queryForObject(
                    "select count(*) from complaint where doctor_id = ? and status = 'PENDING'",
                    Integer.class, doctorId);
            if (complaintCount > 0) {
                Map<String, Object> todo = new LinkedHashMap<>();
                todo.put("type", "pending_complaint");
                todo.put("title", "待处理投诉");
                todo.put("count", complaintCount);
                todo.put("description", "有 " + complaintCount + " 条投诉需要关注");
                todo.put("icon", "⚠️");
                todo.put("actionTab", "doctorComplaint");
                todos.add(todo);
            }
        } catch (Exception e) {
            // 表可能不存在，忽略
        }

        // 资质审核中
        DoctorProfile profile = doctorProfileService.getDoctorProfileByUserId(userId);
        if (profile != null && "PENDING".equals(profile.getVerificationStatus())) {
            Map<String, Object> todo = new LinkedHashMap<>();
            todo.put("type", "review_pending");
            todo.put("title", "资质审核中");
            todo.put("count", 1);
            todo.put("description", "你的资质资料正在审核中，请耐心等待");
            todo.put("icon", "📋");
            todo.put("actionTab", "doctorProfile");
            todos.add(todo);
        }

        // 审核被驳回
        if (profile != null && "REJECTED".equals(profile.getVerificationStatus())) {
            Map<String, Object> todo = new LinkedHashMap<>();
            todo.put("type", "review_rejected");
            todo.put("title", "审核未通过");
            todo.put("count", 1);
            todo.put("description", "资质审核未通过，请查看原因并重新提交");
            todo.put("icon", "❌");
            todo.put("actionTab", "doctorProfile");
            todos.add(todo);
        }

        // 活跃处罚
        try {
            int activeSanctions = jdbcTemplate.queryForObject(
                    "select count(*) from doctor_sanction where doctor_id = ? and status = 'ACTIVE'",
                    Integer.class, doctorId);
            if (activeSanctions > 0) {
                Map<String, Object> todo = new LinkedHashMap<>();
                todo.put("type", "active_sanction");
                todo.put("title", "处罚通知");
                todo.put("count", activeSanctions);
                todo.put("description", "有 " + activeSanctions + " 条活跃处罚记录");
                todo.put("icon", "🚫");
                todo.put("actionTab", "doctorComplaint");
                todos.add(todo);
            }
        } catch (Exception e) {
            // 忽略
        }

        // 如果没有待办，添加一条空状态
        if (todos.isEmpty()) {
            Map<String, Object> todo = new LinkedHashMap<>();
            todo.put("type", "all_clear");
            todo.put("title", "一切正常");
            todo.put("count", 0);
            todo.put("description", "暂无待办事项，继续保持！");
            todo.put("icon", "✅");
            todo.put("actionTab", "");
            todos.add(todo);
        }

        return todos;
    }

    private List<Map<String, Object>> buildQuickActions(DoctorProfile profile) {
        List<Map<String, Object>> actions = new ArrayList<>();

        // 我的患者
        Map<String, Object> patients = new LinkedHashMap<>();
        patients.put("key", "patients");
        patients.put("title", "我的患者");
        patients.put("icon", "👥");
        patients.put("tab", "doctorPatient");
        actions.add(patients);

        // 我的评价
        Map<String, Object> ratings = new LinkedHashMap<>();
        ratings.put("key", "ratings");
        ratings.put("title", "我的评价");
        ratings.put("icon", "⭐");
        ratings.put("tab", "doctorProfile");
        actions.add(ratings);

        // 医生资料
        Map<String, Object> profileAction = new LinkedHashMap<>();
        profileAction.put("key", "profile");
        profileAction.put("title", "我的资料");
        profileAction.put("icon", "📝");
        profileAction.put("tab", "doctorProfile");
        actions.add(profileAction);

        // 积分奖励
        Map<String, Object> rewards = new LinkedHashMap<>();
        rewards.put("key", "rewards");
        rewards.put("title", "积分奖励");
        rewards.put("icon", "🎁");
        rewards.put("tab", "doctorProfile");
        actions.add(rewards);

        return actions;
    }

    private double roundTo(double value, int places) {
        BigDecimal bd = BigDecimal.valueOf(value);
        bd = bd.setScale(places, RoundingMode.HALF_UP);
        return bd.doubleValue();
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
}
