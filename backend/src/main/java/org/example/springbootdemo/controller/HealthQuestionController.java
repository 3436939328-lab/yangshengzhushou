package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.HealthQuestion;
import org.example.springbootdemo.service.HealthQuestionAiService;
import org.example.springbootdemo.service.HealthQuestionService;
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
public class HealthQuestionController {

    private final HealthQuestionService healthQuestionService;
    private final HealthQuestionAiService healthQuestionAiService;
    private final PermissionService permissionService;

    public HealthQuestionController(
            HealthQuestionService healthQuestionService,
            HealthQuestionAiService healthQuestionAiService,
            PermissionService permissionService
    ) {
        this.healthQuestionService = healthQuestionService;
        this.healthQuestionAiService = healthQuestionAiService;
        this.permissionService = permissionService;
    }

    @GetMapping({"/health-question/list", "/api/health-question/list"})
    public ResponseEntity<Map<String, Object>> listHealthQuestions(
            @RequestParam(required = false) Long userId,
            HttpServletRequest request
    ) {
        if (userId == null && !permissionService.isAdmin(request)) {
            userId = permissionService.currentUserId(request);
        }
        if (!permissionService.canListHealthQuestions(request, userId)) {
            return forbidden();
        }
        if (userId == null) {
            return ResponseEntity.ok(response(true, "query success", healthQuestionService.listHealthQuestions()));
        }
        return ResponseEntity.ok(response(true, "query success", healthQuestionService.listHealthQuestions(userId)));
    }

    @PostMapping({"/health-question", "/api/health-question"})
    public ResponseEntity<Map<String, Object>> addHealthQuestion(@RequestBody HealthQuestion healthQuestion, HttpServletRequest request) {
        if (healthQuestion.getUserId() == null) {
            return ResponseEntity.ok(response(false, "userId is required"));
        }
        if (!permissionService.canAccessUser(request, healthQuestion.getUserId())) {
            return forbidden();
        }
        if (isBlank(healthQuestion.getQuestion())) {
            return ResponseEntity.ok(response(false, "question is required"));
        }
        return ResponseEntity.status(410).body(response(false,
                "Use /api/ai/chat with a requestId; legacy AI generation is retired"));
    }

    @PostMapping({"/health-question/answer", "/api/health-question/answer"})
    public ResponseEntity<Map<String, Object>> answerHealthQuestion(@RequestBody HealthQuestion healthQuestion, HttpServletRequest request) {
        if (healthQuestion.getId() == null) {
            return ResponseEntity.ok(response(false, "id is required"));
        }
        if (!permissionService.canAnswerHealthQuestion(request)) {
            return forbidden();
        }
        if (isBlank(healthQuestion.getAnswer())) {
            return ResponseEntity.ok(response(false, "answer is required"));
        }
        healthQuestion.setStatus((byte) 1);
        boolean updated = healthQuestionService.answerHealthQuestion(healthQuestion) > 0;
        return ResponseEntity.ok(response(updated, updated ? "health question answered" : "answer failed"));
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
