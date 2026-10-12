package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.Complaint;
import org.example.springbootdemo.service.ComplaintService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class ComplaintController {

    private final ComplaintService complaintService;
    private final PermissionService permissionService;

    public ComplaintController(ComplaintService complaintService, PermissionService permissionService) {
        this.complaintService = complaintService;
        this.permissionService = permissionService;
    }

    @GetMapping("/admin/complaints")
    public ResponseEntity<Map<String, Object>> listComplaints(
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "doctorId", required = false) Long doctorId,
            @RequestParam(value = "page", defaultValue = "1") int page,
            @RequestParam(value = "pageSize", defaultValue = "20") int pageSize,
            HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        return ok(response(true, "ok", complaintService.listForAdmin(status, doctorId, page, pageSize)));
    }

    @GetMapping("/admin/complaints/{id}")
    public ResponseEntity<Map<String, Object>> getComplaintDetail(@PathVariable("id") Long complaintId,
                                                                   HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        Map<String, Object> detail = complaintService.getDetail(complaintId);
        if (detail == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response(false, "complaint not found"));
        }
        return ok(response(true, "ok", detail));
    }

    @PostMapping("/admin/complaints/{id}/action")
    public ResponseEntity<Map<String, Object>> complaintAction(@PathVariable("id") Long complaintId,
                                                               @RequestBody Map<String, Object> body,
                                                               HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        Long reviewerId = permissionService.currentUserId(request);
        String action = text(body.get("action"));
        String reason = text(body.get("reason"));
        Long targetEventId = longValue(body.get("targetEventId"));
        Integer version = integer(body.get("version"));
        if (action.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, "action is required"));
        }
        try {
            Complaint updated = complaintService.action(complaintId, action, reason, targetEventId, reviewerId, version);
            return ok(response(true, "action completed", updated));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, ex.getMessage()));
        } catch (IllegalStateException ex) {
            return conflict(ex.getMessage());
        }
    }

    @PostMapping("/admin/complaints/{id}/decision")
    public ResponseEntity<Map<String, Object>> complaintDecision(@PathVariable("id") Long complaintId,
                                                                 @RequestBody Map<String, Object> body,
                                                                 HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        Long reviewerId = permissionService.currentUserId(request);
        String result = text(body.get("result"));
        String severity = text(body.get("severity"));
        String reason = text(body.get("reason"));
        Integer version = integer(body.get("version"));
        @SuppressWarnings("unchecked")
        Map<String, Object> sanction = (Map<String, Object>) body.get("sanction");
        if (result.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, "result is required"));
        }
        if (version == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, "version is required for optimistic lock"));
        }
        try {
            Complaint updated = complaintService.decision(complaintId, result, severity, reason, sanction, version, reviewerId);
            return ok(response(true, "decision saved", updated));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, ex.getMessage()));
        } catch (IllegalStateException ex) {
            return conflict(ex.getMessage());
        }
    }

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
