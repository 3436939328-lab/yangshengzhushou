package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.UserRole;
import org.example.springbootdemo.service.UserRoleService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class UserRoleController {

    private final UserRoleService userRoleService;
    private final PermissionService permissionService;

    public UserRoleController(UserRoleService userRoleService, PermissionService permissionService) {
        this.userRoleService = userRoleService;
        this.permissionService = permissionService;
    }

    @GetMapping({"/user-role", "/api/user-role"})
    public ResponseEntity<Map<String, Object>> getUserRoleById(@RequestParam Long id, HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        UserRole userRole = userRoleService.getUserRoleById(id);
        return ResponseEntity.ok(response(userRole != null, userRole != null ? "query success" : "user role not found", userRole));
    }

    @GetMapping({"/user-role/list", "/api/user-role/list"})
    public ResponseEntity<Map<String, Object>> listUserRoles(HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        return ResponseEntity.ok(response(true, "query success", userRoleService.listUserRoles()));
    }

    @PostMapping({"/user-role", "/api/user-role"})
    public ResponseEntity<Map<String, Object>> addUserRole(@RequestBody UserRole userRole, HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        if (userRole.getUserId() == null || userRole.getRoleId() == null) {
            return ResponseEntity.ok(response(false, "userId and roleId are required"));
        }
        boolean inserted = userRoleService.addUserRole(userRole) > 0;
        return ResponseEntity.ok(response(inserted, inserted ? "user role created" : "create failed"));
    }

    @PutMapping({"/user-role", "/api/user-role"})
    public ResponseEntity<Map<String, Object>> updateUserRole(@RequestBody UserRole userRole, HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        if (userRole.getId() == null) {
            return ResponseEntity.ok(response(false, "id is required"));
        }
        boolean updated = userRoleService.updateUserRole(userRole) > 0;
        return ResponseEntity.ok(response(updated, updated ? "user role updated" : "user role not found"));
    }

    @DeleteMapping({"/user-role", "/api/user-role"})
    public ResponseEntity<Map<String, Object>> deleteUserRole(@RequestParam Long id, HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        boolean deleted = userRoleService.deleteUserRole(id) > 0;
        return ResponseEntity.ok(response(deleted, deleted ? "user role deleted" : "user role not found"));
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