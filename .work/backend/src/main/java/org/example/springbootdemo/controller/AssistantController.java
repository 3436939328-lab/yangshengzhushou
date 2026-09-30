package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.ai.AssistantChatReply;
import org.example.springbootdemo.ai.AssistantChatRequest;
import org.example.springbootdemo.ai.AssistantSuggestionReply;
import org.example.springbootdemo.ai.AssistantSuggestionRequest;
import org.example.springbootdemo.bean.HealthQuestion;
import org.example.springbootdemo.rag.RagSuggestionUnavailableException;
import org.example.springbootdemo.service.AiRateLimitService;
import org.example.springbootdemo.service.AssistantChatService;
import org.example.springbootdemo.service.AssistantSuggestionService;
import org.example.springbootdemo.service.HealthQuestionService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class AssistantController {

    private static final int MAX_CHAT_MESSAGE_LENGTH = 1000;

    private final AssistantChatService assistantChatService;
    private final AssistantSuggestionService assistantSuggestionService;
    private final AiRateLimitService aiRateLimitService;
    private final HealthQuestionService healthQuestionService;
    private final org.example.springbootdemo.rewards.RewardsService rewards;
    private final com.fasterxml.jackson.databind.ObjectMapper mapper;
    private final org.example.springbootdemo.ai.AiProviderStatus providerStatus;
    private final org.example.springbootdemo.ai.HealthQuestionAiProperties aiProperties;

    public AssistantController(
            AssistantChatService assistantChatService,
            AssistantSuggestionService assistantSuggestionService,
            AiRateLimitService aiRateLimitService,
            HealthQuestionService healthQuestionService,
            org.example.springbootdemo.rewards.RewardsService rewards,
            com.fasterxml.jackson.databind.ObjectMapper mapper,
            org.example.springbootdemo.ai.AiProviderStatus providerStatus,
            org.example.springbootdemo.ai.HealthQuestionAiProperties aiProperties
    ) {
        this.assistantChatService = assistantChatService;
        this.assistantSuggestionService = assistantSuggestionService;
        this.aiRateLimitService = aiRateLimitService;
        this.healthQuestionService = healthQuestionService;
        this.rewards = rewards;
        this.mapper = mapper;
        this.providerStatus = providerStatus;
        this.aiProperties = aiProperties;
    }

    @PostMapping({"/api/ai/chat", "/api/assistant/chat"})
    public ResponseEntity<?> chat(@RequestBody AssistantChatRequest request, HttpServletRequest servletRequest) {
        Long userId = currentUserId(servletRequest);
        if (request != null && request.message() != null && request.message().length() > MAX_CHAT_MESSAGE_LENGTH) {
            return error(HttpStatus.BAD_REQUEST, "AI问题不能超过1000字");
        }
        if(request == null || isBlank(request.message())) return error(HttpStatus.BAD_REQUEST,"Message is required");
        if(userId == null) return error(HttpStatus.UNAUTHORIZED,"Please sign in");
        String hash;
        try {
            byte[] bytes = mapper.writeValueAsBytes(request);
            hash = java.util.HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch(Exception exception) { return error(HttpStatus.BAD_REQUEST,"Invalid request"); }
        Map<String,Object> reservation = rewards.reserveChat(userId,request.requestId(),hash);
        if("SUCCEEDED".equals(reservation.get("status"))) return ResponseEntity.ok(reservation.get("reply"));
        if("PENDING".equals(reservation.get("status"))) return error(HttpStatus.CONFLICT,"Request is still processing");
        if("FAILED".equals(reservation.get("status"))) return error(HttpStatus.SERVICE_UNAVAILABLE,String.valueOf(reservation.get("error")));
        if (!aiRateLimitService.tryAcquire(userId, "chat")) {
            rewards.failChat(userId,request.requestId(),"Too many requests");
            return error(HttpStatus.TOO_MANY_REQUESTS, "AI请求过于频繁，请稍后再试");
        }
        try {
            HealthQuestion savedQuestion = savePendingQuestion(request, userId);
            AssistantChatReply reply = assistantChatService.chat(request, List.of());
            if(reply == null || isBlank(reply.reply())) throw new IllegalStateException("AI returned empty content");
            saveAnsweredQuestion(savedQuestion, reply);
            rewards.completeChat(userId,request.requestId(),reply);
            return ResponseEntity.ok(reply);
        } catch (RuntimeException exception) {
            rewards.failChat(userId,request.requestId(),"AI request failed; no points charged");
            return error(HttpStatus.SERVICE_UNAVAILABLE,"AI request failed; no points charged");
        }
    }

    @PostMapping({"/api/ai/suggestions", "/api/suggestions/scene"})
    public ResponseEntity<?> suggestions(@RequestBody AssistantSuggestionRequest request, HttpServletRequest servletRequest) {
        Long userId = currentUserId(servletRequest);
        if (!aiRateLimitService.tryAcquire(userId, "suggestions")) {
            return error(HttpStatus.TOO_MANY_REQUESTS, "AI请求过于频繁，请稍后再试");
        }
        try {
            return ResponseEntity.ok(assistantSuggestionService.suggest(request));
        } catch (RagSuggestionUnavailableException exception) {
            return error(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage());
        }
    }

    @GetMapping({"/api/ai/status", "/api/assistant/status"})
    public Map<String,Object> status() {
        return providerStatus.snapshot(aiProperties);
    }

    @GetMapping("/api/ai/chat/{requestId}")
    public org.example.springbootdemo.common.result.ApiResponse<?> chatResult(@org.springframework.web.bind.annotation.PathVariable String requestId, HttpServletRequest request) {
        return org.example.springbootdemo.common.result.ApiResponse.success(rewards.chatResult(currentUserId(request),requestId));
    }

    private ResponseEntity<Map<String, Object>> error(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(Map.of(
                "success", false,
                "message", message
        ));
    }

    private HealthQuestion savePendingQuestion(AssistantChatRequest request, Long userId) {
        if (userId == null || request == null || isBlank(request.message())) {
            return null;
        }
        HealthQuestion healthQuestion = new HealthQuestion();
        healthQuestion.setUserId(userId);
        healthQuestion.setQuestion(request.message());
        healthQuestion.setStatus((byte) 0);
        healthQuestionService.addHealthQuestion(healthQuestion);
        return healthQuestion;
    }

    private void saveAnsweredQuestion(HealthQuestion savedQuestion, AssistantChatReply reply) {
        if (savedQuestion == null || savedQuestion.getId() == null || reply == null || isBlank(reply.reply())) {
            return;
        }
        HealthQuestion answer = new HealthQuestion();
        answer.setId(savedQuestion.getId());
        answer.setAnswer(reply.reply());
        answer.setStatus((byte) 1);
        healthQuestionService.answerHealthQuestion(answer);
    }

    private Long currentUserId(HttpServletRequest servletRequest) {
        Object currentUserId = servletRequest.getAttribute("currentUserId");
        if (currentUserId instanceof Long userId) {
            return userId;
        }
        if (currentUserId instanceof Number number) {
            return number.longValue();
        }
        return null;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
