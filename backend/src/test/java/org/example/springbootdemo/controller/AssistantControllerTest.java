package org.example.springbootdemo.controller;

import org.example.springbootdemo.ai.AssistantChatReply;
import org.example.springbootdemo.ai.AssistantSuggestionReply;
import org.example.springbootdemo.ai.NodeAiStatusReply;
import org.example.springbootdemo.bean.HealthQuestion;
import org.example.springbootdemo.service.AssistantChatService;
import org.example.springbootdemo.service.AssistantSuggestionService;
import org.example.springbootdemo.service.HealthQuestionService;
import org.example.springbootdemo.service.NodeAiStatusService;
import org.example.springbootdemo.support.AuthenticatedWebMvcTest;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AssistantController.class)
@Import(org.example.springbootdemo.service.AiRateLimitService.class)
class AssistantControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AssistantChatService assistantChatService;

    @MockBean
    private AssistantSuggestionService assistantSuggestionService;

    @MockBean
    private HealthQuestionService healthQuestionService;

    @MockBean
    private NodeAiStatusService nodeAiStatusService;

    @MockBean private org.example.springbootdemo.rewards.RewardsService rewards;
    @MockBean private org.example.springbootdemo.ai.AiProviderStatus providerStatus;
    @MockBean private org.example.springbootdemo.ai.HealthQuestionAiProperties aiProperties;

    @org.junit.jupiter.api.BeforeEach
    void setupRewards() {
        when(rewards.reserveChat(any(), any(), any())).thenReturn(Map.of("status", "NEW"));
    }

    @Test
    void appChatEndpointReturnsNodeStylePayload() throws Exception {
        when(assistantChatService.chat(any(), any())).thenReturn(
                new AssistantChatReply(
                        "Keep a steady routine",
                        "NodeLangGraph",
                        "normal",
                        List.of("Sleep at a fixed time"),
                        List.of(),
                        "This advice cannot replace medical diagnosis."
                )
        );

        mockMvc.perform(authPost("/api/ai/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"message":"sleep problem","profile":{},"weather":{},"history":[]}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reply").value("Keep a steady routine"))
                .andExpect(jsonPath("$.source").value("NodeLangGraph"));
    }

    @Test
    void failedModelReleasesReservationAndDoesNotStoreAnAnswer() throws Exception {
        when(assistantChatService.chat(any(), any())).thenThrow(new IllegalStateException("provider down"));
        mockMvc.perform(authPost("/api/ai/chat").contentType(MediaType.APPLICATION_JSON)
            .content("{\"requestId\":\"failure-test\",\"message\":\"question\"}"))
            .andExpect(status().isServiceUnavailable());
        verify(rewards).failChat(any(), org.mockito.ArgumentMatchers.eq("failure-test"), any());
        verify(rewards, never()).completeChat(any(), any(), any());
        verify(healthQuestionService, never()).answerHealthQuestion(any());
    }

    @Test
    void appChatEndpointPersistsQuestionAndAnswerForCurrentUser() throws Exception {
        when(tokenStore.getUserId("test-token")).thenReturn(3L);
        when(assistantChatService.chat(any(), any())).thenReturn(
                new AssistantChatReply(
                        "Keep a steady routine",
                        "NodeLangGraph",
                        "normal",
                        List.of("Sleep at a fixed time"),
                        List.of(),
                        "This advice cannot replace medical diagnosis."
                )
        );
        doAnswer(invocation -> {
            HealthQuestion question = invocation.getArgument(0);
            question.setId(99L);
            return 1;
        }).when(healthQuestionService).addHealthQuestion(any(HealthQuestion.class));

        mockMvc.perform(authPost("/api/ai/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"message":"sleep problem","profile":{},"weather":{},"history":[]}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reply").value("Keep a steady routine"));

        ArgumentCaptor<HealthQuestion> addedCaptor = ArgumentCaptor.forClass(HealthQuestion.class);
        ArgumentCaptor<HealthQuestion> answeredCaptor = ArgumentCaptor.forClass(HealthQuestion.class);
        verify(healthQuestionService).addHealthQuestion(addedCaptor.capture());
        verify(healthQuestionService).answerHealthQuestion(answeredCaptor.capture());
        org.junit.jupiter.api.Assertions.assertEquals(3L, addedCaptor.getValue().getUserId());
        org.junit.jupiter.api.Assertions.assertEquals("sleep problem", addedCaptor.getValue().getQuestion());
        org.junit.jupiter.api.Assertions.assertEquals((byte) 0, addedCaptor.getValue().getStatus());
        org.junit.jupiter.api.Assertions.assertEquals(99L, answeredCaptor.getValue().getId());
        org.junit.jupiter.api.Assertions.assertEquals("Keep a steady routine", answeredCaptor.getValue().getAnswer());
    }


    @Test
    void chatRejectsMessageLongerThanLimitBeforeCallingAi() throws Exception {
        String longMessage = "a".repeat(1001);

        mockMvc.perform(authPost("/api/ai/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"message":"%s","profile":{},"weather":{},"history":[]}
                                """.formatted(longMessage)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("AI问题不能超过1000字"));

        verify(assistantChatService, never()).chat(any(), any());
        verify(healthQuestionService, never()).addHealthQuestion(any(HealthQuestion.class));
    }

    @Test
    void chatRateLimitsCurrentUserBeforeCallingAi() throws Exception {
        when(tokenStore.getUserId("test-token")).thenReturn(7L);
        when(assistantChatService.chat(any(), any())).thenReturn(
                new AssistantChatReply(
                        "ok",
                        "NodeLangGraph",
                        "normal",
                        List.of(),
                        List.of(),
                        "This advice cannot replace medical diagnosis."
                )
        );

        for (int index = 0; index < 5; index++) {
            mockMvc.perform(authPost("/api/ai/chat")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"message":"sleep problem","profile":{},"weather":{},"history":[]}
                                    """))
                    .andExpect(status().isOk());
        }

        mockMvc.perform(authPost("/api/ai/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"message":"sleep problem","profile":{},"weather":{},"history":[]}
                                """))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("AI请求过于频繁，请稍后再试"));
    }

    @Test
    void suggestionsRateLimitsCurrentUserBeforeCallingAi() throws Exception {
        when(tokenStore.getUserId("test-token")).thenReturn(8L);
        when(assistantSuggestionService.suggest(any())).thenReturn(
                new AssistantSuggestionReply(
                        "NodeLangGraph",
                        "normal",
                        "home",
                        "Eat lightly today.",
                        List.of(),
                        List.of(),
                        "This advice cannot replace medical diagnosis."
                )
        );

        for (int index = 0; index < 5; index++) {
            mockMvc.perform(authPost("/api/ai/suggestions")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"scenario":"home","weather":{},"profile":{}}
                                    """))
                    .andExpect(status().isOk());
        }

        mockMvc.perform(authPost("/api/ai/suggestions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"scenario":"home","weather":{},"profile":{}}
                                """))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("AI请求过于频繁，请稍后再试"));

        verify(assistantSuggestionService, times(5)).suggest(any());
    }
    @Test
    void sceneSuggestionEndpointReturnsSummaryAndPlans() throws Exception {
        when(assistantSuggestionService.suggest(any())).thenReturn(
                new AssistantSuggestionReply(
                        "LocalRagLlm",
                        "normal",
                        "home",
                        "Eat lightly today.",
                        List.of("Eat lightly"),
                        List.of(Map.of("timeOfDay", "morning", "title", "Light breakfast")),
                        "This advice cannot replace medical diagnosis.",
                        List.of(Map.of(
                                "chunkId", 12L,
                                "title", "Qi deficiency and fatigue wellness tips",
                                "documentTitle", "TCM constitution and daily wellness basics",
                                "retrievalType", "KEYWORD",
                                "score", 0.8
                        )),
                        "KEYWORD_ONLY"
                )
        );

        mockMvc.perform(authPost("/api/ai/suggestions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"scenario":"home","weather":{},"profile":{}}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.source").value("LocalRagLlm"))
                .andExpect(jsonPath("$.scenario").value("home"))
                .andExpect(jsonPath("$.summary").value("Eat lightly today."))
                .andExpect(jsonPath("$.plans[0].title").value("Light breakfast"))
                .andExpect(jsonPath("$.references[0].chunkId").value(12))
                .andExpect(jsonPath("$.retrievalStatus").value("KEYWORD_ONLY"));
    }

    @Test
    void suggestionsReturnsUnavailableWhenRagServiceFails() throws Exception {
        when(assistantSuggestionService.suggest(any())).thenThrow(
                new org.example.springbootdemo.rag.RagSuggestionUnavailableException("local LLM unavailable")
        );

        mockMvc.perform(authPost("/api/ai/suggestions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"scenario":"home","weather":{},"profile":{}}
                                """))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("local LLM unavailable"));
    }

    @Test
    void aiStatusEndpointReturnsNodeEngineStatus() throws Exception {
        when(providerStatus.snapshot(any())).thenReturn(Map.of("provider","deepseek","model","deepseek-chat","configured",false,"status","not_configured"));
        when(nodeAiStatusService.status()).thenReturn(
                new NodeAiStatusReply(
                        true,
                        "node-ai",
                        "ok",
                        "http://127.0.0.1:8787",
                        "Node AI engine is available."
                )
        );

        mockMvc.perform(authGet("/api/ai/status"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.provider").value("deepseek"))
                .andExpect(jsonPath("$.configured").value(false))
                .andExpect(jsonPath("$.status").value("not_configured"));
    }
}

