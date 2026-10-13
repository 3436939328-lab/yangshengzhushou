package org.example.springbootdemo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.bean.Consultation;
import org.example.springbootdemo.bean.ConsultationMessage;
import org.example.springbootdemo.service.ConsultationService;
import org.example.springbootdemo.service.ConsultationMessageService;
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
import java.util.concurrent.atomic.AtomicReference;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ConsultationMessageController.class)
class ConsultationMessageControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ConsultationMessageService consultationMessageService;

    @MockBean
    private ConsultationService consultationService;

    @Test
    void sendConsultationMessageSavesMessage() throws Exception {
        Consultation consultation = consultation();
        AtomicReference<ConsultationMessage> savedMessage = new AtomicReference<>();
        when(consultationService.getConsultationById(5L)).thenReturn(consultation);
        when(permissionService.currentUserId(any())).thenReturn(2L);
        doAnswer(invocation -> {
            savedMessage.set(invocation.getArgument(0));
            return 1;
        }).when(consultationMessageService).addConsultationMessage(any(ConsultationMessage.class));

        Map<String, Object> payload = new HashMap<>();
        payload.put("consultationId", 5L);
        payload.put("senderId", 3L);
        payload.put("content", "医生您好，我最近睡眠不好。");

        mockMvc.perform(authPost("/api/consultation-message")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("consultation message created"));

        ConsultationMessage message = savedMessage.get();
        org.junit.jupiter.api.Assertions.assertNotNull(message);
        org.junit.jupiter.api.Assertions.assertEquals(2L, message.getSenderId());
        org.junit.jupiter.api.Assertions.assertEquals("DOCTOR", message.getSenderRole());
        verify(consultationService).markConsultationReplied(5L);
    }

    @Test
    void listConsultationMessagesReturnsMessagesByConsultationId() throws Exception {
        ConsultationMessage message = new ConsultationMessage();
        message.setId(1L);
        message.setConsultationId(5L);
        message.setSenderId(3L);
        message.setContent("医生您好，我最近睡眠不好。");
        when(consultationMessageService.listMessagesByConsultationId(5L)).thenReturn(List.of(message));

        mockMvc.perform(authGet("/api/consultation-message/list").param("consultationId", "5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data[0].id").value(1))
                .andExpect(jsonPath("$.data[0].consultationId").value(5))
                .andExpect(jsonPath("$.data[0].senderId").value(3))
                .andExpect(jsonPath("$.data[0].content").value("医生您好，我最近睡眠不好。"));
    }
    @Test
    void listConsultationMessagesRejectsNonParticipant() throws Exception {
        Consultation consultation = consultation();
        when(consultationService.getConsultationById(5L)).thenReturn(consultation);
        when(permissionService.canAccessConsultation(any(), org.mockito.ArgumentMatchers.eq(consultation))).thenReturn(false);

        mockMvc.perform(authGet("/api/consultation-message/list").param("consultationId", "5"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void sendConsultationMessageRejectsNonParticipant() throws Exception {
        Consultation consultation = consultation();
        when(consultationService.getConsultationById(5L)).thenReturn(consultation);
        when(permissionService.canAccessConsultation(any(), org.mockito.ArgumentMatchers.eq(consultation))).thenReturn(false);

        Map<String, Object> payload = new HashMap<>();
        payload.put("consultationId", 5L);
        payload.put("senderId", 3L);
        payload.put("content", "hello");

        mockMvc.perform(authPost("/api/consultation-message")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    private Consultation consultation() {
        Consultation consultation = new Consultation();
        consultation.setId(5L);
        consultation.setUserId(3L);
        consultation.setDoctorId(2L);
        return consultation;
    }
}
