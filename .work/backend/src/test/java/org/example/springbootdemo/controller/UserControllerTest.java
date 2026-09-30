package org.example.springbootdemo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.bean.User;
import org.example.springbootdemo.service.UserService;
import org.example.springbootdemo.support.AuthenticatedWebMvcTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(UserController.class)
class UserControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private UserService userService;

    @Test
    void listUsersReturnsUsersWithoutPasswords() throws Exception {
        User user = new User();
        user.setId(1L);
        user.setUsername("admin");
        user.setPassword("secret");
        user.setRealName("Admin");
        user.setPhone("13800138000");
        user.setStatus((byte) 1);
        Role userRole = new Role();
        userRole.setRoleCode("USER");
        Role doctorRole = new Role();
        doctorRole.setRoleCode("DOCTOR");
        when(userService.listUsers()).thenReturn(List.of(user));
        when(userService.getRolesByUserId(1L)).thenReturn(List.of(userRole, doctorRole));

        mockMvc.perform(authGet("/api/user/list"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data[0].id").value(1))
                .andExpect(jsonPath("$.data[0].username").value("admin"))
                .andExpect(jsonPath("$.data[0].phone").value("13800138000"))
                .andExpect(jsonPath("$.data[0].roles[0]").value("USER"))
                .andExpect(jsonPath("$.data[0].roles[1]").value("DOCTOR"))
                .andExpect(jsonPath("$.data[0].password").doesNotExist());
    }

    @Test
    void listUsersRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(authGet("/api/user/list"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void profileRejectsOtherUserId() throws Exception {
        when(permissionService.canAccessUser(any(), org.mockito.ArgumentMatchers.eq(99L))).thenReturn(false);

        mockMvc.perform(authGet("/api/user/profile").param("id", "99"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void profileReturnsSafeUserWithoutPassword() throws Exception {
        User user = new User();
        user.setId(3L);
        user.setUsername("user3");
        user.setPassword("secret");
        user.setEmail("user3@example.com");

        when(userService.getUserById(3L)).thenReturn(user);

        mockMvc.perform(authGet("/api/user/profile").param("id", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(3))
                .andExpect(jsonPath("$.data.email").value("user3@example.com"))
                .andExpect(jsonPath("$.data.password").doesNotExist());
    }

    @Test
    void updateProfileRejectsOtherUserId() throws Exception {
        when(permissionService.canAccessUser(any(), org.mockito.ArgumentMatchers.eq(99L))).thenReturn(false);

        User user = new User();
        user.setId(99L);
        user.setRealName("Other User");

        mockMvc.perform(authPut("/api/user/profile")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(user)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void updateProfileReturnsSavedAvatar() throws Exception {
        User user = new User();
        user.setId(3L);
        user.setRealName("Updated User");
        user.setPhone("13800138002");
        user.setAvatar("data:image/png;base64,avatar");

        User saved = new User();
        saved.setId(3L);
        saved.setUsername("user3");
        saved.setRealName("Updated User");
        saved.setPhone("13800138002");
        saved.setAvatar("data:image/png;base64,avatar");

        when(userService.updateUser(any(User.class))).thenReturn(1);
        when(userService.getUserById(3L)).thenReturn(saved);

        mockMvc.perform(authPut("/api/user/profile")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("profile updated"))
                .andExpect(jsonPath("$.data.id").value(3))
                .andExpect(jsonPath("$.data.avatar").value("data:image/png;base64,avatar"))
                .andExpect(jsonPath("$.data.password").doesNotExist());
    }

    @Test
    void addUserRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        User user = new User();
        user.setUsername("newuser");
        user.setPhone("13800138001");

        mockMvc.perform(authPost("/api/user")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(user)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));

        verify(userService, never()).addUser(any(User.class));
    }
    @Test
    void serviceFailureReturnsSafeJsonError() throws Exception {
        when(userService.listUsers()).thenThrow(new RuntimeException("database password leaked"));

        mockMvc.perform(authGet("/api/user/list"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("服务器异常，请稍后重试"))
                .andExpect(jsonPath("$.trace").doesNotExist())
                .andExpect(jsonPath("$.exception").doesNotExist());
    }

    @Test
    void malformedJsonReturnsUnifiedBadRequest() throws Exception {
        mockMvc.perform(authPost("/api/user")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{bad json"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("请求参数格式错误"))
                .andExpect(jsonPath("$.trace").doesNotExist());
    }
}
