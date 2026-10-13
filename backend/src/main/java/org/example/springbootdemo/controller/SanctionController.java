package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.DoctorSanction;
import org.example.springbootdemo.service.SanctionService;
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
import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class SanctionController {

    private final SanctionService sanctionService;
    private final PermissionService permissionService;

    public SanctionController(SanctionService sanctionService, PermissionService permissionService) {
        this.sanctionService = sanctionService;
        this.permissionService = permissionService;
    }

    @GetMapping("/admin/sanctions")
    public ResponseEntity<Map<String, Object>> listSanctions(
            @RequestParam("doctorId") Long doctorId,
            HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        List<DoctorSanction> items = sanctionService.listAllByDoctor(doctorId);
        Map<String, Object> data = new HashMap<>();
        data.put("items", items);
        data.put("total", items.size());
        return ok(response(true, "ok", data));
    }

    @GetMapping("/admin/sanctions/active")
    public ResponseEntity<Map<String, Object>> listActiveSanctions(
            @RequestParam("doctorId") Long doctorId,
            HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        List<DoctorSanction> items = sanctionService.getActiveSanctionByDoctor(doctorId);
        Map<String, Object> data = new HashMap<>();
        data.put("items", items);
        data.put("total", items.size());
        return ok(response(true, "ok", data));
    }

    @PostMapping("/admin/sanctions/{id}/approve")
    public ResponseEntity<Map<String, Object>> approvePermanentBan(@PathVariable("id") Long sanctionId,
                                                                     @RequestBody Map<String, Object> body,
                                                                     HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        Long approverId = permissionService.currentUserId(request);
        String reason = text(body.get("reason"));
        try {
            DoctorSanction updated = sanctionService.approvePermanentBan(sanctionId, approverId, reason);
            return ok(response(true, "permanent ban approved", updated));
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
}
