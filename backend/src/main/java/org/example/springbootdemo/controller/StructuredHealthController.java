package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.HealthCardSummary;
import org.example.springbootdemo.bean.StructuredHealthMeasurement;
import org.example.springbootdemo.dao.StructuredHealthMeasurementDao;
import org.example.springbootdemo.service.HealthCardService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 结构化健康指标控制器
 * 提供血压、血糖、心率、血氧、体温、体格、步数、运动、饮水、睡眠 10种指标的CRUD
 * 以及健康卡摘要接口
 */
@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class StructuredHealthController {

    private final StructuredHealthMeasurementDao measurementDao;
    private final HealthCardService healthCardService;
    private final PermissionService permissionService;

    public StructuredHealthController(
            StructuredHealthMeasurementDao measurementDao,
            HealthCardService healthCardService,
            PermissionService permissionService) {
        this.measurementDao = measurementDao;
        this.healthCardService = healthCardService;
        this.permissionService = permissionService;
    }

    // ==================== 健康卡摘要 ====================

    @GetMapping({"/health-card", "/api/health-card"})
    public ResponseEntity<Map<String, Object>> getHealthCard(HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        HealthCardSummary card = healthCardService.buildHealthCard(currentUserId, "我");
        return ResponseEntity.ok(response(true, "success", card));
    }

    // ==================== 查询测量记录 ====================

    @GetMapping({"/health-measurements", "/api/health-measurements"})
    public ResponseEntity<Map<String, Object>> getMeasurements(
            @RequestParam(required = false) String metricCode,
            @RequestParam(defaultValue = "20") int limit,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        List<StructuredHealthMeasurement> records;
        if (metricCode != null && !metricCode.isBlank()) {
            records = measurementDao.selectByUserIdWithLimit(currentUserId, metricCode, limit);
        } else {
            records = measurementDao.selectByUserId(currentUserId);
        }
        return ResponseEntity.ok(response(true, "success", records));
    }

    @GetMapping({"/health-measurements/latest", "/api/health-measurements/latest"})
    public ResponseEntity<Map<String, Object>> getLatestMeasurement(
            @RequestParam String metricCode,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        StructuredHealthMeasurement record = measurementDao.selectLatestByUserIdAndMetric(currentUserId, metricCode);
        return ResponseEntity.ok(response(true, "success", record));
    }

    @GetMapping({"/health-measurements/{id}", "/api/health-measurements/{id}"})
    public ResponseEntity<Map<String, Object>> getMeasurementById(
            @PathVariable Long id,
            HttpServletRequest request) {
        StructuredHealthMeasurement record = measurementDao.selectByPrimaryKey(id);
        if (record == null) {
            return ResponseEntity.ok(response(false, "not found"));
        }
        if (!permissionService.canAccessUser(request, record.getUserId())) {
            return forbidden();
        }
        return ResponseEntity.ok(response(true, "success", record));
    }

    // ==================== 新增测量记录 ====================

    @PostMapping({"/health-measurements", "/api/health-measurements"})
    public ResponseEntity<Map<String, Object>> addMeasurement(
            @RequestBody StructuredHealthMeasurement record,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        // 验证必填字段
        if (record.getMetricCode() == null || record.getMetricCode().isBlank()) {
            return ResponseEntity.ok(response(false, "metricCode is required"));
        }
        if (record.getTypeSpecificJson() == null || record.getTypeSpecificJson().isBlank()) {
            return ResponseEntity.ok(response(false, "typeSpecificJson is required"));
        }

        record.setUserId(currentUserId);
        StructuredHealthMeasurement saved = healthCardService.addMeasurement(record);
        return ResponseEntity.ok(response(true, "measurement created", saved));
    }

    // ==================== 更新测量记录 ====================

    @PutMapping({"/health-measurements/{id}", "/api/health-measurements/{id}"})
    public ResponseEntity<Map<String, Object>> updateMeasurement(
            @PathVariable Long id,
            @RequestBody StructuredHealthMeasurement record,
            HttpServletRequest request) {
        StructuredHealthMeasurement existing = measurementDao.selectByPrimaryKey(id);
        if (existing == null) {
            return ResponseEntity.ok(response(false, "not found"));
        }
        if (!permissionService.canAccessUser(request, existing.getUserId())) {
            return forbidden();
        }

        record.setId(id);
        healthCardService.autoAssess(record);
        int updated = measurementDao.updateByPrimaryKeySelective(record);
        if (updated > 0) {
            StructuredHealthMeasurement updatedRecord = measurementDao.selectByPrimaryKey(id);
            return ResponseEntity.ok(response(true, "updated", updatedRecord));
        }
        return ResponseEntity.ok(response(false, "update failed"));
    }

    // ==================== 删除测量记录 ====================

    @DeleteMapping({"/health-measurements/{id}", "/api/health-measurements/{id}"})
    public ResponseEntity<Map<String, Object>> deleteMeasurement(
            @PathVariable Long id,
            HttpServletRequest request) {
        StructuredHealthMeasurement existing = measurementDao.selectByPrimaryKey(id);
        if (existing == null) {
            return ResponseEntity.ok(response(false, "not found"));
        }
        if (!permissionService.canAccessUser(request, existing.getUserId())) {
            return forbidden();
        }

        int deleted = measurementDao.logicalDeleteByPrimaryKey(id);
        return ResponseEntity.ok(response(deleted > 0,
                deleted > 0 ? "deleted" : "delete failed"));
    }

    // ==================== 辅助方法 ====================

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
