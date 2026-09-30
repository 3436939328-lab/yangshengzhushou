package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.AssistantChatReply;
import org.example.springbootdemo.ai.AssistantChatRequest;
import org.example.springbootdemo.bean.HealthQuestion;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class HealthQuestionAiService {

    private final HealthQuestionService healthQuestionService;
    private final AssistantChatService assistantChatService;

    public HealthQuestionAiService(
            HealthQuestionService healthQuestionService,
            AssistantChatService assistantChatService
    ) {
        this.healthQuestionService = healthQuestionService;
        this.assistantChatService = assistantChatService;
    }

    public HealthQuestion askQuestion(HealthQuestion healthQuestion) {
        if (healthQuestion == null || healthQuestion.getUserId() == null) {
            throw new IllegalArgumentException("userId is required");
        }
        if (healthQuestion.getQuestion() == null || healthQuestion.getQuestion().trim().isEmpty()) {
            throw new IllegalArgumentException("question is required");
        }

        List<HealthQuestion> history = healthQuestionService.listHealthQuestions(healthQuestion.getUserId());
        healthQuestion.setStatus((byte) 0);
        healthQuestionService.addHealthQuestion(healthQuestion);

        AssistantChatReply reply = assistantChatService.chat(
                new AssistantChatRequest(healthQuestion.getQuestion(), Map.of(), Map.of(), toAssistantHistory(history)),
                history
        );

        healthQuestion.setAnswer(reply.reply());
        healthQuestionService.answerHealthQuestion(healthQuestion);
        return healthQuestion;
    }

    private List<Map<String, Object>> toAssistantHistory(List<HealthQuestion> history) {
        return history.stream()
                .filter(question -> question.getQuestion() != null && question.getAnswer() != null)
                .map(question -> Map.<String, Object>of(
                        "question", question.getQuestion(),
                        "answer", question.getAnswer()
                ))
                .toList();
    }
}
