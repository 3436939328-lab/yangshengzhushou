package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.bean.User;
import org.example.springbootdemo.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class UserController {

    private final UserService userService;
    private final PermissionService permissionService;

    public UserController(UserService userService, PermissionService permissionService) {
        this.userService = userService;
        this.permissionService = permissionService;
    }

    @GetMapping({"/user/profile", "/api/user/profile"})
    public ResponseEntity<Map<String, Object>> profile(@RequestParam Long id, HttpServletRequest request) {
        if (!permissionService.canAccessUser(request, id)) {
            return forbidden();
        }
        User user = userService.getUserById(id);
        return ResponseEntity.ok(response(user != null, user != null ? "query success" : "user not found", user == null ? null : safeUser(user)));
    }

    @GetMapping({"/user/list", "/api/user/list"})
    public ResponseEntity<Map<String, Object>> listUsers(HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        List<Map<String, Object>> users = new ArrayList<>();
        for (User user : userService.listUsers()) {
            users.add(safeUser(user, true));
        }
        return ResponseEntity.ok(response(true, "query success", users));
    }

    @PostMapping({"/user", "/api/user"})
    public ResponseEntity<Map<String, Object>> addUser(@RequestBody User user, HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        if (isBlank(user.getUsername())) {
            return ResponseEntity.ok(response(false, "username is required"));
        }
        boolean inserted = userService.addUser(user) > 0;
        return ResponseEntity.ok(response(inserted, inserted ? "user created" : "create failed"));
    }

    @PutMapping({"/user/profile", "/api/user/profile"})
    public ResponseEntity<Map<String, Object>> updateProfile(@RequestBody User user, HttpServletRequest request) {
        if (user.getId() == null) {
            return ResponseEntity.ok(response(false, "id is required"));
        }
        if (!permissionService.canAccessUser(request, user.getId())) {
            return forbidden();
        }
        User profileUpdate = new User();
        profileUpdate.setId(user.getId());
        profileUpdate.setRealName(user.getRealName());
        profileUpdate.setPhone(user.getPhone());
        profileUpdate.setEmail(user.getEmail());
        profileUpdate.setBirthday(user.getBirthday());
        profileUpdate.setAvatar(user.getAvatar());
        profileUpdate.setGender(user.getGender());
        profileUpdate.setAge(user.getAge());
        boolean updated = userService.updateUser(profileUpdate) > 0;
        User saved = updated ? userService.getUserById(profileUpdate.getId()) : null;
        return ResponseEntity.ok(response(updated, updated ? "profile updated" : "user not found", saved == null ? null : safeUser(saved)));
    }

    @DeleteMapping({"/user", "/api/user"})
    public ResponseEntity<Map<String, Object>> deleteUser(@RequestParam Long id, HttpServletRequest request) {
        if (!permissionService.isAdmin(request)) {
            return forbidden();
        }
        boolean deleted = userService.deleteUser(id) > 0;
        return ResponseEntity.ok(response(deleted, deleted ? "user deleted" : "user not found"));
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

    private Map<String, Object> safeUser(User user) {
        return safeUser(user, false);
    }

    private Map<String, Object> safeUser(User user, boolean includeRoles) {
        Map<String, Object> safe = new HashMap<>();
        safe.put("id", user.getId());
        safe.put("username", user.getUsername());
        safe.put("realName", user.getRealName());
        // 管理员列表视图脱敏手机号和邮箱，密码始终不返回
        safe.put("phone", includeRoles ? maskPhone(user.getPhone()) : user.getPhone());
        safe.put("email", includeRoles ? maskEmail(user.getEmail()) : user.getEmail());
        safe.put("birthday", user.getBirthday());
        safe.put("avatar", user.getAvatar());
        safe.put("gender", user.getGender());
        safe.put("age", user.getAge());
        safe.put("status", user.getStatus());
        safe.put("createTime", user.getCreateTime());
        if (includeRoles) {
            List<String> roles = new ArrayList<>();
            if (user.getId() != null) {
                for (Role role : userService.getRolesByUserId(user.getId())) {
                    if (role.getRoleCode() != null && !role.getRoleCode().trim().isEmpty()) {
                        roles.add(role.getRoleCode());
                    }
                }
            }
            safe.put("roles", roles);
        }
        return safe;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) {
            return phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) {
            return email;
        }
        int atIndex = email.indexOf('@');
        String name = email.substring(0, atIndex);
        String domain = email.substring(atIndex);
        if (name.length() <= 2) {
            return name.charAt(0) + "***" + domain;
        }
        return name.charAt(0) + "***" + name.charAt(name.length() - 1) + domain;
    }
}
