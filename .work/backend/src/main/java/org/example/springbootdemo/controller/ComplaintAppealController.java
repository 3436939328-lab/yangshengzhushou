package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.ComplaintAppeal;
import org.example.springbootdemo.service.ComplaintAppealService;
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
public class ComplaintAppealController {

    private final ComplaintAppealService complaintAppealService;
    private final PermissionService permissionService;

    public ComplaintAppealController(ComplaintAppealService complaintAppealService, PermissionService permissionService) {
        this.complaintAppealService = complaintAppealService;
        this.permissionService = permissionService;
    }

    @GetMapping("/admin/appeals")
    public ResponseEntity<Map<String, Object>> listAppeals(
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "page", defaultValue = "1") int page,
            @RequestParam(value = "pageSize", defaultValue = "20") int pageSize,
            HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        return ok(response(true, "ok", complaintAppealService.listForAdmin(status, page, pageSize)));
    }

    @GetMapping("/admin/appeals/{id}")
    public ResponseEntity<Map<String, Object>> getAppealDetail(@PathVariable("id") Long appealId,
                                                                HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        Map<String, Object> detail = complaintAppealService.getDetail(appealId);
        if (detail == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response(false, "appeal not found"));
        }
        return ok(response(true, "ok", detail));
    }

    @PostMapping("/admin/appeals/{id}/review")
    public ResponseEntity<Map<String, Object>> reviewAppeal(@PathVariable("id") Long appealId,
                                                            @RequestBody Map<String, Object> body,
                                                            HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        Long reviewerId = permissionService.currentUserId(request);
        String decision = text(body.get("decision"));
        String reason = text(body.get("reason"));
        Integer version = integer(body.get("version"));
        if (decision.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, "decision is required"));
        }
        if (version == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, "version is required for optimistic lock"));
        }
        try {
            ComplaintAppeal updated = complaintAppealService.review(appealId, decision, reason, reviewerId, version);
            return ok(response(true, "review completed", updated));
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
}
