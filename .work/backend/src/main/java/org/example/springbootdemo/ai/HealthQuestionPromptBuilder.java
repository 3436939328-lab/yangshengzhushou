package org.example.springbootdemo.ai;

import org.example.springbootdemo.bean.HealthQuestion;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Component
public class HealthQuestionPromptBuilder {

    private final HealthQuestionAiProperties properties;

    public HealthQuestionPromptBuilder(HealthQuestionAiProperties properties) {
        this.properties = properties;
    }

    public List<AiChatMessage> build(List<HealthQuestion> history, String currentQuestion) {
        List<AiChatMessage> messages = new ArrayList<>();
        messages.add(new AiChatMessage("system", properties.getSystemPrompt().trim()));

        List<HealthQuestion> recentQuestions = history.stream()
                .filter(this::hasAnswer)
                .sorted(Comparator.comparing(HealthQuestion::getCreateTime, Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparing((left, right) -> Long.compare(left.getId() == null ? 0L : left.getId(), right.getId() == null ? 0L : right.getId())))
                .toList();

        int startIndex = Math.max(0, recentQuestions.size() - properties.getMemoryWindow());
        for (int index = startIndex; index < recentQuestions.size(); index++) {
            HealthQuestion question = recentQuestions.get(index);
            messages.add(new AiChatMessage("user", question.getQuestion()));
            messages.add(new AiChatMessage("assistant", question.getAnswer()));
        }

        messages.add(new AiChatMessage("user", currentQuestion.trim()));
        return messages;
    }

    private boolean hasAnswer(HealthQuestion question) {
        return question != null && question.getAnswer() != null && !question.getAnswer().trim().isEmpty();
    }
}
