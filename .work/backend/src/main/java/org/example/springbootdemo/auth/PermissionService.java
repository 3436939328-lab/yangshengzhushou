package org.example.springbootdemo.auth;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.bean.Consultation;
import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.service.UserService;
import org.springframework.stereotype.Service;

@Service
public class PermissionService {

    private static final String ADMIN = "ADMIN";
    private static final String DOCTOR = "DOCTOR";
    private static final String ADVISER = "ADVISER";

    private final UserService userService;

    public PermissionService(UserService userService) {
        this.userService = userService;
    }

    public Long currentUserId(HttpServletRequest request) {
        Object value = request.getAttribute("currentUserId");
        return value instanceof Long ? (Long) value : null;
    }

    public boolean isAdmin(HttpServletRequest request) {
        return hasRole(request, ADMIN);
    }

    public boolean canAccessUser(HttpServletRequest request, Long userId) {
        Long currentUserId = currentUserId(request);
        return isAdmin(request) || (currentUserId != null && currentUserId.equals(userId));
    }

    public boolean canManageDoctorProfile(HttpServletRequest request, Long userId) {
        return isAdmin(request) || (canAccessUser(request, userId) && hasAnyRole(request, DOCTOR, ADVISER));
    }

    public boolean canAnswerHealthQuestion(HttpServletRequest request) {
        return isAdmin(request);
    }

    public boolean canListHealthQuestions(HttpServletRequest request, Long userId) {
        if (isAdmin(request)) {
            return true;
        }
        Long currentUserId = currentUserId(request);
        return currentUserId != null && currentUserId.equals(userId);
    }

    public boolean canAccessConsultationFilter(HttpServletRequest request, Long userId, Long doctorId) {
        if (isAdmin(request)) {
            return true;
        }
        Long currentUserId = currentUserId(request);
        if (currentUserId == null) {
            return false;
        }
        if (userId != null) {
            return currentUserId.equals(userId);
        }
        if (doctorId != null) {
            return currentUserId.equals(doctorId) && hasAnyRole(request, DOCTOR, ADVISER);
        }
        return false;
    }

    public boolean canCreateConsultation(HttpServletRequest request, Long userId) {
        return canAccessUser(request, userId);
    }

    public boolean canAccessConsultation(HttpServletRequest request, Consultation consultation) {
        if (consultation == null) {
            return false;
        }
        if (isAdmin(request)) {
            return true;
        }
        Long currentUserId = currentUserId(request);
        return currentUserId != null
                && (currentUserId.equals(consultation.getUserId()) || currentUserId.equals(consultation.getDoctorId()));
    }

    private boolean hasAnyRole(HttpServletRequest request, String... roleCodes) {
        for (String roleCode : roleCodes) {
            if (hasRole(request, roleCode)) {
                return true;
            }
        }
        return false;
    }

    private boolean hasRole(HttpServletRequest request, String roleCode) {
        Long currentUserId = currentUserId(request);
        if (currentUserId == null) {
            return false;
        }
        for (Role role : userService.getRolesByUserId(currentUserId)) {
            if (roleCode.equals(role.getRoleCode())) {
                return true;
            }
        }
        return false;
    }
}
