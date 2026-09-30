package org.example.springbootdemo.ai;

import java.util.List;

public interface HealthQuestionAiClient {

    String generateAnswer(List<AiChatMessage> messages);
}
