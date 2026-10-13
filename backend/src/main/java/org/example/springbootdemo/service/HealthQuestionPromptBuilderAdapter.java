package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.AssistantChatReply;
import org.example.springbootdemo.ai.HealthQuestionAiClient;
import org.example.springbootdemo.ai.HealthQuestionPromptBuilder;
import org.example.springbootdemo.bean.HealthQuestion;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class HealthQuestionPromptBuilderAdapter {

    private final HealthQuestionAiClient aiClient;
    private final HealthQuestionPromptBuilder promptBuilder;

    public HealthQuestionPromptBuilderAdapter(HealthQuestionAiClient aiClient, HealthQuestionPromptBuilder promptBuilder) {
        this.aiClient = aiClient;
        this.promptBuilder = promptBuilder;
    }

    public AssistantChatReply generateReply(String question, List<?> history) {
        String answer;
        try {
            answer = aiClient.generateAnswer(promptBuilder.build(toHealthQuestionHistory(history), question));
        } catch (RuntimeException exception) {
            answer = fallbackAnswer(question, history);
        }
        return new AssistantChatReply(
                answer,
                "SpringBootFallback",
                "normal",
                List.of("Keep a regular routine", "Eat lightly", "Exercise moderately"),
                List.of(),
                "This advice cannot replace medical diagnosis."
        );
    }

    private List<HealthQuestion> toHealthQuestionHistory(List<?> history) {
        return history.stream()
                .filter(HealthQuestion.class::isInstance)
                .map(HealthQuestion.class::cast)
                .toList();
    }

    private String fallbackAnswer(String question, List<?> history) {
        int recentCount = Math.min(2, history.size());
        return "The AI service is temporarily unavailable. Keep a regular routine, eat lightly, exercise moderately, "
                + "and watch symptom changes first. Recent context records: " + recentCount
                + ". Current question: " + question;
    }
}
