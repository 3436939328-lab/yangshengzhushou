package org.example.springbootdemo.auth;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.bean.Consultation;
import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.service.UserService;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class PermissionServiceTest {

    private final UserService userService = mock(UserService.class);
    private final HttpServletRequest request = mock(HttpServletRequest.class);
    private final PermissionService permissionService = new PermissionService(userService);

    @Test
    void adminCanAccessAdminData() {
        when(request.getAttribute("currentUserId")).thenReturn(1L);
        when(userService.getRolesByUserId(1L)).thenReturn(List.of(role("ADMIN")));

        assertTrue(permissionService.isAdmin(request));
        assertTrue(permissionService.canAccessUser(request, 99L));
        assertTrue(permissionService.canAccessConsultationFilter(request, null, null));
        assertTrue(permissionService.canListHealthQuestions(request, null));
        assertTrue(permissionService.canAnswerHealthQuestion(request));
    }

    @Test
    void userCanOnlyAccessOwnUserData() {
        when(request.getAttribute("currentUserId")).thenReturn(3L);
        when(userService.getRolesByUserId(3L)).thenReturn(List.of(role("USER")));

        assertTrue(permissionService.canAccessUser(request, 3L));
        assertFalse(permissionService.canAccessUser(request, 99L));
        assertFalse(permissionService.canAccessConsultationFilter(request, null, null));
        assertTrue(permissionService.canListHealthQuestions(request, 3L));
        assertFalse(permissionService.canListHealthQuestions(request, null));
        assertFalse(permissionService.canAnswerHealthQuestion(request));
    }

    @Test
    void doctorCanManageOwnDoctorProfileAndOwnConsultations() {
        when(request.getAttribute("currentUserId")).thenReturn(2L);
        when(userService.getRolesByUserId(2L)).thenReturn(List.of(role("DOCTOR")));

        assertTrue(permissionService.canManageDoctorProfile(request, 2L));
        assertTrue(permissionService.canAccessConsultationFilter(request, null, 2L));
        assertFalse(permissionService.canManageDoctorProfile(request, 99L));
        assertFalse(permissionService.canListHealthQuestions(request, null));
        assertFalse(permissionService.canAnswerHealthQuestion(request));
    }

    @Test
    void consultationAccessAllowsOnlyParticipantOrAdmin() {
        Consultation consultation = new Consultation();
        consultation.setUserId(3L);
        consultation.setDoctorId(2L);

        when(request.getAttribute("currentUserId")).thenReturn(3L);
        when(userService.getRolesByUserId(3L)).thenReturn(List.of(role("USER")));
        assertTrue(permissionService.canAccessConsultation(request, consultation));

        when(request.getAttribute("currentUserId")).thenReturn(99L);
        when(userService.getRolesByUserId(99L)).thenReturn(List.of(role("USER")));
        assertFalse(permissionService.canAccessConsultation(request, consultation));
    }

    private Role role(String roleCode) {
        Role role = new Role();
        role.setRoleCode(roleCode);
        return role;
    }
}
