package org.example.springbootdemo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.auth.TokenStore;
import org.example.springbootdemo.auth.VerificationCodeService;
import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.bean.User;
import org.example.springbootdemo.service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashMap;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private UserService userService;

    @MockBean
    private TokenStore tokenStore;

    @MockBean
    private VerificationCodeService verificationCodeService;

    @Test
    void registerCreatesEnabledPhoneUserWithUserRoleAndToken() throws Exception {
        when(userService.getUserByPhone("13800138000")).thenReturn(null);
        when(verificationCodeService.consume("REGISTER", "13800138000", "246810")).thenReturn(true);
        when(tokenStore.createToken(anyLong())).thenReturn("test-token");
        when(userService.registerUser(any(User.class), eq("123456"))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(10L);
            user.setPassword("$2a$10$hash-value");
            user.setStatus((byte) 1);
            return user;
        });

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(phonePayload("13800138000", "123456", "New User"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("register success"))
                .andExpect(jsonPath("$.data.token").isNotEmpty())
                .andExpect(jsonPath("$.data.user.phone").value("13800138000"))
                .andExpect(jsonPath("$.data.user.password").doesNotExist())
                .andExpect(jsonPath("$.data.user.roles[0]").value("USER"));
    }

    @Test
    void registerRejectsDuplicatedPhone() throws Exception {
        User existing = new User();
        existing.setPhone("13800138000");
        when(userService.getUserByPhone("13800138000")).thenReturn(existing);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(phonePayload("13800138000", "123456", "User"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("phone already exists"));
    }

    @Test
    void registerRejectsMissingOrWrongSmsCode() throws Exception {
        when(userService.getUserByPhone("13800138000")).thenReturn(null);
        when(verificationCodeService.consume("REGISTER", "13800138000", "000000")).thenReturn(false);

        Map<String, Object> payload = phonePayload("13800138000", "123456", "User");
        payload.put("code", "000000");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("verification code error"));
    }

    @Test
    void loginAcceptsPhoneAndReturnsTokenAndUserRole() throws Exception {
        User user = new User();
        user.setId(1L);
        user.setPhone("13800138000");
        user.setPassword("$2a$10$hashed-password");
        user.setRealName("Admin");
        user.setStatus((byte) 1);
        when(userService.getUserByPhone("13800138000")).thenReturn(user);
        when(userService.matchesPassword("123456", "$2a$10$hashed-password")).thenReturn(true);
        when(tokenStore.createToken(anyLong())).thenReturn("test-token");
        Role adminRole = new Role();
        adminRole.setRoleCode("ADMIN");
        when(userService.getRolesByUserId(1L)).thenReturn(java.util.List.of(adminRole));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(phonePayload("13800138000", "123456", null))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("login success"))
                .andExpect(jsonPath("$.data.token").isNotEmpty())
                .andExpect(jsonPath("$.data.user.phone").value("13800138000"))
                .andExpect(jsonPath("$.data.user.password").doesNotExist())
                .andExpect(jsonPath("$.data.user.roles[0]").value("ADMIN"));
        verify(userService).upgradePasswordIfNeeded(user, "123456");
    }

    @Test
    void loginRejectsWrongPassword() throws Exception {
        User user = new User();
        user.setPhone("13800138000");
        user.setPassword("$2a$10$hashed-password");
        user.setStatus((byte) 1);
        when(userService.getUserByPhone("13800138000")).thenReturn(user);
        when(userService.matchesPassword("wrong", "$2a$10$hashed-password")).thenReturn(false);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(phonePayload("13800138000", "wrong", null))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("phone or password error"));
    }

    @Test
    void sendSmsCodeReturnsDevCodeForExistingLoginUser() throws Exception {
        User user = new User();
        user.setPhone("13800138000");
        when(userService.getUserByPhone("13800138000")).thenReturn(user);
        when(verificationCodeService.generate("LOGIN", "13800138000")).thenReturn("135790");

        Map<String, Object> payload = new HashMap<>();
        payload.put("phone", "13800138000");
        payload.put("purpose", "LOGIN");

        mockMvc.perform(post("/api/auth/sms-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("verification code sent"))
                .andExpect(jsonPath("$.data.devCode").value("135790"));
    }

    @Test
    void sendRegisterSmsCodeRejectsExistingPhone() throws Exception {
        User existing = new User();
        existing.setPhone("13800138000");
        when(userService.getUserByPhone("13800138000")).thenReturn(existing);

        Map<String, Object> payload = new HashMap<>();
        payload.put("phone", "13800138000");
        payload.put("purpose", "REGISTER");

        mockMvc.perform(post("/api/auth/sms-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("phone already exists"));
    }

    @Test
    void smsLoginAcceptsVerificationCodeAndReturnsToken() throws Exception {
        User user = new User();
        user.setId(8L);
        user.setPhone("13800138008");
        user.setStatus((byte) 1);
        when(userService.getUserByPhone("13800138008")).thenReturn(user);
        when(verificationCodeService.consume("LOGIN", "13800138008", "135790")).thenReturn(true);
        when(tokenStore.createToken(8L)).thenReturn("sms-token");

        Map<String, Object> payload = new HashMap<>();
        payload.put("phone", "13800138008");
        payload.put("code", "135790");

        mockMvc.perform(post("/api/auth/sms-login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("login success"))
                .andExpect(jsonPath("$.data.token").value("sms-token"))
                .andExpect(jsonPath("$.data.user.phone").value("13800138008"));
    }

    @Test
    void identifyPasswordResetAccountReturnsMaskedPhone() throws Exception {
        User user = new User();
        user.setId(9L);
        user.setPhone("13800138009");
        when(userService.getUserByPhone("13800138009")).thenReturn(user);

        Map<String, Object> payload = new HashMap<>();
        payload.put("account", "13800138009");

        mockMvc.perform(post("/api/auth/password-reset/identify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("account verified"))
                .andExpect(jsonPath("$.data.phone").value("138****8009"));
    }

    @Test
    void identifyPasswordResetAccountAcceptsUsername() throws Exception {
        User user = new User();
        user.setId(10L);
        user.setUsername("doctorLi");
        user.setPhone("13900139010");
        when(userService.getUserByPhone("doctorLi")).thenReturn(null);
        when(userService.getUserByUsername("doctorLi")).thenReturn(user);

        Map<String, Object> payload = new HashMap<>();
        payload.put("account", "doctorLi");

        mockMvc.perform(post("/api/auth/password-reset/identify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("account verified"))
                .andExpect(jsonPath("$.data.phone").value("139****9010"))
                .andExpect(jsonPath("$.data.rawPhone").value("13900139010"));
    }

    @Test
    void passwordResetUpdatesPasswordAfterSmsCode() throws Exception {
        User user = new User();
        user.setId(9L);
        user.setPhone("13800138009");
        when(userService.getUserByPhone("13800138009")).thenReturn(user);
        when(verificationCodeService.consume("RESET_PASSWORD", "13800138009", "975310")).thenReturn(true);
        when(userService.resetPassword(9L, "newpass123")).thenReturn(1);

        Map<String, Object> payload = new HashMap<>();
        payload.put("phone", "13800138009");
        payload.put("code", "975310");
        payload.put("newPassword", "newpass123");

        mockMvc.perform(post("/api/auth/password-reset")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("password reset success"));

        verify(userService).resetPassword(9L, "newpass123");
    }

    @Test
    void meReturnsCurrentUserFromBearerToken() throws Exception {
        User user = new User();
        user.setId(2L);
        user.setPhone("13900139000");
        user.setRealName("Doctor Li");
        user.setStatus((byte) 1);
        Role doctorRole = new Role();
        doctorRole.setRoleCode("ADVISER");
        when(tokenStore.isValid("valid-token")).thenReturn(true);
        when(tokenStore.getUserId("valid-token")).thenReturn(2L);
        when(userService.getUserById(2L)).thenReturn(user);
        when(userService.getRolesByUserId(2L)).thenReturn(java.util.List.of(doctorRole));

        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer valid-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("session valid"))
                .andExpect(jsonPath("$.data.user.id").value(2))
                .andExpect(jsonPath("$.data.user.phone").value("13900139000"))
                .andExpect(jsonPath("$.data.user.password").doesNotExist())
                .andExpect(jsonPath("$.data.user.roles[0]").value("ADVISER"));
    }

    @Test
    void meRejectsMissingOrInvalidToken() throws Exception {
        mockMvc.perform(get("/api/auth/me"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("missing token"));

        when(tokenStore.isValid("bad-token")).thenReturn(false);
        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer bad-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("invalid token"));
    }

    private Map<String, Object> phonePayload(String phone, String password, String realName) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("phone", phone);
        payload.put("password", password);
        payload.put("code", "246810");
        if (realName != null) {
            payload.put("realName", realName);
        }
        return payload;
    }
}
