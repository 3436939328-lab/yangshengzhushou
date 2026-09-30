package org.example.springbootdemo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.bean.Consultation;
import org.example.springbootdemo.service.ConsultationService;
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
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ConsultationController.class)
class ConsultationControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ConsultationService consultationService;

    @Test
    void createConsultationSavesUserDoctorConsultation() throws Exception {
        when(consultationService.addConsultation(any(Consultation.class))).thenReturn(1);

        Map<String, Object> payload = new HashMap<>();
        payload.put("userId", 3L);
        payload.put("doctorId", 2L);
        payload.put("symptom", "头晕乏力");
        payload.put("description", "最近一周精神差");

        mockMvc.perform(authPost("/api/consultation")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("consultation created"))
                .andExpect(jsonPath("$.data.userId").value(3))
                .andExpect(jsonPath("$.data.doctorId").value(2));
    }

    @Test
    void createConsultationRejectsOtherUserId() throws Exception {
        when(permissionService.canCreateConsultation(any(), org.mockito.ArgumentMatchers.eq(99L))).thenReturn(false);

        Map<String, Object> payload = new HashMap<>();
        payload.put("userId", 99L);
        payload.put("doctorId", 2L);
        payload.put("symptom", "sleep problem");
        payload.put("description", "cannot sleep recently");

        mockMvc.perform(authPost("/api/consultation")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void listConsultationsReturnsConsultationRecords() throws Exception {
        Consultation consultation = new Consultation();
        consultation.setId(1L);
        consultation.setUserId(3L);
        consultation.setDoctorId(2L);
        consultation.setSymptom("头晕乏力");
        consultation.setDescription("最近一周精神差");
        consultation.setStatus((byte) 0);
        when(consultationService.listConsultations()).thenReturn(List.of(consultation));

        mockMvc.perform(authGet("/api/consultation/list"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data[0].id").value(1))
                .andExpect(jsonPath("$.data[0].userId").value(3))
                .andExpect(jsonPath("$.data[0].doctorId").value(2))
                .andExpect(jsonPath("$.data[0].symptom").value("头晕乏力"))
                .andExpect(jsonPath("$.data[0].description").value("最近一周精神差"))
                .andExpect(jsonPath("$.data[0].status").value(0));
    }

    @Test
    void listConsultationsCanFilterByUserAndDoctor() throws Exception {
        when(consultationService.listConsultations(3L, 2L)).thenReturn(List.of());

        mockMvc.perform(authGet("/api/consultation/list")
                        .param("userId", "3")
                        .param("doctorId", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(consultationService).listConsultations(3L, 2L);
    }

    @Test
    void listConsultationsRejectsUnauthorizedFilter() throws Exception {
        when(permissionService.canAccessConsultationFilter(any(), org.mockito.ArgumentMatchers.eq(99L), org.mockito.ArgumentMatchers.eq(2L))).thenReturn(false);

        mockMvc.perform(authGet("/api/consultation/list")
                        .param("userId", "99")
                        .param("doctorId", "2"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void detailReturnsAccessibleConsultation() throws Exception {
        Consultation consultation = new Consultation();
        consultation.setId(9L);
        consultation.setUserId(3L);
        consultation.setDoctorId(2L);
        consultation.setTitle("睡眠咨询");
        consultation.setStatus((byte) 0);

        when(consultationService.getConsultationById(9L)).thenReturn(consultation);
        when(permissionService.canAccessConsultation(any(), eq(consultation))).thenReturn(true);

        mockMvc.perform(authGet("/api/consultation/detail").param("id", "9"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data.id").value(9))
                .andExpect(jsonPath("$.data.title").value("睡眠咨询"));
    }

    @Test
    void detailRejectsUnauthorizedConsultation() throws Exception {
        Consultation consultation = new Consultation();
        consultation.setId(9L);
        consultation.setUserId(99L);
        consultation.setDoctorId(2L);

        when(consultationService.getConsultationById(9L)).thenReturn(consultation);
        when(permissionService.canAccessConsultation(any(), eq(consultation))).thenReturn(false);

        mockMvc.perform(authGet("/api/consultation/detail").param("id", "9"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void updateStatusAllowsAssignedDoctor() throws Exception {
        Consultation consultation = new Consultation();
        consultation.setId(9L);
        consultation.setUserId(3L);
        consultation.setDoctorId(2L);
        consultation.setStatus((byte) 0);

        when(consultationService.getConsultationById(9L)).thenReturn(consultation);
        when(permissionService.currentUserId(any())).thenReturn(2L);
        when(consultationService.updateConsultationStatus(9L, (byte) 1)).thenReturn(1);

        Map<String, Object> payload = new HashMap<>();
        payload.put("id", 9L);
        payload.put("status", 1);

        mockMvc.perform(authPut("/api/consultation/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("status updated"));

        verify(consultationService).updateConsultationStatus(9L, (byte) 1);
    }
}
