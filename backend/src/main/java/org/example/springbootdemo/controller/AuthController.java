package org.example.springbootdemo.controller;

import org.example.springbootdemo.auth.TokenStore;
import org.example.springbootdemo.auth.VerificationCodeService;
import org.example.springbootdemo.bean.User;
import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.service.UserService;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final String DEFAULT_ROLE_CODE = "USER";
    private static final String BEARER_PREFIX = "Bearer ";

    private final UserService userService;
    private final TokenStore tokenStore;
    private final VerificationCodeService verificationCodeService;

    public AuthController(UserService userService, TokenStore tokenStore, VerificationCodeService verificationCodeService) {
        this.userService = userService;
        this.tokenStore = tokenStore;
        this.verificationCodeService = verificationCodeService;
    }

    @PostMapping("/register")
    public Map<String, Object> register(@RequestBody User user) {
        if (isBlank(user.getPhone()) || isBlank(user.getPassword())) {
            return response(false, "phone and password are required");
        }
        if (user.getPassword().length() < 6) {
            return response(false, "password length must be at least 6");
        }

        User existing = userService.getUserByPhone(user.getPhone());
        if (existing != null) {
            return response(false, "phone already exists");
        }
        if (!verificationCodeService.consume("REGISTER", user.getPhone(), user.getCode())) {
            return response(false, "verification code error");
        }

        String rawPassword = user.getPassword();
        User savedUser = userService.registerUser(user, rawPassword);
        return response(true, "register success", authData(savedUser));
    }

    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody User request) {
        if (isBlank(request.getPhone()) || isBlank(request.getPassword())) {
            return response(false, "phone and password are required");
        }

        User user = userService.getUserByPhone(request.getPhone());
        if (user == null || !userService.matchesPassword(request.getPassword(), user.getPassword())) {
            return response(false, "phone or password error");
        }

        if (user.getStatus() != null && user.getStatus() == 0) {
            return response(false, "user disabled");
        }

        userService.upgradePasswordIfNeeded(user, request.getPassword());
        return response(true, "login success", authData(user));
    }

    @PostMapping("/sms-code")
    public Map<String, Object> sendSmsCode(@RequestBody Map<String, Object> request) {
        String phone = text(request.get("phone"));
        String purpose = normalizePurpose(text(request.get("purpose")));
        if (isBlank(phone)) {
            return response(false, "phone is required");
        }
        if (!isSupportedPurpose(purpose)) {
            return response(false, "purpose is invalid");
        }
        User existing = userService.getUserByPhone(phone);
        if ("REGISTER".equals(purpose) && existing != null) {
            return response(false, "phone already exists");
        }
        if (!"REGISTER".equals(purpose) && existing == null) {
            return response(false, "phone not found");
        }
        String code = verificationCodeService.generate(purpose, phone);
        Map<String, Object> data = new HashMap<>();
        data.put("devCode", code);
        return response(true, "verification code sent", data);
    }

    @PostMapping("/sms-login")
    public Map<String, Object> smsLogin(@RequestBody Map<String, Object> request) {
        String phone = text(request.get("phone"));
        String code = text(request.get("code"));
        if (isBlank(phone) || isBlank(code)) {
            return response(false, "phone and code are required");
        }
        User user = userService.getUserByPhone(phone);
        if (user == null) {
            return response(false, "phone not found");
        }
        if (user.getStatus() != null && user.getStatus() == 0) {
            return response(false, "user disabled");
        }
        if (!verificationCodeService.consume("LOGIN", phone, code)) {
            return response(false, "verification code error");
        }
        return response(true, "login success", authData(user));
    }

    @PostMapping("/password-reset/identify")
    public Map<String, Object> identifyPasswordResetAccount(@RequestBody Map<String, Object> request) {
        String account = text(request.get("account"));
        if (isBlank(account)) {
            return response(false, "account is required");
        }
        User user = userService.getUserByPhone(account);
        if (user == null) {
            user = userService.getUserByUsername(account);
        }
        if (user == null) {
            return response(false, "account not found");
        }
        Map<String, Object> data = new HashMap<>();
        data.put("phone", maskPhone(user.getPhone()));
        data.put("rawPhone", user.getPhone());
        return response(true, "account verified", data);
    }

    @PostMapping("/password-reset")
    public Map<String, Object> resetPassword(@RequestBody Map<String, Object> request) {
        String phone = text(request.get("phone"));
        String code = text(request.get("code"));
        String newPassword = text(request.get("newPassword"));
        if (isBlank(phone) || isBlank(code) || isBlank(newPassword)) {
            return response(false, "phone, code and newPassword are required");
        }
        if (newPassword.length() < 6) {
            return response(false, "password length must be at least 6");
        }
        User user = userService.getUserByPhone(phone);
        if (user == null) {
            return response(false, "phone not found");
        }
        if (!verificationCodeService.consume("RESET_PASSWORD", phone, code)) {
            return response(false, "verification code error");
        }
        boolean updated = userService.resetPassword(user.getId(), newPassword) > 0;
        return response(updated, updated ? "password reset success" : "password reset failed");
    }

    @GetMapping("/me")
    public Map<String, Object> me(@RequestHeader(value = "Authorization", required = false) String authorization) {
        String token = extractBearerToken(authorization);
        if (isBlank(token)) {
            return response(false, "missing token");
        }
        if (!tokenStore.isValid(token)) {
            return response(false, "invalid token");
        }
        Long userId = tokenStore.getUserId(token);
        User user = userId == null ? null : userService.getUserById(userId);
        if (user == null) {
            return response(false, "user not found");
        }
        Map<String, Object> data = new HashMap<>();
        data.put("user", safeUser(user));
        return response(true, "session valid", data);
    }

    private Map<String, Object> authData(User user) {
        Map<String, Object> data = new HashMap<>();
        data.put("token", tokenStore.createToken(user.getId()));
        data.put("user", safeUser(user));
        return data;
    }

    private Map<String, Object> safeUser(User user) {
        Map<String, Object> safe = new HashMap<>();
        safe.put("id", user.getId());
        safe.put("username", user.getUsername());
        safe.put("phone", user.getPhone());
        safe.put("realName", user.getRealName());
        safe.put("gender", user.getGender());
        safe.put("age", user.getAge());
        safe.put("status", user.getStatus());
        safe.put("createTime", user.getCreateTime());
        List<String> roles = new ArrayList<>();
        if (user.getId() != null) {
            for (Role role : userService.getRolesByUserId(user.getId())) {
                if (!isBlank(role.getRoleCode())) {
                    roles.add(role.getRoleCode());
                }
            }
        }
        if (roles.isEmpty()) {
            roles.add(DEFAULT_ROLE_CODE);
        }
        safe.put("roles", roles);
        return safe;
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

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String text(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }

    private String normalizePurpose(String purpose) {
        return isBlank(purpose) ? "" : purpose.trim().toUpperCase();
    }

    private boolean isSupportedPurpose(String purpose) {
        return "LOGIN".equals(purpose) || "REGISTER".equals(purpose) || "RESET_PASSWORD".equals(purpose);
    }

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) {
            return phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }

    private String extractBearerToken(String authorization) {
        if (authorization == null || !authorization.startsWith(BEARER_PREFIX)) {
            return "";
        }
        return authorization.substring(BEARER_PREFIX.length()).trim();
    }
}
