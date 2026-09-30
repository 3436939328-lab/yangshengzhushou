package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.Consultation;
import org.example.springbootdemo.service.ConsultationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class ConsultationController {

    private final ConsultationService consultationService;
    private final PermissionService permissionService;

    public ConsultationController(ConsultationService consultationService, PermissionService permissionService) {
        this.consultationService = consultationService;
        this.permissionService = permissionService;
    }

    @GetMapping({"/consultation/list", "/api/consultation/list"})
    public ResponseEntity<Map<String, Object>> listConsultations(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Long doctorId,
            HttpServletRequest request) {
        if (!permissionService.canAccessConsultationFilter(request, userId, doctorId)) {
            return forbidden();
        }
        if (userId == null && doctorId == null) {
            return ResponseEntity.ok(response(true, "query success", consultationService.listConsultations()));
        }
        return ResponseEntity.ok(response(true, "query success", consultationService.listConsultations(userId, doctorId)));
    }

    @GetMapping({"/consultation/detail", "/api/consultation/detail"})
    public ResponseEntity<Map<String, Object>> getConsultationDetail(@RequestParam Long id, HttpServletRequest request) {
        Consultation consultation = consultationService.getConsultationById(id);
        if (!permissionService.canAccessConsultation(request, consultation)) {
            return forbidden();
        }
        return ResponseEntity.ok(response(consultation != null, consultation != null ? "query success" : "consultation not found", consultation));
    }

    @PostMapping({"/consultation", "/api/consultation"})
    public ResponseEntity<Map<String, Object>> addConsultation(@RequestBody Consultation consultation, HttpServletRequest request) {
        if (consultation.getUserId() == null) {
            consultation.setUserId(permissionService.currentUserId(request));
        }
        if (consultation.getUserId() == null) {
            return ResponseEntity.ok(response(false, "userId is required"));
        }
        if (!permissionService.canCreateConsultation(request, consultation.getUserId())) {
            return forbidden();
        }
        if (consultation.getDoctorId() == null) {
            return ResponseEntity.ok(response(false, "doctorId is required"));
        }
        if (isBlank(consultation.getSymptom())) {
            consultation.setSymptom(consultation.getTitle());
        }
        if (isBlank(consultation.getSymptom())) {
            return ResponseEntity.ok(response(false, "symptom is required"));
        }
        if (isBlank(consultation.getDescription())) {
            return ResponseEntity.ok(response(false, "description is required"));
        }
        boolean inserted = consultationService.addConsultation(consultation) > 0;
        return ResponseEntity.ok(response(inserted, inserted ? "consultation created" : "create failed", inserted ? consultation : null));
    }

    @PutMapping({"/consultation/status", "/api/consultation/status"})
    public ResponseEntity<Map<String, Object>> updateConsultationStatus(@RequestBody Map<String, Object> payload, HttpServletRequest request) {
        Long id = toLong(payload.get("id"));
        Byte status = toByte(payload.get("status"));
        if (id == null) {
            return ResponseEntity.ok(response(false, "id is required"));
        }
        if (status == null) {
            return ResponseEntity.ok(response(false, "status is required"));
        }
        Consultation consultation = consultationService.getConsultationById(id);
        if (consultation == null) {
            return ResponseEntity.ok(response(false, "consultation not found"));
        }
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null || !currentUserId.equals(consultation.getDoctorId())) {
            return forbidden();
        }
        boolean updated = consultationService.updateConsultationStatus(id, status) > 0;
        return ResponseEntity.ok(response(updated, updated ? "status updated" : "consultation not found"));
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

    private Long toLong(Object value) {
        if (value instanceof Number number) {
            return number.longValue();
        }
        if (value instanceof String text && !isBlank(text)) {
            try {
                return Long.parseLong(text);
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }

    private Byte toByte(Object value) {
        if (value instanceof Number number) {
            return number.byteValue();
        }
        if (value instanceof String text && !isBlank(text)) {
            try {
                return Byte.parseByte(text);
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }
}
