package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.HealthIndicatorRecord;
import org.example.springbootdemo.bean.HealthQuestionnaireRecord;
import org.example.springbootdemo.bean.TongueObservationRecord;
import org.example.springbootdemo.service.HealthDetailService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class HealthDetailController {

    private final HealthDetailService healthDetailService;
    private final PermissionService permissionService;

    public HealthDetailController(HealthDetailService healthDetailService, PermissionService permissionService) {
        this.healthDetailService = healthDetailService;
        this.permissionService = permissionService;
    }

    @GetMapping({"/health-detail/current", "/api/health-detail/current"})
    public ResponseEntity<Map<String, Object>> getCurrentHealthDetails(HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) {
            return forbidden();
        }
        return ResponseEntity.ok(response(true, "query success", healthDetailService.getDetailsByUserId(currentUserId)));
    }

    @PostMapping({"/health-detail/questionnaire", "/api/health-detail/questionnaire"})
    public ResponseEntity<Map<String, Object>> addCurrentQuestionnaire(
            @RequestBody HealthQuestionnaireRecord record,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) {
            return forbidden();
        }
        if (isBlank(record.getConstitutionType())) {
            return ResponseEntity.ok(response(false, "constitutionType is required"));
        }
        record.setUserId(currentUserId);
        return ResponseEntity.ok(response(true, "questionnaire record created", healthDetailService.addQuestionnaireRecord(record)));
    }

    @PostMapping({"/health-detail/indicator", "/api/health-detail/indicator"})
    public ResponseEntity<Map<String, Object>> addCurrentHealthIndicator(
            @RequestBody HealthIndicatorRecord record,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) {
            return forbidden();
        }
        if (isBlank(record.getName()) || isBlank(record.getValue())) {
            return ResponseEntity.ok(response(false, "name and value are required"));
        }
        record.setUserId(currentUserId);
        return ResponseEntity.ok(response(true, "health indicator created", healthDetailService.addHealthIndicator(record)));
    }

    @PostMapping({"/health-detail/tongue", "/api/health-detail/tongue"})
    public ResponseEntity<Map<String, Object>> addCurrentTongueObservation(
            @RequestBody TongueObservationRecord record,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) {
            return forbidden();
        }
        if (isBlank(record.getColor()) || isBlank(record.getCoating()) || isBlank(record.getDryness())) {
            return ResponseEntity.ok(response(false, "tongue observation fields are required"));
        }
        record.setUserId(currentUserId);
        return ResponseEntity.ok(response(true, "tongue observation created", healthDetailService.addTongueObservation(record)));
    }

    @DeleteMapping({"/health-detail/indicator", "/api/health-detail/indicator"})
    public ResponseEntity<Map<String, Object>> deleteCurrentHealthIndicator(@RequestParam Long id, HttpServletRequest request) {
        HealthIndicatorRecord existing = healthDetailService.getHealthIndicatorById(id);
        if (existing != null && !permissionService.canAccessUser(request, existing.getUserId())) {
            return forbidden();
        }
        boolean deleted = healthDetailService.deleteHealthIndicator(id) > 0;
        return ResponseEntity.ok(response(deleted, deleted ? "health indicator deleted" : "health indicator not found"));
    }

    @DeleteMapping({"/health-detail/tongue", "/api/health-detail/tongue"})
    public ResponseEntity<Map<String, Object>> deleteCurrentTongueObservation(@RequestParam Long id, HttpServletRequest request) {
        TongueObservationRecord existing = healthDetailService.getTongueObservationById(id);
        if (existing != null && !permissionService.canAccessUser(request, existing.getUserId())) {
            return forbidden();
        }
        boolean deleted = healthDetailService.deleteTongueObservation(id) > 0;
        return ResponseEntity.ok(response(deleted, deleted ? "tongue observation deleted" : "tongue observation not found"));
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

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
