package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.DoctorProfile;
import org.example.springbootdemo.service.DoctorProfileService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class DoctorProfileController {

    private final DoctorProfileService doctorProfileService;
    private final PermissionService permissionService;

    public DoctorProfileController(DoctorProfileService doctorProfileService, PermissionService permissionService) {
        this.doctorProfileService = doctorProfileService;
        this.permissionService = permissionService;
    }

    @GetMapping({"/doctor-profile", "/api/doctor-profile"})
    public Map<String, Object> getDoctorProfile(@RequestParam Long userId) {
        DoctorProfile profile = doctorProfileService.getDoctorProfileByUserId(userId);
        return response(profile != null, profile != null ? "query success" : "doctor profile not found", profile);
    }

    @GetMapping({"/doctor-profile/list", "/api/doctor-profile/list"})
    public Map<String, Object> listDoctorProfiles() {
        return response(true, "query success", doctorProfileService.listDoctorProfiles());
    }

    @PostMapping({"/doctor-profile", "/api/doctor-profile"})
    public ResponseEntity<Map<String, Object>> saveDoctorProfile(@RequestBody DoctorProfile doctorProfile, HttpServletRequest request) {
        if (doctorProfile.getUserId() == null) {
            return ResponseEntity.ok(response(false, "userId is required"));
        }
        if (!permissionService.canManageDoctorProfile(request, doctorProfile.getUserId())) {
            return forbidden();
        }
        if (isBlank(doctorProfile.getDoctorName())) {
            return ResponseEntity.ok(response(false, "doctorName is required"));
        }
        if (isBlank(doctorProfile.getSpecialty())) {
            return ResponseEntity.ok(response(false, "specialty is required"));
        }
        boolean saved = doctorProfileService.saveDoctorProfile(doctorProfile) > 0;
        return ResponseEntity.ok(response(saved, saved ? "doctor profile saved" : "save failed"));
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
