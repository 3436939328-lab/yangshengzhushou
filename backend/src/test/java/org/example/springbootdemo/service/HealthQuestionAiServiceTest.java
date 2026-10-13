package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.AssistantChatReply;
import org.example.springbootdemo.bean.HealthQuestion;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class HealthQuestionAiServiceTest {

    @Test
    void askQuestionDelegatesToAssistantChatServiceAndWritesBackAnswer() {
        HealthQuestionService healthQuestionService = mock(HealthQuestionService.class);
        AssistantChatService assistantChatService = mock(AssistantChatService.class);
        HealthQuestionAiService aiService = new HealthQuestionAiService(healthQuestionService, assistantChatService);

        HealthQuestion previous = new HealthQuestion();
        previous.setId(1L);
        previous.setUserId(3L);
        previous.setQuestion("sleep problem");
        previous.setAnswer("sleep earlier");
        previous.setStatus((byte) 1);
        when(healthQuestionService.listHealthQuestions(3L)).thenReturn(List.of(previous));
        when(assistantChatService.chat(any(), eq(List.of(previous)))).thenReturn(
                new AssistantChatReply(
                        "Keep a steady routine and stop using screens before sleep.",
                        "NodeLangGraph",
                        "normal",
                        List.of("Keep a steady routine"),
                        List.of(),
                        "This advice cannot replace medical diagnosis."
                )
        );

        doAnswer(invocation -> {
            HealthQuestion record = invocation.getArgument(0);
            record.setId(9L);
            return 1;
        }).when(healthQuestionService).addHealthQuestion(any(HealthQuestion.class));
        when(healthQuestionService.answerHealthQuestion(any(HealthQuestion.class))).thenReturn(1);

        HealthQuestion question = new HealthQuestion();
        question.setUserId(3L);
        question.setQuestion("still sleeping badly");

        HealthQuestion result = aiService.askQuestion(question);

        assertEquals(9L, result.getId());
        assertEquals("Keep a steady routine and stop using screens before sleep.", result.getAnswer());
        verify(healthQuestionService).listHealthQuestions(3L);
        verify(healthQuestionService).addHealthQuestion(any(HealthQuestion.class));
        verify(assistantChatService).chat(any(), eq(List.of(previous)));
        verify(healthQuestionService).answerHealthQuestion(any(HealthQuestion.class));
    }
}
