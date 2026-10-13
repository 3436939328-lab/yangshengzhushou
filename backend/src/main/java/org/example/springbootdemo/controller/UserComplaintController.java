package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.Complaint;
import org.example.springbootdemo.bean.Consultation;
import org.example.springbootdemo.service.ComplaintService;
import org.example.springbootdemo.service.ConsultationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class UserComplaintController {

    private final ComplaintService complaintService;
    private final ConsultationService consultationService;
    private final PermissionService permissionService;

    public UserComplaintController(ComplaintService complaintService,
                                   ConsultationService consultationService,
                                   PermissionService permissionService) {
        this.complaintService = complaintService;
        this.consultationService = consultationService;
        this.permissionService = permissionService;
    }

    @PostMapping("/api/user/complaints")
    public ResponseEntity<Map<String, Object>> submitComplaint(@RequestBody Map<String, Object> body,
                                                               HttpServletRequest request) {
        Long reporterId = permissionService.currentUserId(request);
        Long consultationId = longValue(body.get("consultationId"));
        String category = text(body.get("category"));
        String description = text(body.get("description"));

        if (consultationId == null) {
            return badRequest("consultationId is required");
        }
        if (description.isEmpty()) {
            return badRequest("description is required");
        }

        Consultation consultation = consultationService.getConsultationById(consultationId);
        if (consultation == null) {
            return badRequest("consultation not found");
        }
        if (!consultation.getUserId().equals(reporterId)) {
            return forbidden();
        }

        Complaint complaint = complaintService.submitUserComplaint(
                reporterId,
                consultation.getDoctorId(),
                consultationId,
                category,
                description
        );

        return ok(response(true, "complaint submitted", complaint));
    }

    @GetMapping("/api/user/my-complaints")
    public ResponseEntity<Map<String, Object>> myComplaints(HttpServletRequest request) {
        Long reporterId = permissionService.currentUserId(request);
        Map<String, Object> complaints = complaintService.myComplaints(reporterId);
        return ok(response(true, "ok", complaints));
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

    private ResponseEntity<Map<String, Object>> forbidden() {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response(false, "forbidden"));
    }

    private ResponseEntity<Map<String, Object>> badRequest(String msg) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, msg));
    }

    private String text(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }

    private Long longValue(Object value) {
        if (value == null) return null;
        if (value instanceof Long) return (Long) value;
        if (value instanceof Integer) return ((Integer) value).longValue();
        try {
            return Long.parseLong(String.valueOf(value));
        } catch (NumberFormatException ex) {
            return null;
        }
    }
}
