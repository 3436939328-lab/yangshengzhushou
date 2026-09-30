package org.example.springbootdemo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.bean.HealthDetailBundle;
import org.example.springbootdemo.bean.HealthIndicatorRecord;
import org.example.springbootdemo.bean.HealthQuestionnaireRecord;
import org.example.springbootdemo.bean.TongueObservationRecord;
import org.example.springbootdemo.service.HealthDetailService;
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
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(HealthDetailController.class)
class HealthDetailControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private HealthDetailService healthDetailService;

    @Test
    void getCurrentHealthDetailsReturnsThreeRecordLists() throws Exception {
        when(permissionService.currentUserId(any())).thenReturn(3L);
        HealthQuestionnaireRecord questionnaire = new HealthQuestionnaireRecord();
        questionnaire.setId(1L);
        questionnaire.setUserId(3L);
        questionnaire.setConstitutionType("气虚质");
        questionnaire.setTotalScore(11);
        questionnaire.setSuggestion("温和运动");
        HealthIndicatorRecord indicator = new HealthIndicatorRecord();
        indicator.setId(2L);
        indicator.setUserId(3L);
        indicator.setName("血压");
        indicator.setValue("128/82");
        indicator.setUnit("mmHg");
        TongueObservationRecord tongue = new TongueObservationRecord();
        tongue.setId(3L);
        tongue.setUserId(3L);
        tongue.setColor("淡红");
        tongue.setCoating("薄白");
        tongue.setDryness("适中");
        tongue.setNote("晨起观察");
        when(healthDetailService.getDetailsByUserId(3L)).thenReturn(new HealthDetailBundle(
                List.of(questionnaire),
                List.of(indicator),
                List.of(tongue)
        ));

        mockMvc.perform(authGet("/api/health-detail/current"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.questionnaireRecords[0].constitutionType").value("气虚质"))
                .andExpect(jsonPath("$.data.healthIndicators[0].name").value("血压"))
                .andExpect(jsonPath("$.data.tongueNotes[0].color").value("淡红"));
    }

    @Test
    void addCurrentHealthIndicatorUsesCurrentUser() throws Exception {
        when(permissionService.currentUserId(any())).thenReturn(3L);
        AtomicReference<HealthIndicatorRecord> savedRecord = new AtomicReference<>();
        when(healthDetailService.addHealthIndicator(any(HealthIndicatorRecord.class))).thenAnswer(invocation -> {
            HealthIndicatorRecord record = invocation.getArgument(0);
            record.setId(9L);
            savedRecord.set(record);
            return record;
        });
        Map<String, Object> payload = new HashMap<>();
        payload.put("name", "血压");
        payload.put("value", "128/82");
        payload.put("unit", "mmHg");
        payload.put("recordedAt", "2026-06-26T10:30:00.000Z");

        mockMvc.perform(authPost("/api/health-detail/indicator")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(9))
                .andExpect(jsonPath("$.data.userId").value(3));

        org.junit.jupiter.api.Assertions.assertEquals(3L, savedRecord.get().getUserId());
    }
}
