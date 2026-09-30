package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.Consultation;
import org.example.springbootdemo.bean.ConsultationMessage;
import org.example.springbootdemo.service.ConsultationService;
import org.example.springbootdemo.service.ConsultationMessageService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class ConsultationMessageController {

    private static final String USER_ROLE_CODE = "USER";
    private static final String DOCTOR_ROLE_CODE = "DOCTOR";

    private final ConsultationMessageService consultationMessageService;
    private final ConsultationService consultationService;
    private final PermissionService permissionService;

    public ConsultationMessageController(
            ConsultationMessageService consultationMessageService,
            ConsultationService consultationService,
            PermissionService permissionService) {
        this.consultationMessageService = consultationMessageService;
        this.consultationService = consultationService;
        this.permissionService = permissionService;
    }

    @GetMapping({"/consultation-message/list", "/api/consultation-message/list"})
    public ResponseEntity<Map<String, Object>> listConsultationMessages(@RequestParam Long consultationId, HttpServletRequest request) {
        Consultation consultation = consultationService.getConsultationById(consultationId);
        if (!permissionService.canAccessConsultation(request, consultation)) {
            return forbidden();
        }
        return ResponseEntity.ok(response(true, "query success", consultationMessageService.listMessagesByConsultationId(consultationId)));
    }

    @PostMapping({"/consultation-message", "/api/consultation-message"})
    public ResponseEntity<Map<String, Object>> addConsultationMessage(@RequestBody ConsultationMessage consultationMessage, HttpServletRequest request) {
        if (consultationMessage.getConsultationId() == null) {
            return ResponseEntity.ok(response(false, "consultationId is required"));
        }
        Consultation consultation = consultationService.getConsultationById(consultationMessage.getConsultationId());
        if (!permissionService.canAccessConsultation(request, consultation)) {
            return forbidden();
        }
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) {
            return forbidden();
        }
        if (isBlank(consultationMessage.getContent())) {
            return ResponseEntity.ok(response(false, "content is required"));
        }
        if (consultation == null) {
            return ResponseEntity.ok(response(false, "consultation not found"));
        }

        if (currentUserId.equals(consultation.getDoctorId())) {
            consultationMessage.setSenderRole(DOCTOR_ROLE_CODE);
        } else if (currentUserId.equals(consultation.getUserId())) {
            consultationMessage.setSenderRole(USER_ROLE_CODE);
        } else {
            return forbidden();
        }
        consultationMessage.setSenderId(currentUserId);
        boolean inserted = consultationMessageService.addConsultationMessage(consultationMessage) > 0;
        if (inserted && DOCTOR_ROLE_CODE.equals(consultationMessage.getSenderRole())) {
            consultationService.markConsultationReplied(consultation.getId());
        }
        return ResponseEntity.ok(response(inserted, inserted ? "consultation message created" : "create failed"));
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
