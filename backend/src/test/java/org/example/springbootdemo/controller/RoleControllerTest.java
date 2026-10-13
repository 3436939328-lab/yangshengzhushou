package org.example.springbootdemo.controller;

import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.service.RoleService;
import org.example.springbootdemo.support.AuthenticatedWebMvcTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(RoleController.class)
class RoleControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private RoleService roleService;

    @Test
    void listRolesReturnsRoles() throws Exception {
        Role role = new Role();
        role.setId(1L);
        role.setRoleName("Admin");
        role.setRoleCode("ADMIN");
        when(roleService.listRoles()).thenReturn(List.of(role));

        mockMvc.perform(authGet("/api/role/list"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data[0].id").value(1))
                .andExpect(jsonPath("$.data[0].roleName").value("Admin"))
                .andExpect(jsonPath("$.data[0].roleCode").value("ADMIN"));
    }

    @Test
    void listRolesRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(authGet("/api/role/list"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void roleDetailRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(authGet("/api/role").param("id", "1"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void addRoleRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(authPost("/api/role")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"roleName\":\"Doctor\",\"roleCode\":\"DOCTOR\"}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void updateRoleRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(authPut("/api/role")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"id\":1,\"roleName\":\"Doctor\"}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void deleteRoleRejectsNonAdminUser() throws Exception {
        when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(delete("/api/role")
                        .header("Authorization", "Bearer test-token")
                        .param("id", "1"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void deleteRoleRemovesRoleAndAssignments() throws Exception {
        when(roleService.deleteRole(7L)).thenReturn(1);

        mockMvc.perform(delete("/api/role")
                        .header("Authorization", "Bearer test-token")
                        .param("id", "7"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("role deleted"));

        verify(roleService).deleteRole(7L);
    }
}
