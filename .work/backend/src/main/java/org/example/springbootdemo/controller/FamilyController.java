package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.HealthArchive;
import org.example.springbootdemo.bean.HealthIndicatorRecord;
import org.example.springbootdemo.bean.User;
import org.example.springbootdemo.service.HealthArchiveService;
import org.example.springbootdemo.service.HealthDetailService;
import org.example.springbootdemo.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class FamilyController {

    private final UserService userService;
    private final HealthArchiveService healthArchiveService;
    private final HealthDetailService healthDetailService;
    private final PermissionService permissionService;

    public FamilyController(UserService userService,
                            HealthArchiveService healthArchiveService,
                            HealthDetailService healthDetailService,
                            PermissionService permissionService) {
        this.userService = userService;
        this.healthArchiveService = healthArchiveService;
        this.healthDetailService = healthDetailService;
        this.permissionService = permissionService;
    }

    @GetMapping({"/family/health-summary", "/api/family/health-summary"})
    public ResponseEntity<Map<String, Object>> getFamilyHealthSummary(
            @RequestParam String phone,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) {
            return forbidden();
        }
        if (phone == null || phone.trim().isEmpty()) {
            return ResponseEntity.ok(response(false, "phone is required"));
        }
        User targetUser = userService.getUserByPhone(phone.trim());
        if (targetUser == null) {
            return ResponseEntity.ok(response(false, "user not found by phone"));
        }

        Map<String, Object> summary = new HashMap<>();
        summary.put("userId", targetUser.getId());
        summary.put("realName", targetUser.getRealName() != null ? targetUser.getRealName() : targetUser.getUsername());
        summary.put("phone", targetUser.getPhone());
        summary.put("gender", targetUser.getGender());
        summary.put("age", targetUser.getAge());
        summary.put("avatar", targetUser.getAvatar());

        HealthArchive archive = healthArchiveService.getHealthArchiveByUserId(targetUser.getId());
        if (archive != null) {
            Map<String, Object> archiveData = new HashMap<>();
            archiveData.put("height", archive.getHeight());
            archiveData.put("weight", archive.getWeight());
            archiveData.put("constitutionType", archive.getConstitutionType());
            archiveData.put("allergyHistory", archive.getAllergyHistory());
            archiveData.put("medicalHistory", archive.getMedicalHistory());
            archiveData.put("healthGoal", archive.getHealthGoal());
            summary.put("healthArchive", archiveData);
        }

        List<HealthIndicatorRecord> indicators = healthDetailService.getIndicatorRecordsByUserId(targetUser.getId());
        List<Map<String, Object>> latestIndicators = buildLatestIndicators(indicators);
        summary.put("indicators", latestIndicators);

        return ResponseEntity.ok(response(true, "query success", summary));
    }

    private List<Map<String, Object>> buildLatestIndicators(List<HealthIndicatorRecord> records) {
        if (records == null || records.isEmpty()) {
            return new ArrayList<>();
        }
        Map<String, HealthIndicatorRecord> latestByName = new HashMap<>();
        for (HealthIndicatorRecord record : records) {
            if (record.getName() == null) continue;
            String name = record.getName();
            HealthIndicatorRecord existing = latestByName.get(name);
            if (existing == null || compareRecordedAt(record.getRecordedAt(), existing.getRecordedAt()) > 0) {
                latestByName.put(name, record);
            }
        }
        List<Map<String, Object>> result = new ArrayList<>();
        for (Map.Entry<String, HealthIndicatorRecord> entry : latestByName.entrySet()) {
            HealthIndicatorRecord rec = entry.getValue();
            Map<String, Object> item = new HashMap<>();
            item.put("name", rec.getName());
            item.put("value", rec.getValue());
            item.put("unit", rec.getUnit());
            item.put("recordedAt", rec.getRecordedAt());
            result.add(item);
        }
        return result;
    }

    private int compareRecordedAt(String a, String b) {
        if (a == null && b == null) return 0;
        if (a == null) return -1;
        if (b == null) return 1;
        return a.compareTo(b);
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
