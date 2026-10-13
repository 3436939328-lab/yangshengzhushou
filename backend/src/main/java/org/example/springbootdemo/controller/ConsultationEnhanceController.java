package org.example.springbootdemo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.Consultation;
import org.example.springbootdemo.bean.HealthCardSummary;
import org.example.springbootdemo.service.ConsultationService;
import org.example.springbootdemo.service.HealthCardService;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * 问诊增强控制器
 * 提供问诊健康快照、问诊评价等扩展接口
 */
@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class ConsultationEnhanceController {

    private final ConsultationService consultationService;
    private final PermissionService permissionService;
    private final HealthCardService healthCardService;
    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public ConsultationEnhanceController(ConsultationService consultationService,
                                         PermissionService permissionService,
                                         HealthCardService healthCardService,
                                         JdbcTemplate jdbcTemplate) {
        this.consultationService = consultationService;
        this.permissionService = permissionService;
        this.healthCardService = healthCardService;
        this.jdbcTemplate = jdbcTemplate;
    }

    // ==================== 问诊健康快照 ====================

    /**
     * 获取问诊时的健康快照
     * 用于发起问诊时，将用户近期健康数据摘要分享给医生
     */
    @GetMapping({"/consultations/{id}/health-snapshot", "/api/consultations/{id}/health-snapshot"})
    public ResponseEntity<Map<String, Object>> getConsultationHealthSnapshot(
            @PathVariable Long id,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        Consultation consultation = consultationService.getConsultationById(id);
        if (consultation == null) {
            return ResponseEntity.ok(response(false, "问诊不存在"));
        }

        // 验证权限：问诊用户或对应医生可以查看
        boolean isUser = currentUserId.equals(consultation.getUserId());
        boolean isDoctor = currentUserId.equals(consultation.getDoctorId());

        if (!isUser && !isDoctor && !permissionService.isAdmin(request)) {
            return forbidden();
        }

        // 构建用户的健康卡
        HealthCardSummary card = healthCardService.buildHealthCard(
                consultation.getUserId(), "用户");

        // 查询舌象照片（最近一张）
        List<Map<String, Object>> tongueImages = jdbcTemplate.queryForList(
                "select id, image_url as imageUrl, thumbnail_url as thumbnailUrl, " +
                        "captured_at as capturedAt, analysis_status as analysisStatus, " +
                        "analysis_result_json as analysisResult " +
                        "from tongue_image_record where user_id = ? and is_deleted = 0 " +
                        "order by captured_at desc limit 1",
                consultation.getUserId());

        Map<String, Object> result = new HashMap<>();
        result.put("healthCard", card);
        result.put("includeTongue", !tongueImages.isEmpty());
        result.put("tongueImage", tongueImages.isEmpty() ? null : tongueImages.get(0));
        result.put("snapshotTime", new Date());

        return ResponseEntity.ok(response(true, "success", result));
    }

    // ==================== 问诊评价 ====================

    /**
     * 获取问诊评价
     */
    @GetMapping({"/consultations/{id}/rating", "/api/consultations/{id}/rating"})
    public ResponseEntity<Map<String, Object>> getConsultationRating(
            @PathVariable Long id,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        Consultation consultation = consultationService.getConsultationById(id);
        if (consultation == null) {
            return ResponseEntity.ok(response(false, "问诊不存在"));
        }

        // 只有问诊用户可以查看自己的评价
        if (!currentUserId.equals(consultation.getUserId()) && !permissionService.isAdmin(request)) {
            return forbidden();
        }

        Map<String, Object> rating = findRatingByConsultationId(id);
        return ResponseEntity.ok(response(true, "success", rating));
    }

    /**
     * 提交问诊评价
     */
    @PostMapping({"/consultations/{id}/rating", "/api/consultations/{id}/rating"})
    public ResponseEntity<Map<String, Object>> submitConsultationRating(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        Consultation consultation = consultationService.getConsultationById(id);
        if (consultation == null) {
            return ResponseEntity.ok(response(false, "问诊不存在"));
        }

        // 只有问诊用户可以评价
        if (!currentUserId.equals(consultation.getUserId())) {
            return forbidden();
        }

        // 检查是否已评价
        Map<String, Object> existing = findRatingByConsultationId(id);
        if (existing != null) {
            return ResponseEntity.ok(response(false, "已评价过该问诊"));
        }

        Integer rating = (Integer) body.get("rating");
        String content = (String) body.get("content");
        List<String> tags = (List<String>) body.get("tags");

        if (rating == null || rating < 1 || rating > 5) {
            return ResponseEntity.ok(response(false, "评分需在1-5之间"));
        }

        String tagsJson;
        try {
            tagsJson = objectMapper.writeValueAsString(tags != null ? tags : List.of());
        } catch (Exception e) {
            tagsJson = "[]";
        }

        jdbcTemplate.update(
                "insert into consultation_rating (consultation_id, user_id, rating, content, tags) " +
                        "values (?, ?, ?, ?, ?)",
                id, currentUserId, rating, content, tagsJson);

        return ResponseEntity.ok(response(true, "评价提交成功"));
    }

    // ==================== 医生评价列表 ====================

    /**
     * 获取医生的评价列表
     */
    @GetMapping({"/doctors/{doctorId}/ratings", "/api/doctors/{doctorId}/ratings"})
    public ResponseEntity<Map<String, Object>> getDoctorRatings(
            @PathVariable Long doctorId,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            HttpServletRequest request) {

        // 查询该医生的所有问诊评价
        List<Map<String, Object>> ratings = jdbcTemplate.queryForList(
                "select r.id, r.consultation_id as consultationId, r.user_id as userId, " +
                        "r.rating, r.content, r.tags, r.create_time as createTime, " +
                        "c.symptom " +
                        "from consultation_rating r " +
                        "join consultation c on r.consultation_id = c.id " +
                        "where c.doctor_id = ? and r.is_visible = 1 " +
                        "order by r.create_time desc limit ? offset ?",
                doctorId, limit, offset);

        // 计算平均分
        Map<String, Object> avgResult = jdbcTemplate.queryForMap(
                "select count(*) as total, avg(r.rating) as avgRating " +
                        "from consultation_rating r " +
                        "join consultation c on r.consultation_id = c.id " +
                        "where c.doctor_id = ? and r.is_visible = 1",
                doctorId);

        Map<String, Object> result = new HashMap<>();
        result.put("ratings", ratings);
        result.put("total", avgResult.get("total"));
        result.put("avgRating", avgResult.get("avgRating"));

        return ResponseEntity.ok(response(true, "success", result));
    }

    // ==================== 辅助方法 ====================

    private Map<String, Object> findRatingByConsultationId(Long consultationId) {
        try {
            return jdbcTemplate.queryForMap(
                    "select id, consultation_id as consultationId, user_id as userId, " +
                            "rating, content, tags, is_visible as isVisible, " +
                            "create_time as createTime " +
                            "from consultation_rating where consultation_id = ?",
                    consultationId);
        } catch (Exception e) {
            return null;
        }
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

    private ResponseEntity<Map<String, Object>> forbidden() {
        return ResponseEntity.status(403).body(response(false, "forbidden"));
    }
}
