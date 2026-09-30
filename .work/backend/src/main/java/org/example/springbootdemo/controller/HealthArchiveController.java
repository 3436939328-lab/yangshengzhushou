package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.HealthArchive;
import org.example.springbootdemo.service.HealthArchiveService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class HealthArchiveController {

    private final HealthArchiveService healthArchiveService;
    private final PermissionService permissionService;

    public HealthArchiveController(HealthArchiveService healthArchiveService, PermissionService permissionService) {
        this.healthArchiveService = healthArchiveService;
        this.permissionService = permissionService;
    }

    @GetMapping({"/health-archive", "/api/health-archive"})
    public ResponseEntity<Map<String, Object>> getHealthArchiveById(
            @RequestParam(required = false) Long id,
            @RequestParam(required = false) Long userId,
            HttpServletRequest request) {
        if (userId != null) {
            if (!permissionService.canAccessUser(request, userId)) {
                return forbidden();
            }
            HealthArchive archive = healthArchiveService.getHealthArchiveByUserId(userId);
            return ResponseEntity.ok(response(archive != null, archive != null ? "query success" : "health archive not found", archive));
        }
        if (id == null) {
            return ResponseEntity.ok(response(false, "id or userId is required"));
        }
        HealthArchive archive = healthArchiveService.getHealthArchiveById(id);
        if (archive != null && !permissionService.canAccessUser(request, archive.getUserId())) {
            return forbidden();
        }
        return ResponseEntity.ok(response(archive != null, archive != null ? "query success" : "health archive not found", archive));
    }

    @GetMapping({"/health-archive/list", "/api/health-archive/list"})
    public ResponseEntity<Map<String, Object>> listHealthArchives(HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        return ResponseEntity.ok(response(true, "query success", healthArchiveService.listHealthArchives()));
    }

    @PostMapping({"/health-archive", "/api/health-archive"})
    public ResponseEntity<Map<String, Object>> addHealthArchive(@RequestBody HealthArchive healthArchive, HttpServletRequest request) {
        if (healthArchive.getUserId() == null) {
            return ResponseEntity.ok(response(false, "userId is required"));
        }
        if (!permissionService.canAccessUser(request, healthArchive.getUserId())) {
            return forbidden();
        }
        boolean inserted = healthArchiveService.addHealthArchive(healthArchive) > 0;
        return ResponseEntity.ok(response(inserted, inserted ? "health archive created" : "create failed"));
    }

    @PutMapping({"/health-archive", "/api/health-archive"})
    public ResponseEntity<Map<String, Object>> updateHealthArchive(@RequestBody HealthArchive healthArchive, HttpServletRequest request) {
        if (healthArchive.getId() == null) {
            return ResponseEntity.ok(response(false, "id is required"));
        }
        HealthArchive existing = healthArchiveService.getHealthArchiveById(healthArchive.getId());
        if (existing != null && !permissionService.canAccessUser(request, existing.getUserId())) {
            return forbidden();
        }
        boolean updated = healthArchiveService.updateHealthArchive(healthArchive) > 0;
        return ResponseEntity.ok(response(updated, updated ? "health archive updated" : "health archive not found"));
    }

    @PutMapping({"/health-archive/current", "/api/health-archive/current"})
    public ResponseEntity<Map<String, Object>> upsertCurrentHealthArchive(@RequestBody HealthArchive healthArchive, HttpServletRequest request) {
        Long currentUserId = currentUserId(request);
        if (currentUserId == null) {
            return forbidden();
        }
        healthArchive.setUserId(currentUserId);
        HealthArchive saved = healthArchiveService.upsertHealthArchiveForUser(healthArchive, currentUserId);
        return ResponseEntity.ok(response(saved != null, saved != null ? "health archive saved" : "save failed", saved));
    }

    @GetMapping({"/health-archive/current", "/api/health-archive/current"})
    public ResponseEntity<Map<String, Object>> getCurrentHealthArchive(HttpServletRequest request) {
        Long currentUserId = currentUserId(request);
        if (currentUserId == null) {
            return forbidden();
        }
        HealthArchive archive = healthArchiveService.getHealthArchiveByUserId(currentUserId);
        return ResponseEntity.ok(response(archive != null, archive != null ? "query success" : "health archive not found", archive));
    }

    @DeleteMapping({"/health-archive", "/api/health-archive"})
    public ResponseEntity<Map<String, Object>> deleteHealthArchive(@RequestParam Long id, HttpServletRequest request) {
        HealthArchive existing = healthArchiveService.getHealthArchiveById(id);
        if (existing != null && !permissionService.canAccessUser(request, existing.getUserId())) {
            return forbidden();
        }
        boolean deleted = healthArchiveService.deleteHealthArchive(id) > 0;
        return ResponseEntity.ok(response(deleted, deleted ? "health archive deleted" : "health archive not found"));
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

    private Long currentUserId(HttpServletRequest request) {
        Object currentUserId = request.getAttribute("currentUserId");
        if (currentUserId instanceof Long userId) {
            return userId;
        }
        if (currentUserId instanceof Number number) {
            return number.longValue();
        }
        return null;
    }
}
