package org.example.springbootdemo.controller;

import org.example.springbootdemo.bean.UserRole;
import org.example.springbootdemo.service.UserRoleService;
import org.example.springbootdemo.support.AuthenticatedWebMvcTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(UserRoleController.class)
class UserRoleControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserRoleService userRoleService;

    @Test
    void listUserRolesReturnsUserRoleRelations() throws Exception {
        UserRole userRole = new UserRole();
        userRole.setId(1L);
        userRole.setUserId(10L);
        userRole.setRoleId(2L);
        when(userRoleService.listUserRoles()).thenReturn(List.of(userRole));

        mockMvc.perform(authGet("/api/user-role/list"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data[0].id").value(1))
                .andExpect(jsonPath("$.data[0].userId").value(10))
                .andExpect(jsonPath("$.data[0].roleId").value(2));
    }

    @Test
    void listUserRolesRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(authGet("/api/user-role/list"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void userRoleDetailRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(authGet("/api/user-role").param("id", "1"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void addUserRoleRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(authPost("/api/user-role")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":10,\"roleId\":2}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void updateUserRoleRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(authPut("/api/user-role")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"id\":1,\"userId\":10,\"roleId\":2}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void deleteUserRoleRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(delete("/api/user-role")
                        .header("Authorization", "Bearer test-token")
                        .param("id", "1"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }
}