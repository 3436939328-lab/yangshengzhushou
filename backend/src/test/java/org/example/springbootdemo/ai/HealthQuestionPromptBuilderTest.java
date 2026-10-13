package org.example.springbootdemo.ai;

import org.example.springbootdemo.bean.HealthQuestion;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class HealthQuestionPromptBuilderTest {

    @Test
    void buildKeepsRecentContextAndCurrentQuestion() {
        HealthQuestionAiProperties properties = new HealthQuestionAiProperties();
        properties.setSystemPrompt("你是中医养生助手");
        properties.setMemoryWindow(2);
        HealthQuestionPromptBuilder builder = new HealthQuestionPromptBuilder(properties);

        List<HealthQuestion> history = List.of(
                question(1L, "最近睡不好怎么办？", "早点休息"),
                question(2L, "胃口不好怎么调？", "清淡饮食"),
                question(3L, "总是疲劳怎么办？", "增加作息规律")
        );

        List<AiChatMessage> messages = builder.build(history, "最近还是很困");

        assertEquals(6, messages.size());
        assertEquals("system", messages.get(0).role());
        assertEquals("你是中医养生助手", messages.get(0).content());
        assertEquals("user", messages.get(1).role());
        assertEquals("胃口不好怎么调？", messages.get(1).content());
        assertEquals("assistant", messages.get(2).role());
        assertEquals("清淡饮食", messages.get(2).content());
        assertEquals("user", messages.get(3).role());
        assertEquals("总是疲劳怎么办？", messages.get(3).content());
        assertEquals("assistant", messages.get(4).role());
        assertEquals("增加作息规律", messages.get(4).content());
        assertEquals("user", messages.get(5).role());
        assertEquals("最近还是很困", messages.get(5).content());
    }

    private HealthQuestion question(Long id, String text, String answer) {
        HealthQuestion question = new HealthQuestion();
        question.setId(id);
        question.setUserId(7L);
        question.setQuestion(text);
        question.setAnswer(answer);
        question.setStatus((byte) 1);
        return question;
    }
}
