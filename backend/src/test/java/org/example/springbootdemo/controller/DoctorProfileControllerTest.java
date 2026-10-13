package org.example.springbootdemo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.bean.DoctorProfile;
import org.example.springbootdemo.service.DoctorProfileService;
import org.example.springbootdemo.support.AuthenticatedWebMvcTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(DoctorProfileController.class)
class DoctorProfileControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private DoctorProfileService doctorProfileService;

    @Test
    void getDoctorProfileByUserIdReturnsProfile() throws Exception {
        DoctorProfile profile = new DoctorProfile();
        profile.setId(1L);
        profile.setUserId(2L);
        profile.setDoctorName("王医生");
        profile.setTitle("主治医师");
        profile.setSpecialty("体质调理");
        profile.setIntroduction("擅长中医养生调理");
        when(doctorProfileService.getDoctorProfileByUserId(2L)).thenReturn(profile);

        mockMvc.perform(authGet("/api/doctor-profile").param("userId", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data.userId").value(2))
                .andExpect(jsonPath("$.data.doctorName").value("王医生"))
                .andExpect(jsonPath("$.data.specialty").value("体质调理"));
    }

    @Test
    void saveDoctorProfileCreatesOrUpdatesProfile() throws Exception {
        when(doctorProfileService.saveDoctorProfile(any(DoctorProfile.class))).thenReturn(1);

        Map<String, Object> payload = new HashMap<>();
        payload.put("userId", 2L);
        payload.put("doctorName", "王医生");
        payload.put("title", "主治医师");
        payload.put("specialty", "体质调理");
        payload.put("introduction", "擅长中医养生调理");

        mockMvc.perform(authPost("/api/doctor-profile")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("doctor profile saved"));
    }

    @Test
    void listDoctorProfilesReturnsAllDoctorProfiles() throws Exception {
        DoctorProfile profile = new DoctorProfile();
        profile.setId(1L);
        profile.setUserId(2L);
        profile.setDoctorName("Doctor Wang");
        profile.setTitle("Chief Doctor");
        profile.setSpecialty("Sleep care");
        when(doctorProfileService.listDoctorProfiles()).thenReturn(List.of(profile));

        mockMvc.perform(authGet("/api/doctor-profile/list"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data[0].id").value(1))
                .andExpect(jsonPath("$.data[0].userId").value(2))
                .andExpect(jsonPath("$.data[0].doctorName").value("Doctor Wang"))
                .andExpect(jsonPath("$.data[0].specialty").value("Sleep care"));
    }

    @Test
    void saveDoctorProfileRejectsUnauthorizedUser() throws Exception {
        when(permissionService.canManageDoctorProfile(any(), org.mockito.ArgumentMatchers.eq(99L))).thenReturn(false);

        Map<String, Object> payload = new HashMap<>();
        payload.put("userId", 99L);
        payload.put("doctorName", "Doctor Zhang");
        payload.put("specialty", "Sleep care");

        mockMvc.perform(authPost("/api/doctor-profile")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }
}
