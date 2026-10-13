package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.service.RoleService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class RoleController {

    private final RoleService roleService;
    private final PermissionService permissionService;

    public RoleController(RoleService roleService, PermissionService permissionService) {
        this.roleService = roleService;
        this.permissionService = permissionService;
    }

    @GetMapping({"/role", "/api/role"})
    public ResponseEntity<Map<String, Object>> getRoleById(@RequestParam Long id, HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        Role role = roleService.getRoleById(id);
        return ResponseEntity.ok(response(role != null, role != null ? "query success" : "role not found", role));
    }

    @GetMapping({"/role/list", "/api/role/list"})
    public ResponseEntity<Map<String, Object>> listRoles(HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        return ResponseEntity.ok(response(true, "query success", roleService.listRoles()));
    }

    @PostMapping({"/role", "/api/role"})
    public ResponseEntity<Map<String, Object>> addRole(@RequestBody Role role, HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        if (isBlank(role.getRoleName())) {
            return ResponseEntity.ok(response(false, "roleName is required"));
        }
        boolean inserted = roleService.addRole(role) > 0;
        return ResponseEntity.ok(response(inserted, inserted ? "role created" : "create failed"));
    }

    @PutMapping({"/role", "/api/role"})
    public ResponseEntity<Map<String, Object>> updateRole(@RequestBody Role role, HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        if (role.getId() == null) {
            return ResponseEntity.ok(response(false, "id is required"));
        }
        boolean updated = roleService.updateRole(role) > 0;
        return ResponseEntity.ok(response(updated, updated ? "role updated" : "role not found"));
    }

    @DeleteMapping({"/role", "/api/role"})
    public ResponseEntity<Map<String, Object>> deleteRole(@RequestParam Long id, HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        boolean deleted = roleService.deleteRole(id) > 0;
        return ResponseEntity.ok(response(deleted, deleted ? "role deleted" : "role not found"));
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