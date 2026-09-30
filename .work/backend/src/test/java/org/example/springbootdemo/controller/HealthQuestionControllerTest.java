package org.example.springbootdemo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.bean.HealthQuestion;
import org.example.springbootdemo.service.HealthQuestionAiService;
import org.example.springbootdemo.service.HealthQuestionService;
import org.example.springbootdemo.support.AuthenticatedWebMvcTest;
import org.junit.jupiter.api.Assertions;
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
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(HealthQuestionController.class)
class HealthQuestionControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private HealthQuestionService healthQuestionService;

    @MockBean
    private HealthQuestionAiService healthQuestionAiService;

    @Test
    void legacyGenerationIsRetiredWithoutCallingUnchargedAi() throws Exception {
        HealthQuestion generated = new HealthQuestion();
        generated.setId(1L);
        generated.setUserId(3L);
        generated.setQuestion("最近睡眠不好怎么办");
        generated.setAnswer("建议规律作息");
        generated.setStatus((byte) 1);
        when(healthQuestionAiService.askQuestion(any(HealthQuestion.class))).thenReturn(generated);

        Map<String, Object> payload = new HashMap<>();
        payload.put("userId", 3L);
        payload.put("question", "最近睡眠不好怎么办");

        mockMvc.perform(authPost("/api/health-question")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isGone())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Use /api/ai/chat with a requestId; legacy AI generation is retired"));
        org.mockito.Mockito.verify(healthQuestionAiService, org.mockito.Mockito.never()).askQuestion(any());
    }

    @Test
    void createHealthQuestionRejectsOtherUserId() throws Exception {
        when(permissionService.canAccessUser(any(), org.mockito.ArgumentMatchers.eq(99L))).thenReturn(false);

        Map<String, Object> payload = new HashMap<>();
        payload.put("userId", 99L);
        payload.put("question", "sleep problem");

        mockMvc.perform(authPost("/api/health-question")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void listHealthQuestionsReturnsQuestionRecords() throws Exception {
        HealthQuestion question = new HealthQuestion();
        question.setId(1L);
        question.setUserId(3L);
        question.setQuestion("最近睡眠不好怎么办");
        question.setAnswer("建议保持规律作息，睡前减少电子屏幕使用。");
        question.setStatus((byte) 1);
        when(healthQuestionService.listHealthQuestions()).thenReturn(List.of(question));

        mockMvc.perform(authGet("/api/health-question/list"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data[0].id").value(1))
                .andExpect(jsonPath("$.data[0].userId").value(3))
                .andExpect(jsonPath("$.data[0].question").value("最近睡眠不好怎么办"))
                .andExpect(jsonPath("$.data[0].answer").value("建议保持规律作息，睡前减少电子屏幕使用。"))
                .andExpect(jsonPath("$.data[0].status").value(1));
    }

    @Test
    void listHealthQuestionsCanFilterByUserId() throws Exception {
        when(healthQuestionService.listHealthQuestions(3L)).thenReturn(List.of());

        mockMvc.perform(authGet("/api/health-question/list").param("userId", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(healthQuestionService).listHealthQuestions(3L);
    }

    @Test
    void listHealthQuestionsDefaultsToCurrentUserWhenUserIdIsMissingForNormalUser() throws Exception {
        HealthQuestion question = new HealthQuestion();
        question.setId(2L);
        question.setUserId(3L);
        question.setQuestion("sleep problem");
        question.setAnswer("sleep early");
        question.setStatus((byte) 1);

        when(permissionService.isAdmin(any())).thenReturn(false);
        when(permissionService.currentUserId(any())).thenReturn(3L);
        when(permissionService.canListHealthQuestions(any(), isNull())).thenReturn(false);
        when(permissionService.canListHealthQuestions(any(), eq(3L))).thenReturn(true);
        when(healthQuestionService.listHealthQuestions(3L)).thenReturn(List.of(question));

        mockMvc.perform(authGet("/api/health-question/list"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(2))
                .andExpect(jsonPath("$.data[0].userId").value(3));

        verify(healthQuestionService).listHealthQuestions(3L);
    }

    @Test
    void listHealthQuestionsRejectsListingAllWhenPermissionDenied() throws Exception {
        when(permissionService.canListHealthQuestions(any(), isNull())).thenReturn(false);

        mockMvc.perform(authGet("/api/health-question/list"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void listHealthQuestionsRejectsOtherUserFilterWhenPermissionDenied() throws Exception {
        when(permissionService.canListHealthQuestions(any(), org.mockito.ArgumentMatchers.eq(99L))).thenReturn(false);

        mockMvc.perform(authGet("/api/health-question/list").param("userId", "99"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void answerHealthQuestionSavesAnswerAndMarksAnswered() throws Exception {
        when(healthQuestionService.answerHealthQuestion(any(HealthQuestion.class))).thenReturn(1);

        Map<String, Object> payload = new HashMap<>();
        payload.put("id", 1L);
        payload.put("answer", "sleep early");

        mockMvc.perform(authPost("/api/health-question/answer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("health question answered"));

        verify(healthQuestionService).answerHealthQuestion(argThat(question -> {
            Assertions.assertEquals(1L, question.getId());
            Assertions.assertEquals("sleep early", question.getAnswer());
            Assertions.assertEquals((byte) 1, question.getStatus());
            return true;
        }));
    }

    @Test
    void answerHealthQuestionRejectsUserWithoutAnswerPermission() throws Exception {
        when(permissionService.canAnswerHealthQuestion(any())).thenReturn(false);

        Map<String, Object> payload = new HashMap<>();
        payload.put("id", 1L);
        payload.put("answer", "sleep early");

        mockMvc.perform(authPost("/api/health-question/answer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }
}
